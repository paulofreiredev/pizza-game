"""Resize the generated master into Android density and safe-area variants.

Run from the repository root with Python and Pillow installed.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'android/app/src/main/res'
MASTER = Image.open(ROOT / 'assets/images/branding/calabresa-mark.png').convert('RGBA')


def export(destination, canvas_size, pizza_size, background=(0, 0, 0, 0)):
    canvas = Image.new('RGBA', (canvas_size, canvas_size), background)
    pizza = MASTER.resize((pizza_size, pizza_size), Image.Resampling.LANCZOS)
    offset = (canvas_size - pizza_size) // 2
    canvas.alpha_composite(pizza, (offset, offset))
    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination)


for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    export(RES / f'mipmap-{density}/ic_launcher.png', size, round(size * .82), (255, 246, 229, 255))

# 108dp adaptive layer: pizza remains inside the 66dp safe circle.
export(RES / 'drawable-xxxhdpi/pizza_icon_foreground.png', 432, 256)
# 288dp Android 12 splash: artwork remains inside its 192dp safe circle.
export(RES / 'drawable-xxxhdpi/pizza_splash.png', 1152, 720)
