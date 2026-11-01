#!/usr/bin/env python3
"""Converts text citations to [@key] when person and year match zotero.bib uniquely."""
import argparse
import collections
import glob
import pathlib
import re
import sys

YEAR = r'(?:19|20)\d{2}[a-z]?'
NAME = r"[A-ZÄÖÜÉ][\w'-]+"
PREFIX = r'(?:[Vv]an )?'
AUTHORS = (rf"(?:[A-Z]\. ?)*(?P<family>{PREFIX}{NAME})"
           rf"(?P<rest>(?:,? et al\.|,? (?:&|und|and) {PREFIX}{NAME}|, {PREFIX}{NAME}(?=,? et al\.))*)")
PRE = r'(?P<pre>(?:vgl\.|z\. ?B\.|u\. ?a\.|siehe(?: auch)?|s\.)\s+)?'


def norm(name):
    return re.sub(r'\W+', '', name.lower().replace('ü', 'u').replace('ö', 'o').replace('ä', 'a').replace('é', 'e'))


def families(field):
    names = []
    for person in re.split(r'\s+and\s+', field):
        match = re.search(r'family=([^,]+)', person)
        prefix = re.search(r'prefix=([^,]+)', person)
        if match:
            names.append(((prefix.group(1) + ' ') if prefix else '') + match.group(1))
        else:
            names.append(person.split(',')[0])
    return [norm(n.strip('{} ')) for n in names]


def load_bib(path):
    index = collections.defaultdict(list)
    for m in re.finditer(r'^@\w+\{([^,\s]+),(.*?)^\}', pathlib.Path(path).read_text(encoding='utf-8'), re.S | re.M):
        field = re.search(r'^\s*(?:author|editor) = \{(.*)\},?\s*$', m.group(2), re.M)
        date = re.search(r'^\s*date = \{(\d{4})', m.group(2), re.M)
        if field and date:
            names = families(field.group(1))
            index[(names[0], date.group(1))].append((m.group(1), names))
    return index


class Mapper:
    def __init__(self, index):
        self.index = index
        self.stats = collections.Counter()
        self.open = collections.Counter()
        self.pairs = []

    def key(self, family, year, rest):
        candidates = self.index.get((norm(family), year[:4]), [])
        named = re.findall(rf'(?:&|und|and|,) ({PREFIX}{NAME})', rest)
        if named:
            wanted = norm(named[-1] if not re.search(r'et al', rest) else named[0])
            candidates = [c for c in candidates if len(c[1]) > 1 and wanted in c[1][1:]]
        elif 'et al' in rest:
            candidates = [c for c in candidates if len(c[1]) >= 3]
        else:
            candidates = [c for c in candidates if len(c[1]) == 1]
        if len(candidates) == 1:
            self.pairs.append((f'{family}{rest}, {year}', candidates[0][0]))
            return candidates[0][0]
        self.open[f'{family} {year}'] += 1
        return None

    def group(self, match):
        inner = match.group(1)
        if not re.search(rf'\b{YEAR}\b', inner):
            return match.group(0)
        keys, text, previous = [], [], None
        for part in (p.strip() for p in inner.split(';')):
            bare = re.match(rf'^{PRE}(?P<years>{YEAR})(?P<loc>,\s*S\.\s*.*)?$', part)
            m = bare or re.match(rf'^{PRE}{AUTHORS},?\s+(?P<years>{YEAR}(?:,\s*{YEAR})*)(?P<loc>,\s*S\.\s*.*)?$', part)
            if not m or (bare and not previous):
                if re.search(rf'\b{YEAR}\b', part):
                    self.stats['nicht zerlegbar'] += 1
                    print('  nicht zerlegbar:', match.group(0)[:100])
                    return match.group(0)
                text.append(part)
                continue
            family, rest = previous if bare else (m.group('family'), m.group('rest'))
            previous = (family, rest)
            pre = m.group('pre') or ''
            years = re.split(r',\s*', m.group('years'))
            for year in years:
                key = self.key(family, year, rest)
                location = m.group('loc') if year == years[-1] and m.group('loc') else ''
                if key:
                    keys.append(f'{pre}@{key}{location}')
                    pre = ''
                else:
                    text.append(f'{pre}{family}{rest}, {year}{location}')
                    pre = ''
        if not keys:
            self.stats['bleibt Text'] += 1
            return match.group(0)
        self.stats['Klammer umgestellt'] += 1
        prefix = '\\; '.join(text) + '\\; ' if text else ''
        return '[' + prefix + '; '.join(keys) + ']'

    def narrative(self, match):
        key = self.key(match.group('family'), match.group('year'), match.group('rest'))
        if not key:
            self.stats['Autor (Jahr) bleibt Text'] += 1
            return match.group(0)
        self.stats['Autor (Jahr) umgestellt'] += 1
        loc = match.group('loc')
        return f'@{key}' + (f' [{loc.strip(", ")}]' if loc else '')

    def convert(self, text):
        attributes = []

        def hide(match):
            attributes.append(match.group(0))
            return f'\x00{len(attributes) - 1}\x00'

        text = re.sub(r'\{#[^}]*\}|!\[\]\([^)]*\)|\]\([^)]*\)|^---\n.*?\n---\n', hide, text, flags=re.M | re.S)
        text = re.sub(rf'{AUTHORS}\s*\((?P<year>{YEAR})(?P<loc>,\s*S\.\s*[^)]*)?\)', self.narrative, text)
        text = re.sub(r'(?<!\])\(([^()\[\]]*)\)', self.group, text)
        return re.sub(r'\x00(\d+)\x00', lambda m: attributes[int(m.group(1))], text)


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bib', default='zotero.bib')
    parser.add_argument('--schreiben', action='store_true', help='Dateien ändern, sonst nur anzeigen')
    args = parser.parse_args()
    mapper = Mapper(load_bib(args.bib))
    files = [f for f in glob.glob('part_*/*.qmd') if 'template' not in f]
    for f in sorted(files):
        p = pathlib.Path(f)
        before = p.read_text(encoding='utf-8')
        after = mapper.convert(before)
        if after != before:
            print(f'{p.as_posix()}: {len(re.findall("@", after)) - len(re.findall("@", before))} neue Zitate')
            if args.schreiben:
                p.write_text(after, encoding='utf-8', newline='\n')
    print('## Zuordnungen')
    for text, key in sorted(set(mapper.pairs)):
        print(f'{text} -> {key}')
    print(dict(mapper.stats))
    print('Ohne Key:', dict(mapper.open))


if __name__ == '__main__':
    main()
