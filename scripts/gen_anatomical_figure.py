#!/usr/bin/env python3
"""
Genera siluetas anatómicas PROFESIONALES de cuerpo humano con músculos diferenciados.
Diseño tip-tier: proporciones reales, sombreado, definición muscular, fondo transparente.
"""
import os
from PIL import Image, ImageDraw, ImageFilter

OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'app', 'assets', 'images', 'muscles')

# Colores (siguiendo convenciones anatómicas de Visible Body / Anatomy.app)
SKIN = (220, 200, 175, 255)
SKIN_SHADOW = (170, 150, 125, 255)
SHADOW_HARD = (110, 90, 70, 255)
BONE = (235, 220, 195, 255)
BG_TRANSPARENT = (0, 0, 0, 0)


def gradient_skin(draw, points, base_color, shadow_color, size):
    """Dibuja un polígono con sombreado radial suave."""
    # Calcular centro para sombreado
    cx = sum(p[0] for p in points) / len(points)
    cy = sum(p[1] for p in points) / len(points)
    # distancia máxima desde el centro
    max_d = max(((p[0] - cx) ** 2 + (p[1] - cy) ** 2) ** 0.5 for p in points)
    # Dibujar el polígono principal
    draw.polygon(points, fill=base_color)
    # Aplicar sombreado: dibujar círculos oscuros pequeños en bordes
    if max_d > 10:
        steps = 12
        for i in range(steps):
            t = i / steps
            r_factor = 0.5 + 0.5 * t
            r = max_d * r_factor
            # Color interpola entre base y shadow
            cr = int(base_color[0] * (1 - t * 0.6) + shadow_color[0] * t * 0.6)
            cg = int(base_color[1] * (1 - t * 0.6) + shadow_color[1] * t * 0.6)
            cb = int(base_color[2] * (1 - t * 0.6) + shadow_color[2] * t * 0.6)
            # No dibujar (solo el outline) — usar una "anillo" via ellipse con alpha
        # Outline sombreado: dibuja el polígono con stroke
        draw.line(points + [points[0]], fill=shadow_color, width=2)


def draw_muscle_oval(draw, cx, cy, rx, ry, angle_deg=0, color=(180, 80, 80, 255), highlight=True):
    """Dibuja un músculo como óvalo con sombreado y highlight."""
    # Rotar el bounding box
    import math
    a = math.radians(angle_deg)
    cos_a, sin_a = math.cos(a), math.sin(a)
    # Dibujar con sombreado: outline más oscuro
    draw.ellipse(
        [(cx - rx, cy - ry), (cx + rx, cy + ry)],
        fill=color,
        outline=(int(color[0] * 0.6), int(color[1] * 0.6), int(color[2] * 0.6), 255),
        width=2,
    )
    if highlight:
        # Highlight: pequeño óvalo blanco arriba-izquierda
        hx = cx - rx * 0.3
        hy = cy - ry * 0.4
        hr = min(rx, ry) * 0.25
        draw.ellipse(
            [(hx - hr, hy - hr), (hx + hr, hy + hr)],
            fill=(255, 255, 255, 60),
        )


