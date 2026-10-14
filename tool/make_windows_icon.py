"""Builds windows/runner/resources/app_icon.ico with every size Windows asks
for (taskbar, title bar, Explorer views, Alt+Tab).

flutter_launcher_icons writes a single 256 px image, which some Windows
views don't scale down and show the default icon instead. Small sizes are
stored as classic bitmaps and 256 px as PNG, the layout Windows' own icons use.

    python3 tool/make_windows_icon.py
"""

import io
import struct
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/icon/icon.png"
TARGET = ROOT / "windows/runner/resources/app_icon.ico"
SIZES = [16, 20, 24, 32, 40, 48, 64, 96, 128, 256]


def entry(image: Image.Image, size: int) -> bytes:
    scaled = image.resize((size, size), Image.LANCZOS)
    buffer = io.BytesIO()
    if size >= 256:
        scaled.save(buffer, format="PNG", optimize=True)
        return buffer.getvalue()
    # A single-size BMP-flavoured .ico from Pillow; keep only its image data.
    scaled.save(buffer, format="ICO", sizes=[(size, size)], bitmap_format="bmp")
    data = buffer.getvalue()
    length, offset = struct.unpack("<II", data[14:22])
    return data[offset : offset + length]


def main() -> None:
    image = Image.open(SOURCE).convert("RGBA")
    blobs = [entry(image, s) for s in SIZES]
    header = struct.pack("<HHH", 0, 1, len(SIZES))
    offset = len(header) + 16 * len(SIZES)
    directory = b""
    for size, blob in zip(SIZES, blobs):
        dim = 0 if size >= 256 else size
        directory += struct.pack("<BBBBHHII", dim, dim, 0, 0, 1, 32, len(blob), offset)
        offset += len(blob)
    TARGET.write_bytes(header + directory + b"".join(blobs))
    print(f"wrote {TARGET.relative_to(ROOT)} ({TARGET.stat().st_size // 1024} KB, {len(SIZES)} sizes)")


if __name__ == "__main__":
    main()
