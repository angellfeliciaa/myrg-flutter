"""Draws the Raja Gadai app icon (purple, lime zigzag, white "RG") into the Android launcher folders.

    python tool/make_launcher_icon.py

Drawn, not scaled from a small picture, so it is sharp at every density. Geometry and colours
were measured from Raja Gadai's 240 px store icon: lime #A9CE37 band with a zigzag top (two
teeth), purple #632B8D below it, "RG" in white. Writes the legacy icons (mipmap-*/ic_launcher.png)
and the adaptive icon for Android 8+ (mipmap-*/ic_launcher_foreground.png + anydpi-v26 XML).
Needs Pillow and the Segoe UI Bold font (Windows).
"""

import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
FONT = r'C:\Windows\Fonts\segoeuib.ttf'

WHITE, LIME, PURPLE = (255, 255, 255, 255), (169, 206, 55, 255), (99, 43, 141, 255)
SS = 4  # supersampling for smooth edges

# Design units: the store icon is 240 x 240.
PEAK_Y, VALLEY_Y, BAND = 2, 32, 53       # zigzag top of the lime band; band thickness
PERIOD = 120                              # one tooth (peaks at 0, 120, 240)
LETTERS = (59, 121, 187, 191)             # "RG" box


def zigzag(x0, x1, offset):
    """Points of the zigzag from x0 to x1 (design units), moved down by offset."""
    pts = []
    start = int(x0 // (PERIOD / 2)) - 1
    end = int(x1 // (PERIOD / 2)) + 2
    for i in range(start, end):
        x = i * PERIOD / 2
        pts.append((x, (PEAK_Y if i % 2 == 0 else VALLEY_Y) + offset))
    return pts


def draw(size, design_square):
    """design_square: (left, top, side) of the 240-unit design inside the size x size canvas."""
    big = size * SS
    left, top, side = (v * SS for v in design_square)
    k = side / 240
    to_px = lambda p: (left + p[0] * k, top + p[1] * k)
    x0, x1 = -left / k, (big - left) / k  # visible design range, extended for the adaptive icon

    im = Image.new('RGBA', (big, big), WHITE)
    d = ImageDraw.Draw(im)
    bottom = (big - top) / k + 240
    lime = zigzag(x0, x1, 0)
    purple = zigzag(x0, x1, BAND)
    d.polygon([to_px(p) for p in lime] + [to_px((lime[-1][0], bottom)), to_px((lime[0][0], bottom))], fill=LIME)
    d.polygon([to_px(p) for p in purple] + [to_px((purple[-1][0], bottom)), to_px((purple[0][0], bottom))], fill=PURPLE)

    # "RG": fitted to the measured box.
    lx0, ly0, lx1, ly1 = LETTERS
    box_w, box_h = (lx1 - lx0) * k, (ly1 - ly0) * k
    font_size = int(box_h * 1.4)
    while True:
        font = ImageFont.truetype(FONT, font_size)
        bx = d.textbbox((0, 0), 'RG', font=font)
        if bx[2] - bx[0] <= box_w and bx[3] - bx[1] <= box_h:
            break
        font_size -= 2
    w, h = bx[2] - bx[0], bx[3] - bx[1]
    cx, cy = left + (lx0 + lx1) / 2 * k, top + (ly0 + ly1) / 2 * k
    d.text((cx - w / 2 - bx[0], cy - h / 2 - bx[1]), 'RG', font=font, fill=WHITE)
    return im.resize((size, size), Image.LANCZOS)


def main():
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for name, f in densities.items():
        folder = os.path.join(RES, f'mipmap-{name}')
        os.makedirs(folder, exist_ok=True)
        legacy = round(48 * f)
        draw(legacy, (0, 0, legacy)).save(os.path.join(folder, 'ic_launcher.png'))
        # Adaptive: 108 dp canvas, the launcher shows about the middle 72 dp.
        fg = round(108 * f)
        inset = round(18 * f)
        draw(fg, (inset, inset, fg - 2 * inset)).save(os.path.join(folder, 'ic_launcher_foreground.png'))

    anydpi = os.path.join(RES, 'mipmap-anydpi-v26')
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, 'ic_launcher.xml'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('<?xml version="1.0" encoding="utf-8"?>\n'
                 '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                 '    <background android:drawable="@color/ic_launcher_background"/>\n'
                 '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                 '</adaptive-icon>\n')
    with open(os.path.join(RES, 'values', 'ic_launcher_background.xml'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
                 '    <color name="ic_launcher_background">#FFFFFF</color>\n</resources>\n')
    draw(512, (0, 0, 512)).save(os.path.join(ROOT, 'tool', 'launcher_icon_preview.png'))
    print('icons written; preview: tool/launcher_icon_preview.png')


if __name__ == '__main__':
    main()
