#!/usr/bin/env python3
"""Images for the web page (docs/, published at lifeos.com.tr/kupler/) from
the review screenshots of the real app.

    python3 tool/make_site_images.py

Run the screenshot tools first (they write to build/): home_screenshots,
sugar_screenshots, chain_screenshots, blocks_screenshots,
story_screenshots and gifts_screenshots (all under tool/, run with
`flutter test`). Writes to docs/images/web/:
  shot-<name>.webp   phone screenshots, 600 px wide
  og.png             1200×630 link preview (Open Graph / Twitter)
Needs Pillow. Unlike make_web_images.py it does not read the App Store
screenshots.
"""

import pathlib

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
BUILD = ROOT / 'build'
OUT = ROOT / 'docs/images/web'
FONT = ROOT / 'assets/fonts/Baloo2-ExtraBold.ttf'
BODY = ROOT / 'assets/fonts/Inter-SemiBold.otf'
BG_TOP, BG_BOTTOM = (74, 38, 150), (36, 20, 90)

SHOTS = {
    'home': 'home-shots/toyHd-telefon.png',
    'sugar': 'sugar-shots/oyun.png',
    'sugar-rush': 'sugar-shots/sov.png',
    'sugar-win': 'sugar-shots/kazandin.png',
    'sugar-map': 'sugar-shots/harita.png',
    'chain': 'chain-shots/chain.png',
    'puzzle-combo': 'blocks-shots/kombo.png',
    'puzzle-jewels': 'blocks-shots/mucevher.png',
    'story': 'story-shots/story-0.png',
    'wardrobe': 'story-shots/wardrobe.png',
    'gifts': 'gift-shots/gifts-top.png',
    'album': 'gift-shots/album.png',
}


def shots():
    for name, rel in SHOTS.items():
        img = Image.open(BUILD / rel).convert('RGB')
        img = img.resize((600, round(img.height * 600 / img.width)), Image.LANCZOS)
        img.save(OUT / f'shot-{name}.webp', quality=82, method=6)
        yield name


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
    # Three phones on the right, Şeker Küpler in front.
    for name, x, y, height in [('chain', 650, 120, 470), ('puzzle-combo', 980, 120, 470), ('sugar', 800, 50, 560)]:
        src = Image.open(BUILD / SHOTS[name]).convert('RGB')
        phone = rounded(src.resize((round(src.width * height / src.height), height), Image.LANCZOS), 26)
        shadow = Image.new('RGBA', (phone.width + 60, phone.height + 60), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle((30, 40, phone.width + 30, phone.height + 40), 30, fill=(0, 0, 0, 150))
        shadow = shadow.filter(ImageFilter.GaussianBlur(18))
        canvas.paste(shadow, (x - 30, y - 30), shadow)
        canvas.paste(phone, (x, y), phone)
    icon = rounded(Image.open(ROOT / 'assets/icon/icon.png').resize((110, 110), Image.LANCZOS), 26)
    canvas.paste(icon, (64, 70), icon)
    title = ImageFont.truetype(str(FONT), 88)
    body = ImageFont.truetype(str(BODY), 28)
    draw = ImageDraw.Draw(canvas)
    draw.text((60, 196), 'Küpler', font=title, fill=(255, 197, 61))
    draw.text((64, 300), 'Şeker ve Blok Oyunları', font=ImageFont.truetype(str(FONT), 48), fill=(255, 248, 235))
    draw.text((64, 404), 'Şeker, Zincir, Bulmaca ve daha fazlası', font=body, fill=(230, 220, 250))
    draw.text((64, 448), 'Tarayıcıda oyna ya da ücretsiz indir', font=body, fill=(255, 210, 120))
    draw.text((64, 492), 'Android · iPhone · Windows · Linux · Web', font=body, fill=(190, 178, 225))
    canvas.save(OUT / 'og.png', optimize=True)


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    print('screenshots:', ', '.join(shots()))
    og()
    print('og.png')
