#!/usr/bin/env python3
"""Prüft Zitate gegen zotero.bib; vergleicht und migriert Keys gegen einen Git-Stand."""
import argparse
import collections
import pathlib
import re
import subprocess
import sys

KEY_FORMAT = re.compile(r'^[a-z][a-z-]*\d{4}_[a-z0-9-]+$')
CITE = re.compile(r'(?<![\w.@/-])@([A-Za-z0-9][\w:.#$%&+?<>~/-]*\w)')
CROSSREF = re.compile(r'^(sec|fig|tbl|eq|lst|thm|tip|nte|wrn|imp|cau|lem|cor|prp|cnj|def|exm|exr|sol|rem|alg)-')
PLAIN_CITE = re.compile(
    r"\((?:[^()\[\]@]*?[A-ZÄÖÜ][\w'-]+(?: et al\.| (?:&|und) [A-ZÄÖÜ][\w'-]+)?,? (?:19|20)\d{2}[a-z]?[^()\[\]@]*)\)")
SKIP_DIRS = {'_book', '_build', '_docx', '.quarto', '.venv', 'venv', '_quellen_docx', '_quellen_pdf'}


def parse_bib(text):
    entries = {}
    for m in re.finditer(r'^@\w+\{([^,\s]+),(.*?)^\}', text, re.S | re.M):
        title = re.search(r'^\s*title = \{(.*)\},?\s*$', m.group(2), re.M)
        date = re.search(r'^\s*(?:date|year) = \{?(\d{4})', m.group(2), re.M)
        entries[m.group(1)] = (
            re.sub(r'\W+', '', title.group(1)).lower() if title else '',
            date.group(1) if date else '')
    return entries


def qmd_files():
    for path in sorted(pathlib.Path('.').rglob('*.qmd')):
        if not SKIP_DIRS & set(path.parts) and 'template' not in path.name:
            yield path


def cited_keys():
    cited = collections.defaultdict(list)
    for path in qmd_files():
        for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
            for key in CITE.findall(line):
                if not CROSSREF.match(key):
                    cited[key].append(f'{path.as_posix()}:{number}')
    return cited


def plain_citations():
    for path in qmd_files():
        for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
            for m in PLAIN_CITE.finditer(line):
                yield f'{path.as_posix()}:{number}', m.group(0)


def key_mapping(old, new):
    by_identity = collections.defaultdict(list)
    for key, identity in new.items():
        by_identity[identity].append(key)
    mapping, unclear = {}, []
    for key, identity in old.items():
        targets = by_identity.get(identity, [])
        if len(targets) == 1:
            mapping[key] = targets[0]
        else:
            unclear.append((key, targets))
    return mapping, unclear


def migrate(mapping):
    changed = 0
    for path in qmd_files():
        text = path.read_text(encoding='utf-8')
        result = CITE.sub(lambda m: '@' + mapping.get(m.group(1), m.group(1)), text)
        if result != text:
            path.write_text(result, encoding='utf-8', newline='\n')
            changed += 1
    return changed


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bib', default='zotero.bib')
    parser.add_argument('--vergleiche', metavar='REF', help='Keys mit REF:zotero.bib vergleichen')
    parser.add_argument('--umstellen', action='store_true', help='mit --vergleiche: Zitate auf neue Keys umstellen')
    args = parser.parse_args()

    bib = parse_bib(pathlib.Path(args.bib).read_text(encoding='utf-8'))
    failed = False

    if args.vergleiche:
        old_text = subprocess.check_output(['git', 'show', f'{args.vergleiche}:{args.bib}'], encoding='utf-8')
        old = parse_bib(old_text)
        mapping, unclear = key_mapping(old, bib)
        renamed = {k: v for k, v in mapping.items() if k != v}
        old_lower = {k.lower() for k in old}
        swapped = sorted(k for k, v in renamed.items() if v.lower() in old_lower and v.lower() != k.lower())
        print(f'## Vergleich mit {args.vergleiche}: {len(old)} alte, {len(bib)} neue Einträge')
        print(f'Unverändert: {len(mapping) - len(renamed)}, geändert: {len(renamed)}, unklar: {len(unclear)}')
        for key in swapped:
            print(f'VERTAUSCHT: {key} zeigt jetzt auf eine andere Quelle ({key} -> {mapping[key]})')
        for key, targets in unclear:
            print(f'UNKLAR: {key} -> {targets or "kein Treffer"}')
        for key, value in sorted(renamed.items()):
            print(f'  {key} -> {value}')
        failed = bool(swapped or unclear or renamed)
        if args.umstellen:
            if unclear:
                sys.exit('Abbruch: Unklare Zuordnungen zuerst klären.')
            print(f'Umgestellt in {migrate(renamed)} Dateien.')
            failed = False

    cited = cited_keys()
    missing = sorted(set(cited) - set(bib))
    print(f'\n## Zitate: {len(cited)} Keys, {len(missing)} fehlen in {args.bib}')
    for key in missing:
        print(f'FEHLT: {key} ({", ".join(cited[key][:3])})')

    wrong = sorted(k for k in bib if not KEY_FORMAT.match(k))
    print(f'\n## Format autorjahr_titelwort: {len(wrong)} von {len(bib)} Keys weichen ab')
    for key in wrong[:15]:
        print(f'  {key}')
    if len(wrong) > 15:
        print(f'  ... und {len(wrong) - 15} weitere')

    collisions = sorted(k for k in bib if k[:-1] in bib and k[-1].isalpha() and KEY_FORMAT.match(k))
    print(f'\n## Kollisionen mit Buchstaben-Suffix: {len(collisions)}')
    for key in collisions:
        print(f'  {key}')

    plain = list(plain_citations())
    print(f'\n## Textzitate statt [@key]: {len(plain)}')
    for place, text in plain:
        print(f'  {place}: {text[:90]}')

    sys.exit(1 if missing or failed else 0)


if __name__ == '__main__':
    main()
