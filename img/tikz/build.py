"""Builds a PDF for print and an SVG for the web in img/ from each img/tikz/*.tex."""
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

hier = pathlib.Path(__file__).resolve().parent
ziel = hier.parent
namen = sys.argv[1:] or [p.stem for p in hier.glob('*.tex') if p.stem != 'stil']


def lang(hexwert):
    h = hexwert.lower()
    return ''.join(c * 2 for c in h) if len(h) == 3 else h


farben = {lang(h): n for n, h in re.findall(r'\\definecolor\{(\w+)\}\{HTML\}\{(\w{6})\}', (hier / 'stil.tex').read_text(encoding='utf-8'))}


def tag(m):
    t = m.group(0)
    stile = []
    for attr, wert in re.findall(r"\b(fill|stroke|stop-color)='\s*#(\w+)\s*'", t):
        if lang(wert) in farben:
            stile.append(f'{attr}:var(--fig-{farben[lang(wert)]},#{lang(wert)})')
    t = re.sub(r"(stop-color=')\s*(#\w+)\s*'", r"\1\2'", t)
    if stile:
        t = re.sub(r'(/?>)$', f" style='{';'.join(stile)}'" + r'\1', t)
    return t


for name in namen:
    with tempfile.TemporaryDirectory() as tmp:
        lauf = ['-interaction=nonstopmode', '-halt-on-error', f'-output-directory={tmp}']
        subprocess.run(['pdflatex', *lauf, f'{name}.tex'], cwd=hier, check=True, stdout=subprocess.DEVNULL)
        shutil.copy(pathlib.Path(tmp, f'{name}.pdf'), ziel / f'{name}.pdf')
        subprocess.run(['latex', *lauf, rf'\def\pgfsysdriver{{pgfsys-dvisvgm.def}}\input{{{name}.tex}}'],
                       cwd=hier, check=True, stdout=subprocess.DEVNULL)
        svg = pathlib.Path(tmp, f'{name}.svg')
        subprocess.run(['dvisvgm', '--no-fonts', '--exact-bbox', '--optimize', '-o', str(svg),
                        str(pathlib.Path(tmp, f'{name}.dvi'))], check=True, stderr=subprocess.DEVNULL)
        text = re.sub(r'<[^!?][^>]*>', tag, svg.read_text(encoding='utf-8'))
        (ziel / f'{name}.svg').write_text(text, encoding='utf-8', newline='\n')
    print(name)
