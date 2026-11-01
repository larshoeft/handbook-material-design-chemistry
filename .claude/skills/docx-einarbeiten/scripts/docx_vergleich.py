#!/usr/bin/env python3
"""Analyzes Word files, converts them and compares them word by word with a .qmd."""
import argparse
import difflib
import html
import json
import pathlib
import re
import shutil
import subprocess
import sys
import unicodedata
import zipfile

CITE_TOKEN = '⟦Z⟧'
REFERENCE_HEADINGS = {'literatur', 'literaturverzeichnis', 'quellen', 'references'}
CHARACTERS = {
    '„': '"', '“': '"', '”': '"', '«': '"', '»': '"',
    '‚': "'", '‘': "'", '’': "'",
    '—': '---', '–': '--', '…': '...',
    ' ': ' ', ' ': ' ', ' ': ' ',
    '­': '', '​': '', '‌': '', '‍': '', '﻿': '',
}
YEAR = r'(?:19|20)\d{2}[a-z]?'


def pandoc(*args, text=None):
    quarto = shutil.which('quarto')
    if not quarto:
        sys.exit('quarto wurde nicht gefunden.')
    result = subprocess.run([quarto, 'pandoc', *args], input=text, capture_output=True,
                            text=True, encoding='utf-8', errors='replace')
    if result.returncode:
        sys.exit(result.stderr)
    return result.stdout


def normalize_characters(text):
    return ''.join(CHARACTERS.get(c, c) for c in unicodedata.normalize('NFC', text))


def word_xml(path, part='word/document.xml'):
    with zipfile.ZipFile(path) as archive:
        return archive.read(part).decode('utf-8') if part in archive.namelist() else ''


def xml_text(fragment, deleted=False):
    tag = r'(?:t|delText)' if deleted else 't'
    return html.unescape(''.join(re.findall(rf'<w:{tag}(?: [^>]*)?>([^<]*)<', fragment)))


def zotero_fields(document):
    instructions = html.unescape(''.join(re.findall(r'<w:instrText[^>]*>([^<]*)<', document)))
    decoder = json.JSONDecoder()
    for part in instructions.split('ADDIN ZOTERO_ITEM')[1:]:
        start = part.find('{')
        try:
            data, _ = decoder.raw_decode(part[start:])
        except ValueError:
            yield '(nicht lesbar)', []
            continue
        yield data.get('properties', {}).get('plainCitation', ''), [
            item.get('itemData', {}) for item in data.get('citationItems', [])]


def bib_lookup(path):
    lookup = {}
    if not path.exists():
        return lookup
    for m in re.finditer(r'^@\w+\{([^,\s]+),(.*?)^\}', path.read_text(encoding='utf-8'), re.S | re.M):
        doi = re.search(r'^\s*doi = \{(.*?)\}', m.group(2), re.M)
        title = re.search(r'^\s*title = \{(.*)\},?\s*$', m.group(2), re.M)
        if doi:
            lookup[doi.group(1).lower()] = m.group(1)
        if title:
            lookup[re.sub(r'\W+', '', title.group(1)).lower()] = m.group(1)
    return lookup


def analyse(args):
    document = word_xml(args.datei)
    comments = word_xml(args.datei, 'word/comments.xml')
    print(f'# {pathlib.Path(args.datei).name}')
    print(f'Einfügungen: {len(re.findall("<w:ins ", document))}, Löschungen: {len(re.findall("<w:del ", document))}, '
          f'Verschiebungen: {len(re.findall("<w:moveTo ", document))}')
    print(f'Tabellen: {document.count("<w:tbl>")}, Bilder: {document.count("<w:drawing>")}, '
          f'Formeln: {document.count("<m:oMath")}')

    found = re.findall(r'<w:comment [^>]*w:author="([^"]*)"[^>]*>(.*?)</w:comment>', comments, re.S)
    print(f'\n## Kommentare: {len(found)}')
    for author, body in found:
        print(f'- {html.unescape(author)}: {xml_text(body)}')

    marks = [xml_text(run) for run in re.findall(r'<w:r\b(?:(?!</w:r>).)*?<w:highlight (?:(?!</w:r>).)*?</w:r>', document, re.S)]
    marks = [m for m in marks if m.strip()]
    print(f'\n## Markierungen: {len(marks)}')
    for mark in marks:
        print(f'- {mark}')

    bib = bib_lookup(pathlib.Path(args.bib))
    fields = list(zotero_fields(document))
    print(f'\n## Zotero-Felder: {len(fields)}')
    for citation, items in fields:
        results = []
        for item in items:
            doi = str(item.get('DOI', '')).lower()
            title = re.sub(r'\W+', '', str(item.get('title', ''))).lower()
            key = bib.get(doi) or bib.get(title)
            results.append(key or f'FEHLT: {str(item.get("title", ""))[:60]}')
        print(f'- {citation} -> {"; ".join(results)}')

    print('\n## Überschriften-Kandidaten')
    source = markdown_source(args.datei, 'accept')
    for line in source.splitlines():
        if re.match(r'^(#{1,6} |\*\*[^*]{3,90}\*\*\s*$|\[[^\]]{3,90}\]\{\.underline\}\s*$)', line):
            print(f'- {line}')


def markdown_source(path, changes):
    return pandoc('-f', 'docx', '-t', 'markdown', '--wrap=none', f'--track-changes={changes}', str(path))


