"""Makes the white background of figures transparent: white at the border and large white areas, boxes stay."""
import argparse
import pathlib
import sys
from collections import deque

from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('dateien', nargs='+', type=pathlib.Path)
parser.add_argument('--schwelle', type=int, default=30, help='Abstand zu Weiß, der noch als Hintergrund gilt')
parser.add_argument('--rand', type=float, default=0.6, help='Mindestanteil weißer Randpixel, sonst gilt das Bild als Foto')
parser.add_argument('--flaeche', type=float, default=0.05, help='Mindestgröße innerer weißer Flächen als Anteil am Bild')
args = parser.parse_args()
sys.stdout.reconfigure(encoding='utf-8')

for pfad in args.dateien:
    bild = Image.open(pfad).convert('RGBA')
    b, h = bild.size
    px = bild.load()
    weiss = lambda x, y: min(px[x, y][:3]) >= 255 - args.schwelle and px[x, y][3] > 0
    rand = [(x, 0) for x in range(b)] + [(x, h - 1) for x in range(b)] + [(0, y) for y in range(h)] + [(b - 1, y) for y in range(h)]
    anteil = sum(weiss(x, y) or px[x, y][3] == 0 for x, y in rand) / len(rand)
    if anteil < args.rand:
        print(f'{pfad}: übersprungen, Rand nur zu {anteil:.0%} weiß')
        continue
    gesehen = bytearray(b * h)
    for sx in range(b):
        for sy in range(h):
            if gesehen[sy * b + sx] or not weiss(sx, sy):
                continue
            teil, schlange, am_rand = [], deque([(sx, sy)]), False
            gesehen[sy * b + sx] = 1
            while schlange:
                x, y = schlange.popleft()
                teil.append((x, y))
                am_rand |= x in (0, b - 1) or y in (0, h - 1)
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < b and 0 <= ny < h and not gesehen[ny * b + nx] and weiss(nx, ny):
                        gesehen[ny * b + nx] = 1
                        schlange.append((nx, ny))
            if am_rand or len(teil) >= args.flaeche * b * h:
                for x, y in teil:
                    px[x, y] = (255, 255, 255, 0)
    bild.save(pfad.with_suffix('.png'), optimize=True)
    print(f'{pfad}: Hintergrund transparent')
