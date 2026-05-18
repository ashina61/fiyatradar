"""FiyatRadar Play Console screenshot kompozisyonu — gerçek ekran üzerinden.

Her görsel:
  • 1080x1920 portrait
  • Üst: krem zemin + serif başlık + alt açıklama
  • Alt: gerçek ekran görüntüsü (rounded corner ile mockup framing)

Çıktı: play_store_assets/screenshots_real/0X_*.png
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
UPLOADS = Path("/root/.claude/uploads/af75011a-4d37-4df7-b0e9-7c736754890f")
OUT = ROOT / "play_store_assets" / "screenshots_real"
OUT.mkdir(parents=True, exist_ok=True)

W, H = 1080, 1920

# Gerçek ekrandan örnekleme yapılmış palet
CREAM_BG = (245, 239, 227)      # genel zemin
CREAM_BG_HI = (252, 247, 236)   # üst gradient
INK = (60, 42, 30)              # serif başlık koyu kahve
INK2 = (110, 86, 64)            # secondary
INK3 = (155, 132, 104)          # eyebrow
GOLD = (168, 117, 58)           # marka altın
COPPER = (148, 109, 63)         # CTA bakır
ESPRESSO = (50, 32, 20)

FONTS = {
    "serif_bold": "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf",
    "serif_italic": "/usr/share/fonts/truetype/liberation/LiberationSerif-BoldItalic.ttf",
    "sans": "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "sans_bold": "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
}


def f(size: int, key: str = "sans") -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONTS[key], size)


def measure(draw: ImageDraw.ImageDraw, text: str, font) -> tuple[int, int]:
    l, t, r, b = draw.textbbox((0, 0), text, font=font)
    return r - l, b - t


def wrap_lines(draw, text: str, font, max_w: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    cur = ""
    for w in words:
        trial = (cur + " " + w).strip()
        tw, _ = measure(draw, trial, font)
        if tw <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def crop_screenshot(path: Path, mask_test_ad: bool = False) -> Image.Image:
    """Görüntüyü olduğu gibi döner. mask_test_ad=True ise (1200x2670 Sepet)
    test reklam şeridini krem zeminle örter ve yerine 'Reklamsız Pro'
    rozeti yerleştirir."""
    im = Image.open(path).convert("RGB")
    if not mask_test_ad:
        return im

    # Test ad y aralığı: ~1988-2132 (1200x2670 sepet görseli için).
    y0, y1 = 1976, 2138
    draw = ImageDraw.Draw(im)
    # Sayfanın orijinal krem rengiyle aynı
    draw.rectangle((0, y0, im.width, y1), fill=(244, 238, 226))

    # Rozet — orta çizgi
    cy = (y0 + y1) // 2
    chip_h = 96
    chip_w = 640
    cx = im.width // 2
    bx0 = cx - chip_w // 2
    by0 = cy - chip_h // 2
    bx1 = cx + chip_w // 2
    by1 = cy + chip_h // 2
    draw.rounded_rectangle((bx0, by0, bx1, by1), radius=46, fill=(232, 220, 196), outline=(168, 117, 58), width=2)
    label = "✦  Reklamsız deneyim · Pro"
    fnt = ImageFont.truetype(FONTS["sans_bold"], 38)
    tw = draw.textbbox((0, 0), label, font=fnt)
    tw_w = tw[2] - tw[0]
    tw_h = tw[3] - tw[1]
    draw.text((cx - tw_w // 2, cy - tw_h // 2 - 4), label, font=fnt, fill=(94, 60, 26))
    return im


def soft_shadow(base: Image.Image, xy, radius: int, blur: int, opacity: int):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(xy, radius=radius, fill=(0, 0, 0, opacity))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(layer)


def compose(
    out_name: str,
    src_image: Path,
    eyebrow: str,
    title_a: str,
    title_b_italic: str,
    subtitle: str,
    mask_test_ad: bool = False,
):
    canvas = Image.new("RGBA", (W, H), CREAM_BG + (255,))

    # Üst krem ışıltı
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((-260, -420, W + 260, 340), fill=CREAM_BG_HI + (255,))
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    canvas.alpha_composite(glow)

    # Hafif sağ üst altın aura
    aura = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(aura).ellipse((W - 540, -300, W + 240, 380), fill=(GOLD[0], GOLD[1], GOLD[2], 50))
    aura = aura.filter(ImageFilter.GaussianBlur(80))
    canvas.alpha_composite(aura)

    draw = ImageDraw.Draw(canvas)

    # Eyebrow
    eb_font = f(28, "sans_bold")
    ew, _ = measure(draw, eyebrow, eb_font)
    draw.text((80, 96), eyebrow, font=eb_font, fill=INK3)

    # Başlık (serif + italic kombinasyonu)
    title_font = f(82, "serif_bold")
    italic_font = ImageFont.truetype(FONTS["serif_italic"], 82)

    # title_a + " " + italic kısmı tek satırda mı diye kontrol
    line1 = title_a
    line2 = title_b_italic

    draw.text((80, 150), line1, font=title_font, fill=INK)
    line1_w, line1_h = measure(draw, line1, title_font)

    # ikinci satır italic, hemen altına
    draw.text((80, 150 + 96), line2, font=italic_font, fill=COPPER)

    # Subtitle (sans, gri-kahve, sarı altı çizgi yok)
    sub_font = f(34, "sans")
    sub_lines = wrap_lines(draw, subtitle, sub_font, max_w=W - 160)
    y = 150 + 96 + 110
    for line in sub_lines:
        draw.text((80, y), line, font=sub_font, fill=INK2)
        y += 46

    # ---- Telefon mockup framing ----
    shot = crop_screenshot(src_image, mask_test_ad=mask_test_ad)
    sw, sh = shot.size

    # Hedef genişlik = 880, en-boy oranı korunarak
    target_w = 880
    target_h = int(sh * target_w / sw)
    shot_resized = shot.resize((target_w, target_h), Image.LANCZOS)

    # Köşeleri yuvarla
    radius = 64
    mask = Image.new("L", (target_w, target_h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, target_w, target_h), radius=radius, fill=255)
    shot_rgba = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    shot_rgba.paste(shot_resized, (0, 0), mask)

    # Alt safe-area: ekran sığabilecek max yükseklik
    available_y_top = max(540, y + 30)
    avail_h = H - available_y_top - 80
    if target_h > avail_h:
        # Yükseklik fazlaysa orantılı küçült
        scale = avail_h / target_h
        target_w = int(target_w * scale)
        target_h = int(target_h * scale)
        shot_resized = shot.resize((target_w, target_h), Image.LANCZOS)
        mask = Image.new("L", (target_w, target_h), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, target_w, target_h), radius=int(radius * scale), fill=255)
        shot_rgba = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
        shot_rgba.paste(shot_resized, (0, 0), mask)
        radius = int(radius * scale)

    px = (W - target_w) // 2
    py = H - target_h - 60

    # Gölge
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (px - 6, py + 24, px + target_w + 6, py + target_h + 36),
        radius=radius + 6,
        fill=(50, 32, 20, 95),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.alpha_composite(shadow)

    # Bezel (ince altın çerçeve)
    bezel = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(bezel).rounded_rectangle(
        (px - 4, py - 4, px + target_w + 4, py + target_h + 4),
        radius=radius + 4,
        outline=(GOLD[0], GOLD[1], GOLD[2], 110),
        width=3,
    )
    canvas.alpha_composite(bezel)

    canvas.alpha_composite(shot_rgba, (px, py))

    out = OUT / out_name
    canvas.convert("RGB").save(out, "PNG", quality=95)
    print(f"OK  {out.relative_to(ROOT)}")


SCREENS = [
    # 1) Anasayfa — radar aktif
    {
        "out": "01_anasayfa.png",
        "src": "2fd8d2dc-1000110772.jpg",
        "eyebrow": "ANASAYFA  ·  RADAR",
        "title_a": "Topluluğun",
        "title_b": "gerçek fiyatları",
        "sub": "Bölgendeki kullanıcılar fiyatları paylaşıyor, radar her saniye güncelleniyor.",
    },
    # 2) Topluluk akışı
    {
        "out": "02_topluluk_akisi.png",
        "src": "f56d6a82-1000110773.jpg",
        "eyebrow": "TOPLULUK AKIŞI",
        "title_a": "Anlık",
        "title_b": "fiyat paylaşımları",
        "sub": "Online marketlerden ve marketlerden taze fiyatları canlı izle.",
    },
    # 3) Keşfet
    {
        "out": "03_kesfet.png",
        "src": "1cd0cd36-1000110774.jpg",
        "eyebrow": "KEŞFET",
        "title_a": "Binlerce ürün,",
        "title_b": "anında bul",
        "sub": "Kategoriye, markaya, mağazaya göre ara; favorilerini takip et.",
    },
    # 4) Fiyat ekle adım 1
    {
        "out": "04_fiyat_ekle.png",
        "src": "58a3bf3d-1000110779.jpg",
        "eyebrow": "FİYAT EKLE",
        "title_a": "Fiyat gördün mü?",
        "title_b": "20 saniyede ekle",
        "sub": "Üç adımda paylaş, topluluğa katkıda bulun, puan kazan.",
    },
    # 5) Fiyat ekle adım 2 — market seç
    {
        "out": "05_market_sec.png",
        "src": "98ab763d-1000110780.jpg",
        "eyebrow": "MAĞAZA  ·  KONUM",
        "title_a": "Marketi seç,",
        "title_b": "konumunla doğrula",
        "sub": "Market, online veya pazar; ilçe seviyesinde tutarız, mahallene karışmaz.",
    },
    # 6) Sepetim
    {
        "out": "06_sepet.png",
        "src": "1f18eb3f-1000110775.jpg",
        "eyebrow": "SEPET",
        "title_a": "Sepetini planla,",
        "title_b": "tasarrufunu gör",
        "sub": "Eklediğin ürünlerin bölgesel tahminini ve toplam tasarrufunu anında hesapla.",
        "mask_test_ad": True,
    },
    # 7) Sepet karşılaştırma — en iyi seçenek
    {
        "out": "07_en_iyi_market.png",
        "src": "74ac5dd8-1000110776.jpg",
        "eyebrow": "EN İYİ SEÇENEK",
        "title_a": "Hangi market",
        "title_b": "daha avantajlı?",
        "sub": "Kapsama, güven ve toplam tutara göre senin için en uygun marketi öner.",
    },
    # 8) Profil — seviye, topluluk güveni
    {
        "out": "08_profil.png",
        "src": "3e5fe8c0-1000110778.jpg",
        "eyebrow": "PROFİL  ·  TOPLULUK",
        "title_a": "Katkı yap,",
        "title_b": "seviye atla",
        "sub": "Elit Radar'a yüksel, bölgesel sıralamana bak, FiyatRadar Pro'yu keşfet.",
    },
]


def main() -> None:
    for s in SCREENS:
        compose(
            s["out"],
            UPLOADS / s["src"],
            s["eyebrow"],
            s["title_a"],
            s["title_b"],
            s["sub"],
            mask_test_ad=s.get("mask_test_ad", False),
        )


if __name__ == "__main__":
    main()
