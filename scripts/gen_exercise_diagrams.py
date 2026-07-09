#!/usr/bin/env python3
"""
Genera un PNG placeholder para cada ejercicio (24 archivos).
Estos se usan como fallback antes de generar diagramas específicos.
La app tintará los músculos sobre la silueta base en runtime.

Para ejercicios individuales, en versiones futuras se generarán
diagramas específicos con vector graphics por ejercicio.

Uso: python3 scripts/gen_exercise_diagrams.py
"""
import os
import json
from PIL import Image, ImageDraw, ImageFont

BASE = os.path.dirname(__file__)
EXERCISES_JSON = os.path.join(BASE, '..', 'app', 'assets', 'data', 'exercises.json')
OUT_DIR = os.path.join(BASE, '..', 'app', 'assets', 'images', 'exercises')
os.makedirs(OUT_DIR, exist_ok=True)

W = H = 400
BG = (250, 250, 250, 255)
DARK = (50, 50, 50, 255)
MUTED = (180, 180, 180, 255)
ACCENT = (0, 230, 118, 255)


def get_font(size):
    for path in [
        '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
        '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf',
    ]:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def draw_exercise(img, ex):
    d = ImageDraw.Draw(img)
    # Header
    d.rectangle([(0, 0), (W, 60)], fill=DARK)
    title = ex['name_es'][:30]
    f1 = get_font(20)
    d.text((16, 18), title, fill=(255, 255, 255), font=f1)
    # Body: silueta con músculos marcados
    cx, cy = W // 2, H // 2
    # cabeza
    d.ellipse([(cx-25, cy-110), (cx+25, cy-60)], outline=DARK, width=2)
    # torso
    d.polygon([
        (cx-40, cy-60), (cx+40, cy-60),
        (cx+30, cy+30), (cx-30, cy+30),
    ], outline=DARK, width=2)
    # piernas
    d.line([(cx-15, cy+30), (cx-20, cy+110)], fill=DARK, width=3)
    d.line([(cx+15, cy+30), (cx+20, cy+110)], fill=DARK, width=3)
    # marcar músculos primarios con círculos verdes
    muscles = ex.get('primary_muscles', [])
    accent_rgba = (0, 230, 118, 200)
    for i, m in enumerate(muscles[:4]):
        # posiciones aproximadas por nombre
        x, y = muscle_hint(m, cx, cy)
        d.ellipse([(x-10, y-10), (x+10, y+10)], fill=accent_rgba)
    # footer: categoría
    f2 = get_font(14)
    cat = ex.get('category', '').upper()
    pat = ex.get('pattern', '').replace('_', ' ')
    d.text((16, H - 50), f'{cat} · {pat}', fill=MUTED, font=f2)
    d.text((16, H - 30), f'{len(ex.get("primary_muscles", []))} músculos primarios', fill=MUTED, font=f2)


def muscle_hint(muscle_id, cx, cy):
    """Posición aproximada de un músculo en el cuerpo (front por defecto)."""
    m = muscle_id
    if 'pectoralis' in m:
        return cx - 10, cy - 40
    if 'deltoid_anterior' in m or 'deltoid_lateral' in m:
        return cx - 50, cy - 50
    if 'deltoid_posterior' in m:
        return cx + 60, cy - 50
    if 'biceps' in m or 'brachialis' in m:
        return cx - 70, cy
    if 'triceps' in m:
        return cx + 70, cy
    if 'lat' in m or 'trapezius' in m or 'rhomboid' in m:
        return cx, cy - 30
    if 'rectus' in m or 'abdomin' in m or 'obliqu' in m:
        return cx, cy + 10
    if 'erector' in m:
        return cx, cy + 30
    if 'quad' in m:
        return cx - 25, cy + 70
    if 'hamstring' in m:
        return cx + 25, cy + 70
    if 'glute' in m:
        return cx, cy + 40
    if 'gastroc' in m or 'soleus' in m or 'calf' in m:
        return cx, cy + 95
    return cx, cy


def main():
    with open(EXERCISES_JSON) as f:
        exs = json.load(f)
    for ex in exs:
        img = Image.new('RGBA', (W, H), BG)
        draw_exercise(img, ex)
        path = os.path.join(OUT_DIR, f"{ex['id']}.png")
        img.save(path, optimize=True)
        size_kb = os.path.getsize(path) / 1024
        print(f'  OK  {ex["id"]}.png ({size_kb:.1f} KB)')
    print(f'Generados: {len(exs)} diagramas en {OUT_DIR}')


if __name__ == '__main__':
    main()
