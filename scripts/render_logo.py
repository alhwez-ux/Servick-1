"""Flat Servick badges: an S-handled screwdriver and a gear hub shaped as س."""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

AMBER = (245, 158, 11, 255)
NAVY = (30, 58, 138, 255)
FONT = ImageFont.truetype("/workspace/assets/fonts/Cairo-Bold.ttf", 64)
ROOT = Path("/tmp/servick-logo")
ROOT.mkdir(exist_ok=True)

# Logical badge matches a wider Servick chip: 72 x 28, drawn at 8x.
W, H = 72 * 8, 28 * 8
RADIUS = 8 * 8


def blank():
    image = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((0, 0, W - 1, H - 1), radius=RADIUS, fill=AMBER)
    return image, draw


def screwdriver():
    image, draw = blank()
    font = ImageFont.truetype("/workspace/assets/fonts/Cairo-Bold.ttf", 156)
    box = font.getbbox("S")
    tw, th = box[2] - box[0], box[3] - box[1]
    tx = 28 - box[0]
    ty = (H - th) / 2 - box[1]
    draw.text((tx, ty), "S", font=font, fill=NAVY)

    right = tx + tw - 6
    mid = ty + box[1] + th / 2
    shaft_h = 22
    blade_x = W - 92
    draw.rounded_rectangle(
        (right, mid - shaft_h / 2, blade_x, mid + shaft_h / 2),
        radius=6,
        fill=NAVY,
    )
    blade_h = 58
    draw.rounded_rectangle(
        (blade_x - 2, mid - blade_h / 2, W - 30, mid + blade_h / 2),
        radius=8,
        fill=NAVY,
    )
    return image


def gear_points(cx, cy, teeth, r_tip, r_root):
    points = []
    for index in range(teeth):
        center = -math.pi / 2 + index * 2 * math.pi / teeth
        half = math.pi / teeth * 0.46
        for angle, radius in (
            (center - half * 1.35, r_root),
            (center - half * 0.62, r_tip),
            (center + half * 0.62, r_tip),
            (center + half * 1.35, r_root),
        ):
            points.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    return points


def gear():
    image, draw = blank()
    cx, cy = W / 2, H / 2
    draw.polygon(gear_points(cx, cy, 8, 104, 78), fill=NAVY)
    font = ImageFont.truetype("/workspace/assets/fonts/Cairo-Bold.ttf", 92)
    draw.text((cx, cy + 2), "س", font=font, fill=AMBER, anchor="mm", direction="rtl", language="ar")
    return image


def app_icon(size):
    image = Image.new("RGBA", (size, size), AMBER)
    draw = ImageDraw.Draw(image)
    scale = size / 1024

    font_s = ImageFont.truetype("/workspace/assets/fonts/Cairo-Bold.ttf", int(320 * scale))
    box = font_s.getbbox("S")
    tw, th = box[2] - box[0], box[3] - box[1]
    sx = 88 * scale - box[0]
    sy = (size - th) / 2 - box[1]
    draw.text((sx, sy), "S", font=font_s, fill=NAVY)
    right = sx + tw - 36 * scale
    mid = sy + box[1] + th / 2
    shaft = 15 * scale
    blade_x = 400 * scale
    draw.rounded_rectangle(
        (right, mid - shaft, blade_x, mid + shaft),
        radius=max(2, int(6 * scale)),
        fill=NAVY,
    )
    blade_h = 44 * scale
    draw.rounded_rectangle(
        (blade_x - 2 * scale, mid - blade_h, 468 * scale, mid + blade_h),
        radius=max(2, int(8 * scale)),
        fill=NAVY,
    )

    cx, cy = 730 * scale, size / 2
    draw.polygon(gear_points(cx, cy, 8, 200 * scale, 150 * scale), fill=NAVY)
    font_ar = ImageFont.truetype("/workspace/assets/fonts/Cairo-Bold.ttf", int(170 * scale))
    draw.text(
        (cx, cy + 6 * scale),
        "س",
        font=font_ar,
        fill=AMBER,
        anchor="mm",
        direction="rtl",
        language="ar",
    )
    return image


screw = screwdriver()
cog = gear()
screw.save(ROOT / "screwdriver.png")
cog.save(ROOT / "gear.png")
icon = app_icon(1024)
icon.save(ROOT / "icon.png")

header = Image.new("RGB", (900, 120), (30, 58, 138))
small_s = screw.resize((216, 84), Image.Resampling.LANCZOS)
small_g = cog.resize((216, 84), Image.Resampling.LANCZOS)
header.paste(small_g, (40, 18), small_g)
header.paste(small_s, (640, 18), small_s)
draw = ImageDraw.Draw(header)
name_font = ImageFont.truetype("/workspace/assets/fonts/Cairo-Bold.ttf", 48)
draw.text((450, 60), "سيرفيسك", font=name_font, fill=(255, 255, 255), anchor="mm", direction="rtl", language="ar")
header.save(ROOT / "header.png")

brand = Path("/workspace/assets/brand")
web_icons = Path("/workspace/web/icons")
screw.save(brand / "badge_screwdriver.png")
cog.save(brand / "badge_gear.png")
mark = icon.convert("RGB")
mark.save(brand / "servick_mark.png")
mark.resize((512, 512), Image.Resampling.LANCZOS).save(web_icons / "Icon-512.png")
mark.resize((512, 512), Image.Resampling.LANCZOS).save(web_icons / "Icon-maskable-512.png")
mark.resize((192, 192), Image.Resampling.LANCZOS).save(web_icons / "Icon-192.png")
mark.resize((192, 192), Image.Resampling.LANCZOS).save(web_icons / "Icon-maskable-192.png")
mark.resize((32, 32), Image.Resampling.LANCZOS).save(Path("/workspace/web/favicon.png"))
screw.save(web_icons / "badge-screwdriver.png")
cog.save(web_icons / "badge-gear.png")
print("exported")
