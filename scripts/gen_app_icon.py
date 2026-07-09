#!/usr/bin/env python3
"""
Genera iconos de la app SuperFit para Android (launcher icons).
Genera todos los tamaños estándar.
"""
import os
from PIL import Image, ImageDraw

OUT_BASE = os.path.join(os.path.dirname(__file__), '..', 'app', 'android', 'app', 'src', 'main', 'res')

SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

PRIMARY = (0, 230, 118, 255)
PRIMARY_DARK = (0, 191, 165, 255)
BG = (14, 14, 16, 255)


def draw_icon(size):
    img = Image.new('RGBA', (size, size), BG)
    d = ImageDraw.Draw(img)
    # fondo redondeado
    r = int(size * 0.2)
    d.rounded_rectangle([(0, 0), (size, size)], radius=r, fill=BG)
    # círculo central con gradient (simulado)
    cx, cy = size // 2, size // 2
    cr = int(size * 0.35)
    d.ellipse([(cx-cr, cy-cr), (cx+cr, cy+cr)], fill=PRIMARY)
    # barra de pesas (representación minimalista)
    bw = int(size * 0.06)
    bh = int(size * 0.45)
    # barra vertical (cuerpo)
    bar_x = cx - int(bw / 2)
    d.rounded_rectangle([(bar_x, cy - bh//2), (bar_x + bw, cy + bh//2)], radius=int(bw/2), fill=(0, 0, 0))
    # discos a los lados
    disk_w = int(size * 0.15)
    disk_h = int(size * 0.30)
    d.rounded_rectangle([(cx - int(size*0.3) - disk_w//2, cy - disk_h//2), (cx - int(size*0.3) + disk_w//2, cy + disk_h//2)], radius=int(disk_w*0.3), fill=(0, 0, 0))
    d.rounded_rectangle([(cx + int(size*0.3) - disk_w//2, cy - disk_h//2), (cx + int(size*0.3) + disk_w//2, cy + disk_h//2)], radius=int(disk_w*0.3), fill=(0, 0, 0))
    return img


def main():
    for folder, size in SIZES.items():
        out_dir = os.path.join(OUT_BASE, folder)
        os.makedirs(out_dir, exist_ok=True)
        icon = draw_icon(size)
        path = os.path.join(out_dir, 'ic_launcher.png')
        icon.save(path, optimize=True)
        size_kb = os.path.getsize(path) / 1024
        print(f'  OK  {folder}/ic_launcher.png ({size}x{size}, {size_kb:.1f} KB)')
    # También foreground y background para adaptive icon
    fg_dir = os.path.join(OUT_BASE, 'mipmap-xxxhdpi')
    fg = Image.new('RGBA', (192, 192), (0, 0, 0, 0))
    d = ImageDraw.Draw(fg)
    cx, cy = 96, 96
    cr = 50
    d.ellipse([(cx-cr, cy-cr), (cx+cr, cy+cr)], fill=PRIMARY)
    bw = 14
    bh = 90
    d.rounded_rectangle([(cx-bw//2, cy-bh//2), (cx+bw//2, cy+bh//2)], radius=7, fill=(0,0,0))
    disk_w, disk_h = 32, 60
    d.rounded_rectangle([(cx-72-disk_w//2, cy-disk_h//2), (cx-72+disk_w//2, cy+disk_h//2)], radius=10, fill=(0,0,0))
    d.rounded_rectangle([(cx+72-disk_w//2, cy-disk_h//2), (cx+72+disk_w//2, cy+disk_h//2)], radius=10, fill=(0,0,0))
    fg.save(os.path.join(OUT_BASE, 'mipmap-xxxhdpi', 'ic_launcher_foreground.png'), optimize=True)
    print('  OK  ic_launcher_foreground.png')


if __name__ == '__main__':
    main()
