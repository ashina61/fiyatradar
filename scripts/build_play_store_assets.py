"""FiyatRadar Play Console varlık üretici.

Çıktılar:
  play_store_assets/icon/play_store_icon_512.png            (512x512)
  play_store_assets/feature_graphic/feature_graphic_1024x500.png
  play_store_assets/screenshots/01_home.png ...05_watchlist.png (1080x1920)

Kullanım:
  python3 scripts/build_play_store_assets.py
"""

from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "play_store_assets"
LOGO_MARK = ROOT / "assets" / "images" / "app_logo.png"

# --- Brand palette (FRPalette.light tonları) -------------------------------
CREAM_BG = (251, 246, 238)
CREAM_HI = (255, 251, 244)
CREAM_LO = (243, 232, 212)
HAIRLINE = (217, 197, 164)
INK = (27, 15, 6)
INK2 = (61, 44, 28)
INK3 = (122, 104, 82)
INK4 = (169, 150, 125)
GOLD = (215, 178, 122)        # warm honey (dark palette goldHi)
GOLD_HI = (234, 203, 150)
GOLD_DEEP = (166, 114, 56)
ESPRESSO = (18, 11, 7)
ESPRESSO_HI = (42, 31, 24)
ESPRESSO_SURF = (32, 22, 17)
COPPER = (90, 52, 22)
GOOD = (47, 104, 65)
GOOD_SOFT = (217, 234, 217)
BAD = (217, 104, 94)

FONTS = {
    "regular": "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "bold": "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "mono": "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
}


def f(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONTS[weight], size)


def measure(draw: ImageDraw.ImageDraw, text: str, font) -> tuple[int, int]:
    l, t, r, b = draw.textbbox((0, 0), text, font=font)
    return r - l, b - t


def rounded_rect(
    img: Image.Image,
    xy: tuple[int, int, int, int],
    radius: int,
    fill=None,
    outline=None,
    width: int = 0,
):
    ImageDraw.Draw(img).rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def soft_shadow(
    base: Image.Image,
    xy: tuple[int, int, int, int],
    radius: int,
    blur: int = 18,
    opacity: int = 60,
    offset: tuple[int, int] = (0, 8),
):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(xy, radius=radius, fill=(0, 0, 0, opacity))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(Image.new("RGBA", base.size, (0, 0, 0, 0)).filter(ImageFilter.GaussianBlur(0)))
    base.alpha_composite(layer, (offset[0], offset[1]))


def paste_logo(canvas: Image.Image, box: tuple[int, int, int, int]):
    """Mevcut FR logosunu hedef kareye orantılı yerleştirir."""
    logo = Image.open(LOGO_MARK).convert("RGBA")
    bw, bh = box[2] - box[0], box[3] - box[1]
    size = min(bw, bh)
    logo = logo.resize((size, size), Image.LANCZOS)
    cx = box[0] + (bw - size) // 2
    cy = box[1] + (bh - size) // 2
    canvas.alpha_composite(logo, (cx, cy))


# --------------------------------------------------------------------------
# 1) APP ICON 512x512
# --------------------------------------------------------------------------

def build_app_icon() -> Path:
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Sıcak krem arka plan dairesel kare (Play Store maskeleme dostu)
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(bg).rounded_rectangle((0, 0, size, size), radius=112, fill=CREAM_BG)

    # Çapraz sıcak ışık (gold gradient overlay)
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    for i, alpha in enumerate(range(0, 60, 4)):
        r = 380 - i * 8
        gdraw.ellipse(
            (size - r - 40, -60, size + 80, r + 20),
            fill=(GOLD_HI[0], GOLD_HI[1], GOLD_HI[2], alpha),
        )
    glow = glow.filter(ImageFilter.GaussianBlur(24))

    # Maskeyi rounded yapmak için bg'nin alphası ile çarp
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size, size), radius=112, fill=255)
    bg.putalpha(mask)

    img.alpha_composite(bg)
    glow.putalpha(Image.eval(glow.split()[3], lambda a: a))
    glow_masked = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_masked.paste(glow, (0, 0), mask)
    img.alpha_composite(glow_masked)

    # Logo (merkez, biraz küçük çerçeve payı)
    pad = 64
    paste_logo(img, (pad, pad, size - pad, size - pad))

    # Hafif iç çerçeve (premium hairline)
    ImageDraw.Draw(img).rounded_rectangle(
        (4, 4, size - 4, size - 4), radius=110, outline=(GOLD_DEEP[0], GOLD_DEEP[1], GOLD_DEEP[2], 40), width=2
    )

    out = OUT / "icon" / "play_store_icon_512.png"
    img.convert("RGBA").save(out, "PNG")
    return out