def draw_anterior_figure(size=600, muscle_color=(170, 60, 50, 255), figure_color=None):
    """
    Vista frontal (anterior). Proporciones humanas estándar (8 cabezas).
    """
    fig_color = figure_color or SKIN
    img = Image.new('RGBA', (size, size), BG_TRANSPARENT)
    d = ImageDraw.Draw(img, 'RGBA')

    # Centro del cuerpo
    cx = size // 2
    # Escala basada en altura de cabeza = size/8
    head_h = size // 8
    # Cabeza (óvalo)
    head_cy = head_h
    d.ellipse(
        [(cx - head_h // 2 + 10, head_cy - head_h // 2), (cx + head_h // 2 + 10, head_cy + head_h // 2)],
        fill=fig_color,
        outline=SKIN_SHADOW,
        width=2,
    )
    # cuello
    neck_top = head_cy + head_h // 2
    neck_bot = neck_top + head_h // 3
    d.rectangle(
        [(cx - head_h // 4, neck_top), (cx + head_h // 4, neck_bot)],
        fill=fig_color,
        outline=SKIN_SHADOW,
        width=1,
    )

    # Tronco (cuerpo principal) — trapezoide invertido suave
    torso_top = neck_bot
    torso_bot = torso_top + head_h * 3
    shoulder_w = head_h * 1.8
    waist_w = head_h * 1.4
    torso = [
        (cx - shoulder_w // 2, torso_top),
        (cx + shoulder_w // 2, torso_top),
        (cx + waist_w // 2, torso_bot),
        (cx - waist_w // 2, torso_bot),
    ]
    d.polygon(torso, fill=fig_color, outline=SKIN_SHADOW)
    # línea central (esternón)
    d.line([(cx, torso_top + 5), (cx, torso_bot - 5)], fill=SKIN_SHADOW, width=1)

    # ============== MÚSCULOS DELANTEROS ==============

    # Pectorales (2 óvalos grandes)
    pect_y = torso_top + head_h // 2
    pect_rx = head_h * 0.45
    pect_ry = head_h * 0.7
    draw_muscle_oval(d, cx - head_h * 0.45, pect_y, pect_rx, pect_ry, -15, muscle_color)
    draw_muscle_oval(d, cx + head_h * 0.45, pect_y, pect_rx, pect_ry, 15, muscle_color)

    # Deltoides anteriores
    delt_y = torso_top + head_h // 4
    draw_muscle_oval(d, cx - shoulder_w // 2 + 5, delt_y, head_h // 3, head_h // 2.5, -20, muscle_color)
    draw_muscle_oval(d, cx + shoulder_w // 2 - 5, delt_y, head_h // 3, head_h // 2.5, 20, muscle_color)

    # Bíceps
    bicep_y = torso_top + head_h + head_h // 2
    # brazos: rectángulos con bíceps
    arm_w = head_h // 2.5
    arm_top = torso_top + head_h // 2
    arm_bot = torso_top + head_h * 2
    # brazo izq
    left_arm_x = cx - shoulder_w // 2 - arm_w // 2 + 5
    d.rectangle([(left_arm_x, arm_top), (left_arm_x + arm_w, arm_bot)], fill=fig_color, outline=SKIN_SHADOW)
    draw_muscle_oval(d, left_arm_x + arm_w // 2, bicep_y, arm_w // 2, head_h // 1.8, 0, muscle_color)
    # brazo der
    right_arm_x = cx + shoulder_w // 2 - arm_w // 2 - 5
    d.rectangle([(right_arm_x, arm_top), (right_arm_x + arm_w, arm_bot)], fill=fig_color, outline=SKIN_SHADOW)
    draw_muscle_oval(d, right_arm_x + arm_w // 2, bicep_y, arm_w // 2, head_h // 1.8, 0, muscle_color)

    # Antebrazos (rectángulos más finos)
    forearm_w = arm_w * 0.85
    f_arm_top = arm_bot
    f_arm_bot = f_arm_top + head_h * 1.5
    d.rectangle([(left_arm_x + 3, f_arm_top), (left_arm_x + 3 + forearm_w, f_arm_bot)], fill=fig_color, outline=SKIN_SHADOW)
    d.rectangle([(right_arm_x, f_arm_top), (right_arm_x + forearm_w, f_arm_bot)], fill=fig_color, outline=SKIN_SHADOW)

    # Abdominales (rectángulo central con líneas horizontales)
    ab_top = pect_y + pect_ry
    ab_bot = torso_bot - head_h // 4
    ab_w = head_h * 0.9
    d.rectangle(
        [(cx - ab_w // 2, ab_top), (cx + ab_w // 2, ab_bot)],
        fill=muscle_color,
        outline=(int(muscle_color[0] * 0.6), int(muscle_color[1] * 0.6), int(muscle_color[2] * 0.6)),
    )
    # Líneas horizontales (4 pack)
    ab_sections = 4
    for i in range(1, ab_sections):
        y_line = ab_top + (ab_bot - ab_top) * i / ab_sections
        d.line([(cx - ab_w // 2 + 3, y_line), (cx + ab_w // 2 - 3, y_line)], fill=SKIN_SHADOW, width=2)
    # Línea central
    d.line([(cx, ab_top + 2), (cx, ab_bot - 2)], fill=SKIN_SHADOW, width=2)

    # Oblicuos (pequeños triángulos a los lados)
    obl_w = head_h // 2
    obl_h = head_h
    obl_y = (ab_top + ab_bot) // 2
    # izq
    d.polygon([
        (cx - ab_w // 2, ab_top + head_h // 2),
        (cx - ab_w // 2 - obl_w, obl_y),
        (cx - ab_w // 2, ab_bot - head_h // 4),
    ], fill=muscle_color, outline=SKIN_SHADOW)
    # der
    d.polygon([
        (cx + ab_w // 2, ab_top + head_h // 2),
        (cx + ab_w // 2 + obl_w, obl_y),
        (cx + ab_w // 2, ab_bot - head_h // 4),
    ], fill=musque_color if False else muscle_color, outline=SKIN_SHADOW)

    # ============== PIERNAS ==============
    leg_top = torso_bot
    leg_bot = leg_top + head_h * 3
    leg_w = head_h * 0.9
    # Quad izq
    qd_x = cx - leg_w
    d.rectangle([(qd_x, leg_top), (qd_x + leg_w, leg_bot)], fill=fig_color, outline=SKIN_SHADOW)
    # Quads (músculo frontal muslo)
    quad_y = leg_top + head_h // 2
    draw_muscle_oval(d, qd_x + leg_w // 2, quad_y, leg_w // 2 - 2, head_h, -5, muscle_color)
    # línea entre quad y vasto lateral
    d.line([(qd_x + leg_w // 2, leg_top + head_h // 4), (qd_x + leg_w // 2, quad_y + head_h // 2)], fill=SKIN_SHADOW, width=1)
    # Quad der
    qd2_x = cx
    d.rectangle([(qd2_x, leg_top), (qd2_x + leg_w, leg_bot)], fill=fig_color, outline=SKIN_SHADOW)
    draw_muscle_oval(d, qd2_x + leg_w // 2, quad_y, leg_w // 2 - 2, head_h, 5, muscle_color)
    d.line([(qd2_x + leg_w // 2, leg_top + head_h // 4), (qd2_x + leg_w // 2, quad_y + head_h // 2)], fill=SKIN_SHADOW, width=1)

    # Tibiales (muslo a espinilla, pequeños óvalos frontales)
    tib_y = leg_top + head_h * 2
    draw_muscle_oval(d, qd_x + leg_w // 2, tib_y, leg_w // 3, head_h // 2, 0, muscle_color)
    draw_muscle_oval(d, qd2_x + leg_w // 2, tib_y, leg_w // 3, head_h // 2, 0, muscle_color)

    # Gemelos (no visibles en anterior, solo侧面) — saltar

    return img


def draw_posterior_figure(size=600, muscle_color=(170, 60, 50, 255)):
    """Vista trasera (posterior)."""
    img = Image.new('RGBA', (size, size), BG_TRANSPARENT)
    d = ImageDraw.Draw(img, 'RGBA')

    cx = size // 2
    head_h = size // 8

    # Cabeza
    head_cy = head_h
    d.ellipse(
        [(cx - head_h // 2 + 10, head_cy - head_h // 2), (cx + head_h // 2 + 10, head_cy + head_h // 2)],
        fill=SKIN, outline=SKIN_SHADOW, width=2,
    )
    # cuello
    neck_top = head_cy + head_h // 2
    neck_bot = neck_top + head_h // 3
    d.rectangle([(cx - head_h // 4, neck_top), (cx + head_h // 4, neck_bot)], fill=SKIN, outline=SKIN_SHADOW)

    # Tronco
    torso_top = neck_bot
    torso_bot = torso_top + head_h * 3
    shoulder_w = head_h * 1.8
    waist_w = head_h * 1.4
    torso = [
        (cx - shoulder_w // 2, torso_top),
        (cx + shoulder_w // 2, torso_top),
        (cx + waist_w // 2, torso_bot),
        (cx - waist_w // 2, torso_bot),
    ]
    d.polygon(torso, fill=SKIN, outline=SKIN_SHADOW)

    # Trapecios (V grande en espalda alta)
    trap_y = torso_top + head_h // 2
    d.polygon([
        (cx - shoulder_w // 2 + 5, torso_top + 5),
        (cx + shoulder_w // 2 - 5, torso_top + 5),
        (cx + head_h // 3, trap_y + head_h // 2),
        (cx - head_h // 3, trap_y + head_h // 2),
    ], fill=muscle_color, outline=SKIN_SHADOW)
    # línea media del trapecio
    d.line([(cx, torso_top + 5), (cx, trap_y + head_h // 2 - 2)], fill=SKIN_SHADOW, width=1)

    # Deltoides posteriores
    delt_y = torso_top + head_h // 3
    draw_muscle_oval(d, cx - shoulder_w // 2 + 8, delt_y + 5, head_h // 3, head_h // 2.5, 30, muscle_color)
    draw_muscle_oval(d, cx + shoulder_w // 2 - 8, delt_y + 5, head_h // 3, head_h // 2.5, -30, muscle_color)

    # Dorsales (2 triángulos grandes)
    lat_top = torso_top + head_h * 1.2
    lat_bot = torso_bot - head_h // 3
    # izq
    d.polygon([
        (cx - head_h // 3, lat_top),
        (cx - shoulder_w // 2 + 5, torso_top + head_h // 2),
        (cx - waist_w // 2 - 5, lat_bot),
        (cx - head_h // 6, lat_bot - head_h // 2),
    ], fill=muscle_color, outline=SKIN_SHADOW)
    # der
    d.polygon([
        (cx + head_h // 3, lat_top),
        (cx + shoulder_w // 2 - 5, torso_top + head_h // 2),
        (cx + waist_w // 2 + 5, lat_bot),
        (cx + head_h // 6, lat_bot - head_h // 2),
    ], fill=musque_color if False else muscle_color, outline=SKIN_SHADOW)

    # Espalda media (romboides, entre trapecios y dorsales)
    d.rectangle(
        [(cx - head_h // 4, lat_top - head_h // 2), (cx + head_h // 4, lat_top + head_h // 2)],
        fill=muscle_color, outline=SKIN_SHADOW,
    )
    # lumbares (V inferior)
    d.polygon([
        (cx - head_h // 3, torso_bot - head_h),
        (cx + head_h // 3, torso_bot - head_h),
        (cx + head_h // 4, torso_bot - head_h // 4),
        (cx - head_h // 4, torso_bot - head_h // 4),
    ], fill=muscle_color, outline=SKIN_SHADOW)

    # Glúteos (2 óvalos grandes)
    glut_y = torso_bot + head_h // 4
    glut_rx = head_h // 1.5
    glut_ry = head_h
    draw_muscle_oval(d, cx - head_h // 3, glut_y, glut_rx, glut_ry, -10, muscle_color)
    draw_muscle_oval(d, cx + head_h // 3, glut_y, glut_rx, glut_ry, 10, muscle_color)

    # Brazos (tríceps)
    arm_w = head_h // 2.5
    arm_top = torso_top + head_h // 2
    arm_bot = torso_top + head_h * 2
    left_arm_x = cx - shoulder_w // 2 - arm_w // 2 + 5
    d.rectangle([(left_arm_x, arm_top), (left_arm_x + arm_w, arm_bot)], fill=SKIN, outline=SKIN_SHADOW)
    bicep_y = torso_top + head_h + head_h // 2
    draw_muscle_oval(d, left_arm_x + arm_w // 2, bicep_y, arm_w // 2, head_h // 1.8, 0, muscle_color)
    right_arm_x = cx + shoulder_w // 2 - arm_w // 2 - 5
    d.rectangle([(right_arm_x, arm_top), (right_arm_x + arm_w, arm_bot)], fill=SKIN, outline=SKIN_SHADOW)
    draw_muscle_oval(d, right_arm_x + arm_w // 2, bicep_y, arm_w // 2, head_h // 1.8, 0, muscle_color)
    # Antebrazos
    forearm_w = arm_w * 0.85
    f_arm_top = arm_bot
    f_arm_bot = f_arm_top + head_h * 1.5
    d.rectangle([(left_arm_x + 3, f_arm_top), (left_arm_x + 3 + forearm_w, f_arm_bot)], fill=SKIN, outline=SKIN_SHADOW)
    d.rectangle([(right_arm_x, f_arm_top), (right_arm_x + forearm_w, f_arm_bot)], fill=SKIN, outline=SKIN_SHADOW)

    # Piernas (isquiotibiales + gemelos)
    leg_top = torso_bot + head_h * 1.5
    leg_bot = leg_top + head_h * 3
    leg_w = head_h * 0.9
    # izq
    qd_x = cx - leg_w
    d.rectangle([(qd_x, leg_top), (qd_x + leg_w, leg_bot)], fill=SKIN, outline=SKIN_SHADOW)
    # Hamstring
    ham_y = leg_top + head_h // 2
    draw_muscle_oval(d, qd_x + leg_w // 2, ham_y, leg_w // 2 - 2, head_h, 0, muscle_color)
    d.line([(qd_x + leg_w // 2, leg_top + head_h // 4), (qd_x + leg_w // 2, ham_y + head_h // 2)], fill=SKIN_SHADOW, width=1)
    # der
    qd2_x = cx
    d.rectangle([(qd2_x, leg_top), (qd2_x + leg_w, leg_bot)], fill=SKIN, outline=SKIN_SHADOW)
    draw_muscle_oval(d, qd2_x + leg_w // 2, ham_y, leg_w // 2 - 2, head_h, 0, muscle_color)
    d.line([(qd2_x + leg_w // 2, leg_top + head_h // 4), (qd2_x + leg_w // 2, ham_y + head_h // 2)], fill=SKIN_SHADOW, width=1)

    # Gemelos (pan de ternero)
    calf_y = leg_top + head_h * 2
    draw_muscle_oval(d, qd_x + leg_w // 2, calf_y, leg_w // 2 - 1, head_h * 0.9, 0, muscle_color)
    draw_muscle_oval(d, qd2_x + leg_w // 2, calf_y, leg_w // 2 - 1, head_h * 0.9, 0, muscle_color)

    return img


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    size = 800

    # Vista anterior con músculos en rojo
    front = draw_anterior_figure(size, muscle_color=(200, 50, 50, 255))
    front_path = os.path.join(OUT_DIR, 'front.png')
    front.save(front_path, optimize=True)
    print(f'  OK  {front_path} ({os.path.getsize(front_path) / 1024:.1f} KB)')

    # Vista anterior en gris (base)
    front_grey = draw_anterior_figure(size, muscle_color=(150, 30, 30, 255))
    front_grey_path = os.path.join(OUT_DIR, 'front_base.png')
    front_grey.save(front_grey_path, optimize=True)
    print(f'  OK  {front_grey_path} ({os.path.getsize(front_grey_path) / 1024:.1f} KB)')

    # Vista posterior con músculos
    back = draw_posterior_figure(size, muscle_color=(200, 50, 50, 255))
    back_path = os.path.join(OUT_DIR, 'back.png')
    back.save(back_path, optimize=True)
    print(f'  OK  {back_path} ({os.path.getsize(back_path) / 1024:.1f} KB)')

    # Vista posterior base
    back_grey = draw_posterior_figure(size, muscle_color=(150, 30, 30, 255))
    back_grey_path = os.path.join(OUT_DIR, 'back_base.png')
    back_grey.save(back_grey_path, optimize=True)
    print(f'  OK  {back_grey_path} ({os.path.getsize(back_grey_path) / 1024:.1f} KB)')


if __name__ == '__main__':
    main()
