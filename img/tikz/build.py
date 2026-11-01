"""Erzeugt aus img/tikz/*.tex je eine PDF für den Druck und eine SVG für das Web in img/."""
import pathlib
import shutil
import subprocess
import sys
import tempfile

hier = pathlib.Path(__file__).resolve().parent
ziel = hier.parent
namen = sys.argv[1:] or [p.stem for p in hier.glob('*.tex') if p.stem != 'stil']

for name in namen:
    with tempfile.TemporaryDirectory() as tmp:
        lauf = ['-interaction=nonstopmode', '-halt-on-error', f'-output-directory={tmp}']
        subprocess.run(['pdflatex', *lauf, f'{name}.tex'], cwd=hier, check=True, stdout=subprocess.DEVNULL)
        shutil.copy(pathlib.Path(tmp, f'{name}.pdf'), ziel / f'{name}.pdf')
        subprocess.run(['latex', *lauf, rf'\def\pgfsysdriver{{pgfsys-dvisvgm.def}}\input{{{name}.tex}}'],
                       cwd=hier, check=True, stdout=subprocess.DEVNULL)
        subprocess.run(['dvisvgm', '--no-fonts', '--exact-bbox', '--optimize', '-o', str(ziel / f'{name}.svg'),
                        str(pathlib.Path(tmp, f'{name}.dvi'))], check=True, stderr=subprocess.DEVNULL)
    print(name)
