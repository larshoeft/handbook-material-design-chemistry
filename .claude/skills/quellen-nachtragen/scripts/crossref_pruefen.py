#!/usr/bin/env python3
"""Gleicht die DOIs der offenen Quellen in STATUS.md mit Crossref ab."""
import json
import pathlib
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

DOI = re.compile(r'10\.\d{4,}/[^\s|>]+')


def norm(text):
    return re.sub(r'\W+', '', re.sub(r'<[^>]+>', '', text)).lower()


def open_sources(path):
    text = pathlib.Path(path).read_text(encoding='utf-8')
    text = text[text.index('## Für Zotero offene Quellen'):]
    found = {}
    for line in text.splitlines():
        if not line.startswith('| ') or line.startswith(('| Text ', '|--')) or 'Zotero `' in line:
            continue
        cells = [c.strip() for c in line.strip('|').split(' | ')]
        m = DOI.search(cells[1]) if len(cells) > 1 else None
        if m:
            found.setdefault(m.group(0).rstrip('.').lower(), cells[1])
    return found


def crossref(doi):
    url = 'https://api.crossref.org/works/' + urllib.parse.quote(doi)
    request = urllib.request.Request(url, headers={'User-Agent': 'handbook-material-design/1.0 (mailto:hoeft@leibniz-ipn.de)'})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)['message']


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    sources = open_sources(sys.argv[1] if len(sys.argv) > 1 else 'STATUS.md')
    results, problems = [], 0
    for doi, source in sources.items():
        try:
            data = crossref(doi)
        except (urllib.error.URLError, TimeoutError) as error:
            print(f'FEHLER  {doi}: {error}')
            results.append({'doi': doi, 'status': 'fehler'})
            problems += 1
            continue
        title = (data.get('title') or [''])[0]
        issued = (data.get('issued', {}).get('date-parts') or [[None]])[0][0]
        family = (data.get('author') or [{}])[0].get('family', '')
        matches_title = norm(title)[:25] in norm(source)
        matches_year = str(issued) in source
        matches_author = norm(family) in norm(source)
        status = 'ok' if matches_title and matches_year and matches_author else 'abweichend'
        problems += status != 'ok'
        print(f'{status:10} {doi} | {family} {issued} | {title[:70]}')
        if status != 'ok':
            print(f'           Word: {source[:110]}')
        results.append({'doi': doi, 'status': status, 'family': family, 'year': issued, 'title': title, 'type': data.get('type')})
        time.sleep(0.2)
    if len(sys.argv) > 2:
        pathlib.Path(sys.argv[2]).write_text(json.dumps(results, ensure_ascii=False, indent=1), encoding='utf-8')
    print(f'\n{len(results)} DOIs, {problems} mit Abweichung oder Fehler')
    sys.exit(1 if problems else 0)


if __name__ == '__main__':
    main()
