#!/usr/bin/env python3
"""Images for the web page (docs/, published at lifeos.com.tr/kupler/).

    python3 tool/make_web_images.py

Reads the App Store screenshots (ios/metadata/screenshots/tr, made by
tool/store_screenshots_test.dart) and writes to docs/images/web/:
  shot-<scene>.webp   phone screenshots, 600 px wide
  og.png              1200×630 link preview (Open Graph / Twitter)
Needs Pillow.
"""

import pathlib

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHOTS = ROOT / 'ios/metadata/screenshots/tr'
OUT = ROOT / 'docs/images/web'
FONT = ROOT / 'assets/fonts/Baloo2-ExtraBold.ttf'
BODY = ROOT / 'assets/fonts/Inter-SemiBold.otf'
BG_TOP, BG_BOTTOM = (61, 50, 84), (30, 24, 41)


def shots():
    for path in sorted(SHOTS.glob('iphone-*.png')):
        scene = path.stem.split('-', 2)[2]
        img = Image.open(path).convert('RGB')
        img = img.resize((600, round(img.height * 600 / img.width)), Image.LANCZOS)
        img.save(OUT / f'shot-{scene}.webp', quality=82, method=6)
        yield scene


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *img.size), radius, fill=255)
    out = img.convert('RGBA')
    out.putalpha(mask)
    return out


def og():
    w, h = 1200, 630
    canvas = Image.new('RGB', (w, h))
    draw = ImageDraw.Draw(canvas)
    for y in range(h):
        t = y / h
        draw.line([(0, y), (w, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM)))
    # Three phones on the right, the middle one in front.
    for scene, x, y, scale in [('bomb', 690, 120, 0.42), ('puzzle', 990, 120, 0.42), ('tetris', 820, 60, 0.5)]:
        src = Image.open(SHOTS / f'iphone-{["menu", "tetris", "bomb", "puzzle", "bombs", "pixel"].index(scene) + 1}-{scene}.png')
        phone = rounded(src.resize((round(src.width * scale * 0.5), round(src.height * scale * 0.5)), Image.LANCZOS), 28)
        shadow = Image.new('RGBA', (phone.width + 60, phone.height + 60), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle((30, 40, phone.width + 30, phone.height + 40), 30, fill=(0, 0, 0, 140))
        shadow = shadow.filter(ImageFilter.GaussianBlur(18))
        canvas.paste(shadow, (x - 30, y - 30), shadow)
        canvas.paste(phone, (x, y), phone)
    icon = rounded(Image.open(ROOT / 'assets/icon/icon.png').resize((120, 120), Image.LANCZOS), 28)
    canvas.paste(icon, (72, 96), icon)
    title = ImageFont.truetype(str(FONT), 92)
    body = ImageFont.truetype(str(BODY), 30)
    draw = ImageDraw.Draw(canvas)
    draw.text((68, 236), 'LifeOS', font=title, fill=(255, 248, 235))
    draw.text((68, 326), 'Küpler', font=title, fill=(255, 197, 61))
    draw.text((72, 452), 'Blokları diz, satırları patlat!', font=body, fill=(214, 205, 232))
    draw.text((72, 500), 'Android · iPhone · Windows · Linux', font=body, fill=(160, 150, 184))
    canvas.save(OUT / 'og.png', optimize=True)


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    print('screenshots:', ', '.join(shots()))
    og()
    print('og.png')
