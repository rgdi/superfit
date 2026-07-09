#!/usr/bin/env python3
"""
Genera imágenes PNG para SuperFit:
- assets/images/muscles/front.png  (silueta humana, vista frontal, en gris)
- assets/images/muscles/back.png   (silueta humana, vista trasera)

Render: PIL 800x800, fondo blanco, cuerpo gris medio, líneas finas.
Las imágenes son la "base". En la app se tintan los músculos con CustomPainter
(MuscleMapWidget) pasando sets de primary/secondary muscles.

Uso: python3 scripts/gen_muscle_maps.py
"""
import os
from PIL import Image, ImageDraw

OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'app', 'assets', 'images', 'muscles')
os.makedirs(OUT_DIR, exist_ok=True)

W = H = 800
BODY = (70, 70, 70, 255)
LINE = (40, 40, 40, 255)
BG = (245, 245, 245, 255)


def draw_front(img: Image.Image):
    d = ImageDraw.Draw(img)
    # Cabeza
    d.ellipse([(350, 40), (450, 140)], fill=BODY, outline=LINE, width=2)
    # Cuello
    d.rectangle([(380, 135), (420, 165)], fill=BODY, outline=LINE, width=2)
    # Tronco (pecho + abdomen)
    d.polygon([
        (310, 165), (490, 165),
        (475, 410),
        (425, 480),  # cintura
        (375, 480),
        (325, 410),
    ], fill=BODY, outline=LINE, width=2)
    # Hombros (deltoides)
    d.ellipse([(255, 165), (335, 270)], fill=BODY, outline=LINE, width=2)
    d.ellipse([(465, 165), (545, 270)], fill=BODY, outline=LINE, width=2)
    # Brazos
    d.rounded_rectangle([(240, 270), (305, 460)], radius=25, fill=BODY, outline=LINE, width=2)
    d.rounded_rectangle([(495, 270), (560, 460)], radius=25, fill=BODY, outline=LINE, width=2)
    # Antebrazos
    d.rounded_rectangle([(220, 460), (300, 600)], radius=20, fill=BODY, outline=LINE, width=2)
    d.rounded_rectangle([(500, 460), (580, 600)], radius=20, fill=BODY, outline=LINE, width=2)
    # Manos
    d.ellipse([(225, 595), (295, 660)], fill=BODY, outline=LINE, width=2)
    d.ellipse([(505, 595), (575, 660)], fill=BODY, outline=LINE, width=2)
    # Pelvis
    d.polygon([(340, 470), (460, 470), (475, 540), (325, 540)], fill=BODY, outline=LINE, width=2)
    # Piernas
    d.rounded_rectangle([(335, 540), (395, 760)], radius=25, fill=BODY, outline=LINE, width=2)
    d.rounded_rectangle([(405, 540), (465, 760)], radius=25, fill=BODY, outline=LINE, width=2)
    # Pies
    d.ellipse([(320, 750), (400, 790)], fill=BODY, outline=LINE, width=2)
    d.ellipse([(400, 750), (480, 790)], fill=BODY, outline=LINE, width=2)


def draw_back(img: Image.Image):
    d = ImageDraw.Draw(img)
    # Cabeza
    d.ellipse([(350, 40), (450, 140)], fill=BODY, outline=LINE, width=2)
    # Cuello + trapecio
    d.polygon([(350, 135), (450, 135), (490, 200), (310, 200)], fill=BODY, outline=LINE, width=2)
    # Tronco
    d.polygon([
        (310, 200), (490, 200),
        (475, 410),
        (425, 480),
        (375, 480),
        (325, 410),
    ], fill=BODY, outline=LINE, width=2)
    # Hombros
    d.ellipse([(255, 200), (335, 305)], fill=BODY, outline=LINE, width=2)
    d.ellipse([(465, 200), (545, 305)], fill=BODY, outline=LINE, width=2)
    # Tríceps (parte posterior brazo)
    d.rounded_rectangle([(240, 305), (305, 470)], radius=25, fill=BODY, outline=LINE, width=2)
    d.rounded_rectangle([(495, 305), (560, 470)], radius=25, fill=BODY, outline=LINE, width=2)
    # Antebrazos
    d.rounded_rectangle([(220, 470), (300, 600)], radius=20, fill=BODY, outline=LINE, width=2)
    d.rounded_rectangle([(500, 470), (580, 600)], radius=20, fill=BODY, outline=LINE, width=2)
    # Manos
    d.ellipse([(225, 595), (295, 660)], fill=BODY, outline=LINE, width=2)
    d.ellipse([(505, 595), (575, 660)], fill=BODY, outline=LINE, width=2)
    # Glúteos
    d.ellipse([(320, 470), (410, 570)], fill=BODY, outline=LINE, width=2)
    d.ellipse([(390, 470), (480, 570)], fill=BODY, outline=LINE, width=2)
    # Piernas
    d.rounded_rectangle([(335, 570), (395, 760)], radius=25, fill=BODY, outline=LINE, width=2)
    d.rounded_rectangle([(405, 570), (465, 760)], radius=25, fill=BODY, outline=LINE, width=2)
    # Pies (gemelos detrás)
    d.ellipse([(320, 750), (400, 790)], fill=BODY, outline=LINE, width=2)
    d.ellipse([(400, 750), (480, 790)], fill=BODY, outline=LINE, width=2)


def main():
    for name, fn in [('front', draw_front), ('back', draw_back)]:
        img = Image.new('RGBA', (W, H), BG)
        fn(img)
        path = os.path.join(OUT_DIR, f'{name}.png')
        img.save(path, optimize=True)
        size_kb = os.path.getsize(path) / 1024
        print(f'  OK  {name}.png ({size_kb:.1f} KB)')
    print('Generado:', OUT_DIR)


if __name__ == '__main__':
    main()