def markdown(args):
    text = normalize_characters(markdown_source(args.datei, args.aenderungen))
    text = re.sub(r'\[([^\[\]]*)\]\{\.(?:underline|mark)\}', r'\1', text)
    sys.stdout.reconfigure(encoding='utf-8')
    print(text)


def inline_text(node, out, keys):
    if isinstance(node, list):
        for child in node:
            inline_text(child, out, keys)
    elif isinstance(node, dict):
        kind = node.get('t')
        content = node.get('c')
        if kind == 'Str':
            out.append(content)
        elif kind in ('Space', 'SoftBreak', 'LineBreak'):
            out.append(' ')
        elif kind == 'Quoted':
            mark = '"' if content[0]['t'] == 'DoubleQuote' else "'"
            out.append(mark)
            inline_text(content[1], out, keys)
            out.append(mark)
        elif kind == 'Cite':
            out.append(f' {CITE_TOKEN} ')
            keys.append([citation['citationId'] for citation in content[0]])
        elif kind in ('Code', 'CodeBlock', 'Math'):
            out.append(content[-1])
        elif kind in ('Image', 'RawBlock', 'RawInline'):
            pass
        elif kind in ('Para', 'Plain', 'Header', 'Table', 'BulletList', 'OrderedList', 'Div'):
            out.append(' ')
            inline_text(content, out, keys)
            out.append(' ')
        else:
            inline_text(content, out, keys)


def document_tokens(source, source_format, changes='accept'):
    args = ['-f', source_format, '-t', 'json']
    if source_format == 'docx':
        args += [f'--track-changes={changes}', str(source)]
        data = json.loads(pandoc(*args))
    else:
        data = json.loads(pandoc(*args, text=source))
    blocks, keys, out = data['blocks'], [], []
    for block in blocks:
        text = []
        inline_text(block, text, [])
        if ''.join(text).split('(')[0].strip().rstrip(':').lower() in REFERENCE_HEADINGS:
            break
        inline_text(block, out, keys)
    return mask_citations(normalize_characters(''.join(out))), keys


def mask_citations(text):
    found = []

    def replace(match):
        found.append(match.group(0))
        return f' {CITE_TOKEN} '

    name = r"[A-ZÄÖÜ][\w'-]+"
    narrative = rf"{name}(?: et al\.| (?:&|und|and) {name})*\s*\({YEAR}(?:, S\. [^)]*)?\)"
    text = re.sub(narrative, replace, text)
    text = re.sub(rf'\([^()]*?\b{YEAR}\b[^()]*?\)', replace, text)
    return comparable(text).split(), found


def comparable(text):
    return re.sub(r'-{2,3}', '-', text)


def qmd_body(path):
    text = pathlib.Path(path).read_text(encoding='utf-8')
    return re.sub(r'\A---\n.*?\n---\n', '', text, flags=re.S)


def compare(args):
    sys.stdout.reconfigure(encoding='utf-8')
    (word, word_cites), _ = document_tokens(args.datei, 'docx', args.aenderungen)
    (repo, repo_cites), keys = document_tokens(qmd_body(args.qmd), 'markdown')
    if args.ohne_kopf:
        word = word[args.ohne_kopf:]

    differences = 0
    matcher = difflib.SequenceMatcher(a=word, b=repo, autojunk=False)
    for tag, a0, a1, b0, b1 in matcher.get_opcodes():
        if tag == 'equal':
            continue
        differences += 1
        context = ' '.join(word[max(0, a0 - 6):a0])
        print(f'[{differences}] nach "... {context}"')
        print(f'    Word: {" ".join(word[a0:a1]) or "(nichts)"}')
        print(f'    qmd:  {" ".join(repo[b0:b1]) or "(nichts)"}')

    print(f'\nWörter: Word {len(word)}, qmd {len(repo)}. Abweichungen: {differences}')
    print(f'Zitate: Word {len(word_cites)}, qmd {len(keys) + len(repo_cites)}')
    if args.zitate:
        print('\n## Word-Zitate')
        for citation in word_cites:
            print(f'- {citation}')
        print('\n## Zitate in der qmd')
        for key_list in keys:
            print(f'- {"; ".join(key_list)}')
        for citation in repo_cites:
            print(f'- (Text) {citation}')
    sys.exit(1 if differences else 0)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='befehl', required=True)

    p = commands.add_parser('analyse')
    p.add_argument('datei')
    p.add_argument('--bib', default='zotero.bib')
    p.set_defaults(run=analyse)

    p = commands.add_parser('markdown')
    p.add_argument('datei')
    p.add_argument('--aenderungen', choices=['accept', 'reject'], required=True)
    p.set_defaults(run=markdown)

    p = commands.add_parser('vergleich')
    p.add_argument('datei')
    p.add_argument('qmd')
    p.add_argument('--aenderungen', choices=['accept', 'reject'], default='accept')
    p.add_argument('--ohne-kopf', type=int, default=0, help='Anzahl Wörter der Word-Kopfzeile')
    p.add_argument('--zitate', action='store_true')
    p.set_defaults(run=compare)

    args = parser.parse_args()
    sys.stdout.reconfigure(encoding='utf-8')
    args.run(args)


if __name__ == '__main__':
    main()
