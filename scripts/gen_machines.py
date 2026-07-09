#!/usr/bin/env python3
"""
Genera un PNG placeholder para cada máquina (18 archivos).
"""
import os
import json
from PIL import Image, ImageDraw, ImageFont

BASE = os.path.dirname(__file__)
MACHINES_JSON = os.path.join(BASE, '..', 'app', 'assets', 'data', 'machines.json')
OUT_DIR = os.path.join(BASE, '..', 'app', 'assets', 'images', 'machines')
os.makedirs(OUT_DIR, exist_ok=True)

W = H = 400
BG = (250, 250, 250, 255)
DARK = (50, 50, 50, 255)
MUTED = (180, 180, 180, 255)
ACCENT = (255, 107, 107, 255)


def get_font(size):
    for path in [
        '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
        '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf',
    ]:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def draw_machine(img, m):
    d = ImageDraw.Draw(img)
    d.rectangle([(0, 0), (W, 60)], fill=DARK)
    f1 = get_font(20)
    d.text((16, 18), m['name_es'][:30], fill=(255, 255, 255), font=f1)
    cx, cy = W // 2, H // 2
    # forma genérica de máquina: asiento + respaldo + palanca
    # respaldo
    d.rectangle([(cx-60, cy-100), (cx+60, cy-20)], outline=DARK, width=2, fill=(220, 220, 220))
    # asiento
    d.rectangle([(cx-50, cy-20), (cx+50, cy+20)], outline=DARK, width=2, fill=(200, 200, 200))
    # base
    d.rectangle([(cx-60, cy+20), (cx+60, cy+60)], outline=DARK, width=2, fill=(170, 170, 170))
    # palanca / mango
    d.line([(cx-80, cy-30), (cx+80, cy-30)], fill=ACCENT, width=4)
    d.ellipse([(cx-90, cy-40), (cx-70, cy-20)], fill=ACCENT)
    d.ellipse([(cx+70, cy-40), (cx+90, cy-20)], fill=ACCENT)
    # pie
    d.line([(cx, cy+60), (cx, cy+120)], fill=DARK, width=3)
    d.rectangle([(cx-50, cy+120), (cx+50, cy+135)], fill=DARK)
    # footer
    f2 = get_font(12)
    muscles = m.get('primary_muscles', [])
    if muscles:
        text = 'Trabaja: ' + ', '.join(muscles)[:50]
    else:
        text = 'Equipo multi-ángulo'
    d.text((16, H - 24), text, fill=MUTED, font=f2)


def main():
    with open(MACHINES_JSON) as f:
        ms = json.load(f)
    for m in ms:
        img = Image.new('RGBA', (W, H), BG)
        draw_machine(img, m)
        path = os.path.join(OUT_DIR, f"{m['id']}.png")
        img.save(path, optimize=True)
        size_kb = os.path.getsize(path) / 1024
        print(f'  OK  {m["id"]}.png ({size_kb:.1f} KB)')
    print(f'Generados: {len(ms)} máquinas en {OUT_DIR}')


if __name__ == '__main__':
    main()