# --------------------------------------------------------------------------
# 2) FEATURE GRAPHIC 1024x500
# --------------------------------------------------------------------------

def build_feature_graphic() -> Path:
    W, H = 1024, 500
    img = Image.new("RGBA", (W, H), ESPRESSO + (255,))

    # Üst sağ: sıcak altın bloom
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    for i in range(8):
        r = 520 - i * 40
        a = 22 + i * 4
        gdraw.ellipse((W - r + 120, -r // 2, W + 120, r // 2 + 40), fill=(GOLD_HI[0], GOLD_HI[1], GOLD_HI[2], a))
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    img.alpha_composite(glow)

    # Alt sol: bakır vurgu
    glow2 = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow2).ellipse((-260, H - 220, 360, H + 240), fill=(COPPER[0], COPPER[1], COPPER[2], 80))
    glow2 = glow2.filter(ImageFilter.GaussianBlur(60))
    img.alpha_composite(glow2)

    # Radar dalga çizgileri (sağ üstten geniş yaylar)
    ring_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rdraw = ImageDraw.Draw(ring_layer)
    cx, cy = W - 140, 140
    for i, r in enumerate([120, 200, 280, 360, 440]):
        alpha = 90 - i * 14
        rdraw.arc(
            (cx - r, cy - r, cx + r, cy + r),
            start=120,
            end=260,
            fill=(GOLD[0], GOLD[1], GOLD[2], alpha),
            width=3,
        )
    img.alpha_composite(ring_layer)

    # Sol: logo + marka adı + slogan
    logo_box = (60, 130, 290, 360)
    paste_logo(img, logo_box)

    draw = ImageDraw.Draw(img)
    # Marka adı
    f_brand = f(76, "bold")
    draw.text((310, 150), "FiyatRadar", font=f_brand, fill=(243, 233, 220))
    # Slogan
    f_tag = f(34, "regular")
    draw.text(
        (310, 240),
        "Akıllı fiyat karşılaştırma",
        font=f_tag,
        fill=(GOLD_HI[0], GOLD_HI[1], GOLD_HI[2]),
    )
    # Alt destek
    f_sub = f(22, "regular")
    draw.text(
        (310, 290),
        "Marketleri karşılaştır  •  Sepetini kur  •  Tasarruf et",
        font=f_sub,
        fill=(203, 184, 162),
    )

    # Premium chip
    chip_text = "PREMIUM MARKET INTELLIGENCE"
    f_chip = f(18, "bold")
    cw, ch = measure(draw, chip_text, f_chip)
    cx0, cy0 = 310, 360
    rounded_rect(
        img,
        (cx0, cy0, cx0 + cw + 36, cy0 + ch + 22),
        radius=22,
        fill=(GOLD[0], GOLD[1], GOLD[2], 40),
        outline=(GOLD[0], GOLD[1], GOLD[2], 180),
        width=2,
    )
    draw.text((cx0 + 18, cy0 + 9), chip_text, font=f_chip, fill=GOLD_HI)

    out = OUT / "feature_graphic" / "feature_graphic_1024x500.png"
    img.convert("RGB").save(out, "PNG")
    return out


# --------------------------------------------------------------------------
# 3) PHONE SCREENSHOTS 1080x1920
# --------------------------------------------------------------------------

SCREEN_W, SCREEN_H = 1080, 1920


def base_phone_canvas(title_label: str, screen_title: str, accent_subtitle: str) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (SCREEN_W, SCREEN_H), CREAM_BG + (255,))
    draw = ImageDraw.Draw(img)

    # Üst sıcak ışıltı (radar ambiance)
    glow = Image.new("RGBA", (SCREEN_W, SCREEN_H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((-220, -360, SCREEN_W + 220, 320), fill=(GOLD_HI[0], GOLD_HI[1], GOLD_HI[2], 60))
    glow = glow.filter(ImageFilter.GaussianBlur(60))
    img.alpha_composite(glow)

    # Status bar
    draw.text((60, 42), "9:41", font=f(34, "bold"), fill=INK)
    # Sağ üst pseudo signal/wifi/battery
    draw.text((SCREEN_W - 240, 42), "▮▮▮  ◎  ▮", font=f(28, "bold"), fill=INK2)

    # Section label
    draw.text((60, 120), title_label.upper(), font=f(28, "bold"), fill=INK3)
    # Page title
    draw.text((60, 156), screen_title, font=f(72, "bold"), fill=INK)
    # Accent subtitle
    if accent_subtitle:
        draw.text((60, 252), accent_subtitle, font=f(30, "regular"), fill=INK2)
    return img, draw


def bottom_nav(img: Image.Image):
    draw = ImageDraw.Draw(img)
    nav_y = SCREEN_H - 180
    # Dock
    rounded_rect(img, (60, nav_y, SCREEN_W - 60, nav_y + 120), radius=44, fill=ESPRESSO + (255,))
    items = [
        ("Anasayfa", True),
        ("Kesfet", False),
        ("Liste", False),
        ("Profil", False),
    ]
    fnt = f(22, "bold")
    step = (SCREEN_W - 120) // len(items)
    for i, (label, active) in enumerate(items):
        cx = 60 + step * i + step // 2
        # icon dot
        rcol = GOLD if active else (140, 124, 104)
        draw.ellipse((cx - 16, nav_y + 28, cx + 16, nav_y + 60), fill=rcol)
        if active:
            # halka
            draw.ellipse(
                (cx - 28, nav_y + 16, cx + 28, nav_y + 72),
                outline=GOLD + (160,),
                width=3,
            )
        col = (243, 233, 220) if active else (180, 162, 138)
        tw, _ = measure(draw, label, fnt)
        draw.text((cx - tw // 2, nav_y + 76), label, font=fnt, fill=col)


def dark_hero_card(
    img: Image.Image,
    xy: tuple[int, int, int, int],
    eyebrow: str,
    title: str,
    metric: str,
    sub: str,
):
    draw = ImageDraw.Draw(img)
    # shadow
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((xy[0], xy[1] + 14, xy[2], xy[3] + 14), radius=40, fill=(0, 0, 0, 70))
    sh = sh.filter(ImageFilter.GaussianBlur(22))
    img.alpha_composite(sh)
    # surface
    rounded_rect(img, xy, radius=40, fill=ESPRESSO + (255,))
    # gold bloom corner
    bloom = Image.new("RGBA", img.size, (0, 0, 0, 0))
    bx2 = xy[2]
    by1 = xy[1]
    ImageDraw.Draw(bloom).ellipse((bx2 - 360, by1 - 200, bx2 + 80, by1 + 240), fill=(GOLD_HI[0], GOLD_HI[1], GOLD_HI[2], 110))
    bloom = bloom.filter(ImageFilter.GaussianBlur(60))
    bloom_mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(bloom_mask).rounded_rectangle(xy, radius=40, fill=255)
    img.alpha_composite(Image.composite(bloom, Image.new("RGBA", img.size, (0, 0, 0, 0)), bloom_mask))

    # eyebrow
    draw.text((xy[0] + 36, xy[1] + 34), eyebrow.upper(), font=f(24, "bold"), fill=GOLD)
    # title
    draw.text((xy[0] + 36, xy[1] + 74), title, font=f(42, "bold"), fill=(243, 233, 220))
    # metric
    draw.text((xy[0] + 36, xy[1] + 150), metric, font=f(96, "bold"), fill=GOLD_HI)
    # sub
    draw.text((xy[0] + 36, xy[1] + 260), sub, font=f(26, "regular"), fill=(203, 184, 162))


def soft_card(
    img: Image.Image,
    xy: tuple[int, int, int, int],
    title: str,
    value: str,
    delta: str,
    delta_good: bool = True,
):
    draw = ImageDraw.Draw(img)
    rounded_rect(img, xy, radius=32, fill=CREAM_HI + (255,), outline=HAIRLINE + (255,), width=1)
    draw.text((xy[0] + 28, xy[1] + 26), title, font=f(24, "bold"), fill=INK3)
    draw.text((xy[0] + 28, xy[1] + 64), value, font=f(46, "bold"), fill=INK)
    col = GOOD if delta_good else BAD
    draw.text((xy[0] + 28, xy[1] + 130), delta, font=f(24, "bold"), fill=col)


def list_row(
    img: Image.Image,
    xy: tuple[int, int, int, int],
    rank: str,
    name: str,
    sub: str,
    right_top: str,
    right_bottom: str,
    accent: bool = False,
):
    draw = ImageDraw.Draw(img)
    rounded_rect(img, xy, radius=28, fill=CREAM_HI + (255,), outline=HAIRLINE + (255,), width=1)
    # rank chip
    chip_x = xy[0] + 24
    chip_y = xy[1] + 28
    rounded_rect(
        img,
        (chip_x, chip_y, chip_x + 64, chip_y + 64),
        radius=18,
        fill=(GOLD if accent else CREAM_LO) + (255,),
    )
    rw, rh = measure(draw, rank, f(28, "bold"))
    draw.text(
        (chip_x + (64 - rw) // 2, chip_y + (64 - rh) // 2 - 4),
        rank,
        font=f(28, "bold"),
        fill=INK if accent else INK2,
    )
    # name + sub
    draw.text((xy[0] + 110, xy[1] + 28), name, font=f(32, "bold"), fill=INK)
    draw.text((xy[0] + 110, xy[1] + 70), sub, font=f(22, "regular"), fill=INK3)
    # right block
    rtw, _ = measure(draw, right_top, f(32, "bold"))
    rbw, _ = measure(draw, right_bottom, f(22, "regular"))
    draw.text((xy[2] - 28 - rtw, xy[1] + 28), right_top, font=f(32, "bold"), fill=INK)
    draw.text((xy[2] - 28 - rbw, xy[1] + 70), right_bottom, font=f(22, "regular"), fill=GOOD)


# Screenshot 1: Home / Radar Özeti
def screen_home() -> Path:
    img, draw = base_phone_canvas("Günün nabzı", "Bugünün özeti", "16 Mayıs · İstanbul, Avrupa")
    dark_hero_card(
        img,
        (60, 330, SCREEN_W - 60, 720),
        eyebrow="Radar özeti",
        title="Sepetin bu hafta",
        metric="₺312,40",
        sub="Geçen haftaya göre ₺48,20 tasarruf  •  Migros lider",
    )
    # KPI cards
    soft_card(img, (60, 760, 530, 980), "EN UYGUN MARKET", "Migros", "↓ %12 ucuz", delta_good=True)
    soft_card(img, (550, 760, SCREEN_W - 60, 980), "TAKİP ÜRÜN", "24 ürün", "3 fırsatta", delta_good=True)
    # Leaderboard label
    draw.text((60, 1020), "EN İYİ MARKET SIRALAMASI", font=f(26, "bold"), fill=INK3)
    list_row(img, (60, 1070, SCREEN_W - 60, 1190), "1", "Migros", "Beşiktaş şubesi · 1.2 km", "₺312,40", "en uygun", accent=True)
    list_row(img, (60, 1210, SCREEN_W - 60, 1330), "2", "BİM", "Levent · 1.6 km", "₺324,90", "+₺12,50")
    list_row(img, (60, 1350, SCREEN_W - 60, 1470), "3", "ŞOK", "Ulus · 2.1 km", "₺331,10", "+₺18,70")
    list_row(img, (60, 1490, SCREEN_W - 60, 1610), "4", "A101", "Ortaköy · 2.4 km", "₺338,60", "+₺26,20")
    bottom_nav(img)
    out = OUT / "screenshots" / "01_home.png"
    img.convert("RGB").save(out, "PNG")
    return out


# Screenshot 2: Keşfet / Search
def screen_search() -> Path:
    img, draw = base_phone_canvas("Keşfet", "Ne aramıştın?", "12.400+ ürün  •  240+ market")
    # Search bar
    sb = (60, 330, SCREEN_W - 60, 440)
    rounded_rect(img, sb, radius=34, fill=CREAM_HI + (255,), outline=HAIRLINE + (255,), width=1)
    draw.ellipse((sb[0] + 30, sb[1] + 36, sb[0] + 70, sb[1] + 76), outline=INK3, width=4)
    draw.line((sb[0] + 64, sb[1] + 70, sb[0] + 88, sb[1] + 94), fill=INK3, width=4)
    draw.text((sb[0] + 110, sb[1] + 32), "Süt, ekmek, çiğ köfte...", font=f(32, "regular"), fill=INK3)
    # Filter chips
    chips = [("Tümü", True), ("Süt ürünleri", False), ("Et", False), ("Bakliyat", False), ("Atıştırmalık", False)]
    cx = 60
    cy = 470
    for label, active in chips:
        cw, ch = measure(draw, label, f(26, "bold"))
        w = cw + 50
        if active:
            rounded_rect(img, (cx, cy, cx + w, cy + 70), radius=24, fill=ESPRESSO + (255,))
            draw.text((cx + 25, cy + 18), label, font=f(26, "bold"), fill=GOLD_HI)
        else:
            rounded_rect(img, (cx, cy, cx + w, cy + 70), radius=24, fill=CREAM_HI + (255,), outline=HAIRLINE + (255,), width=1)
            draw.text((cx + 25, cy + 18), label, font=f(26, "bold"), fill=INK2)
        cx += w + 18

    # Trending header
    draw.text((60, 590), "EN ÇOK ARANANLAR", font=f(26, "bold"), fill=INK3)

    products = [
        ("UHT Süt 1 L", "Pınar", "₺32,90", "en ucuz Migros", True),
        ("Tam buğday ekmek", "Eti", "₺18,50", "en ucuz BİM", False),
        ("Zeytinyağı 1 L", "Komili", "₺189,90", "en ucuz ŞOK", False),
        ("Domates 1 kg", "Yerel hal", "₺26,75", "en ucuz A101", False),
        ("Yumurta 30'lu", "Köy", "₺142,00", "en ucuz Migros", False),
    ]
    y = 640
    for i, (name, brand, price, where, hot) in enumerate(products):
        rounded_rect(img, (60, y, SCREEN_W - 60, y + 150), radius=28, fill=CREAM_HI + (255,), outline=HAIRLINE + (255,), width=1)
        # thumbnail
        rounded_rect(img, (84, y + 22, 84 + 106, y + 128), radius=22, fill=CREAM_LO + (255,))
        draw.text((84 + 38, y + 50), str(i + 1), font=f(46, "bold"), fill=GOLD_DEEP)
        # text block
        draw.text((220, y + 28), name, font=f(32, "bold"), fill=INK)
        draw.text((220, y + 76), brand, font=f(24, "regular"), fill=INK3)
        # price
        pw, _ = measure(draw, price, f(34, "bold"))
        draw.text((SCREEN_W - 84 - pw, y + 28), price, font=f(34, "bold"), fill=INK)
        ww, _ = measure(draw, where, f(22, "regular"))
        draw.text((SCREEN_W - 84 - ww, y + 80), where, font=f(22, "regular"), fill=GOOD)
        # hot badge
        if hot:
            rounded_rect(img, (220, y + 112, 360, y + 138), radius=14, fill=GOLD + (255,))
            draw.text((232, y + 116), "TREND", font=f(18, "bold"), fill=INK)
        y += 170

    bottom_nav(img)
    out = OUT / "screenshots" / "02_search.png"
    img.convert("RGB").save(out, "PNG")
    return out


# Screenshot 3: Ürün detayı + fiyat geçmişi
def screen_product() -> Path:
    img, draw = base_phone_canvas("Ürün detayı", "UHT Süt 1 L", "Pınar  •  Tam yağlı")
    # Hero card
    rounded_rect(img, (60, 330, SCREEN_W - 60, 700), radius=40, fill=CREAM_HI + (255,), outline=HAIRLINE + (255,), width=1)
    # product mock
    rounded_rect(img, (110, 380, 410, 660), radius=32, fill=CREAM_LO + (255,))
    draw.text((158, 470), "1L", font=f(120, "bold"), fill=GOLD_DEEP)
    # right info
    draw.text((460, 380), "EN UYGUN", font=f(24, "bold"), fill=GOLD_DEEP)
    draw.text((460, 416), "₺32,90", font=f(86, "bold"), fill=INK)
    draw.text((460, 530), "Migros · Beşiktaş", font=f(28, "regular"), fill=INK2)
    rounded_rect(img, (460, 580, 700, 640), radius=22, fill=GOOD_SOFT + (255,))
    draw.text((478, 596), "↓ %18 ucuz", font=f(26, "bold"), fill=GOOD)

    # Price history label
    draw.text((60, 740), "30 GÜNLÜK FİYAT GEÇMİŞİ", font=f(26, "bold"), fill=INK3)

    # Chart area
    cx0, cy0, cx1, cy1 = 60, 790, SCREEN_W - 60, 1160
    rounded_rect(img, (cx0, cy0, cx1, cy1), radius=32, fill=CREAM_HI + (255,), outline=HAIRLINE + (255,), width=1)
    # axis baseline
    draw.line((cx0 + 60, cy1 - 40, cx1 - 40, cy1 - 40), fill=INK4, width=1)
    # data points
    series = [38.5, 37.9, 39.1, 38.0, 36.4, 35.9, 36.8, 35.2, 34.7, 34.1, 33.6, 33.9, 33.2, 32.9]
    smin, smax = min(series), max(series)
    pts = []
    plot_w = (cx1 - 40) - (cx0 + 60)
    plot_h = (cy1 - 60) - (cy0 + 40)
    for i, v in enumerate(series):
        x = cx0 + 60 + int(plot_w * i / (len(series) - 1))
        y = cy0 + 40 + int(plot_h * (1 - (v - smin) / (smax - smin)))
        pts.append((x, y))
    # filled gradient under line
    poly = pts + [(pts[-1][0], cy1 - 40), (pts[0][0], cy1 - 40)]
    fill_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(fill_layer).polygon(poly, fill=(GOLD[0], GOLD[1], GOLD[2], 70))
    fill_layer = fill_layer.filter(ImageFilter.GaussianBlur(1))
    img.alpha_composite(fill_layer)
    # line
    for i in range(len(pts) - 1):
        draw.line((pts[i], pts[i + 1]), fill=GOLD_DEEP, width=5)
    # points
    for x, y in pts:
        draw.ellipse((x - 6, y - 6, x + 6, y + 6), fill=ESPRESSO, outline=GOLD)
    # highlight last
    lx, ly = pts[-1]
    draw.ellipse((lx - 11, ly - 11, lx + 11, ly + 11), fill=GOLD, outline=ESPRESSO, width=2)
    draw.text((lx - 70, ly - 60), "₺32,90", font=f(26, "bold"), fill=INK)

    # Market comparison row
    draw.text((60, 1200), "MARKETLERDE FİYAT", font=f(26, "bold"), fill=INK3)
    list_row(img, (60, 1250, SCREEN_W - 60, 1370), "M", "Migros", "1.2 km · stokta", "₺32,90", "en ucuz", accent=True)
    list_row(img, (60, 1390, SCREEN_W - 60, 1510), "B", "BİM", "1.6 km · stokta", "₺34,50", "+₺1,60")
    list_row(img, (60, 1530, SCREEN_W - 60, 1650), "Ş", "ŞOK", "2.1 km · sınırlı", "₺35,20", "+₺2,30")

    bottom_nav(img)
    out = OUT / "screenshots" / "03_product_detail.png"
    img.convert("RGB").save(out, "PNG")
    return out


# Screenshot 4: Karşılaştırma / Sepet
def screen_compare() -> Path:
    img, draw = base_phone_canvas("Sepet karşılaştırma", "Hangi market avantajlı?", "12 ürün · 4 market karşılaştırıldı")

    # Hero compare card
    dark_hero_card(
        img,
        (60, 330, SCREEN_W - 60, 720),
        eyebrow="Sepet avantajı",
        title="Migros'ta toplam",
        metric="₺312,40",
        sub="Diğer marketlere göre ortalama ₺26,80 tasarruf",
    )

    draw.text((60, 760), "MARKET KARŞILAŞTIRMASI", font=f(26, "bold"), fill=INK3)

    rows = [
        ("Migros", "12/12 ürün stokta", "₺312,40", GOLD, True),
        ("BİM", "11/12 ürün stokta", "₺324,90", CREAM_LO, False),
        ("ŞOK", "12/12 ürün stokta", "₺331,10", CREAM_LO, False),
        ("A101", "10/12 ürün stokta", "₺338,60", CREAM_LO, False),
    ]
    y = 810
    max_price = 340
    for name, sub, price, swatch, accent in rows:
        rounded_rect(img, (60, y, SCREEN_W - 60, y + 200), radius=32, fill=CREAM_HI + (255,), outline=HAIRLINE + (255,), width=1)
        # swatch dot
        rounded_rect(img, (96, y + 30, 168, y + 102), radius=24, fill=swatch + (255,))
        draw.text((110, y + 46), name[0], font=f(40, "bold"), fill=INK)
        draw.text((200, y + 30), name, font=f(38, "bold"), fill=INK)
        draw.text((200, y + 80), sub, font=f(24, "regular"), fill=INK3)
        pw, _ = measure(draw, price, f(40, "bold"))
        draw.text((SCREEN_W - 90 - pw, y + 36), price, font=f(40, "bold"), fill=INK)
        if accent:
            rounded_rect(img, (SCREEN_W - 270, y + 88, SCREEN_W - 90, y + 124), radius=18, fill=GOOD_SOFT + (255,))
            draw.text((SCREEN_W - 254, y + 92), "EN UYGUN", font=f(22, "bold"), fill=GOOD)
        # mini bar
        ratio = float(price.replace("₺", "").replace(",", ".")) / max_price
        bar_x0 = 200
        bar_x1 = SCREEN_W - 90
        bw = bar_x1 - bar_x0
        rounded_rect(img, (bar_x0, y + 138, bar_x1, y + 168), radius=14, fill=CREAM_LO + (255,))
        rounded_rect(
            img,
            (bar_x0, y + 138, bar_x0 + int(bw * ratio), y + 168),
            radius=14,
            fill=(GOLD if accent else GOLD_DEEP) + (255,),
        )
        y += 220

    bottom_nav(img)
    out = OUT / "screenshots" / "04_compare.png"
    img.convert("RGB").save(out, "PNG")
    return out


# Screenshot 5: Watchlist / Alarm
def screen_watchlist() -> Path:
    img, draw = base_phone_canvas("Takip listem", "Fiyat alarmların", "3 ürün indirimde  •  24 ürün takipte")

    # Hero
    dark_hero_card(
        img,
        (60, 330, SCREEN_W - 60, 720),
        eyebrow="Bu hafta tetiklenen",
        title="3 fırsat alarmı",
        metric="₺184",
        sub="Hedef fiyatın altına düşen ürünler için toplam tasarruf",
    )

    draw.text((60, 760), "AKTİF TAKİP", font=f(26, "bold"), fill=INK3)

    items = [
        ("Zeytinyağı 1 L", "Komili", "₺164,90", "Hedef ₺175", "↓ ₺25", True, True),
        ("Domates 1 kg", "Yerel hal", "₺22,40", "Hedef ₺28", "↓ ₺4,30", True, True),
        ("Yumurta 30'lu", "Köy", "₺142,00", "Hedef ₺140", "+₺2", False, False),
        ("Pirinç 5 kg", "Reis", "₺289,90", "Hedef ₺275", "+₺14,90", False, False),
        ("Kahve 250 g", "Kurukahveci", "₺214,50", "Hedef ₺200", "+₺14,50", False, False),
    ]
    y = 810
    for name, brand, price, target, delta, good, alert in items:
        rounded_rect(img, (60, y, SCREEN_W - 60, y + 180), radius=28, fill=CREAM_HI + (255,), outline=HAIRLINE + (255,), width=1)
        # bell or pin
        rounded_rect(img, (96, y + 36, 178, y + 118), radius=22, fill=(GOLD if alert else CREAM_LO) + (255,))
        sym = "!" if alert else "•"
        sw, sh_ = measure(draw, sym, f(40, "bold"))
        draw.text((96 + (82 - sw) // 2, y + 36 + (82 - sh_) // 2 - 4), sym, font=f(40, "bold"), fill=INK if alert else INK3)
        # text
        draw.text((210, y + 34), name, font=f(32, "bold"), fill=INK)
        draw.text((210, y + 78), brand + "  •  " + target, font=f(24, "regular"), fill=INK3)
        # right
        pw, _ = measure(draw, price, f(36, "bold"))
        draw.text((SCREEN_W - 90 - pw, y + 32), price, font=f(36, "bold"), fill=INK)
        dw, _ = measure(draw, delta, f(26, "bold"))
        draw.text((SCREEN_W - 90 - dw, y + 80), delta, font=f(26, "bold"), fill=GOOD if good else BAD)
        # mini progress bar
        rounded_rect(img, (210, y + 128, SCREEN_W - 90, y + 152), radius=12, fill=CREAM_LO + (255,))
        ratio = 0.85 if good else 0.45
        rounded_rect(img, (210, y + 128, 210 + int((SCREEN_W - 300) * ratio), y + 152), radius=12, fill=(GOLD if good else GOLD_DEEP) + (255,))
        y += 200

    bottom_nav(img)
    out = OUT / "screenshots" / "05_watchlist.png"
    img.convert("RGB").save(out, "PNG")
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "icon").mkdir(exist_ok=True)
    (OUT / "feature_graphic").mkdir(exist_ok=True)
    (OUT / "screenshots").mkdir(exist_ok=True)

    results = [
        build_app_icon(),
        build_feature_graphic(),
        screen_home(),
        screen_search(),
        screen_product(),
        screen_compare(),
        screen_watchlist(),
    ]
    for p in results:
        size = os.path.getsize(p) / 1024
        print(f"OK  {p.relative_to(ROOT)}  ({size:.1f} KB)")


if __name__ == "__main__":
    main()
