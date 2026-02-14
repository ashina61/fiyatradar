
🚀 FiyatRadar ULTRA DESIGN SYSTEM v1

🎯 Temel Kimlik
Stil:
💎 Fintech Premium
⚡ Subtle Cinematic
🧠 Güven hissi
Olmaması gerekenler:
❌ Neon glow
❌ Oyun tarzı animasyon
❌ Aşırı gradient
🎨 Renk Kullanımı (Color Rules)
Hardcode renk YOK.
Sadece:
Theme.of(context).colorScheme
Kullanılacak tonlar:
surface → kart arka planı
surfaceVariant → alt katman
primaryContainer → hero alanları
secondaryContainer → info banner
outlineVariant → divider/border

🧱 Layout Sistemi
Radius
Kartlar: 22
Hero: 26
Bottom Bar: 28+
Spacing
8pt grid
8 / 16 / 24 / 32

Elevation
Soft shadow
Yüksek drop shadow YOK

🧊 Kart Davranışı
Her kart:
glass hissi (opacity surface)
pressed state:
scale 1 → 0.97
tap haptic:
selectionClick

🎬 Animasyon Standardı
Duration:
250–350ms
Curve:
Curves.easeOutCubic
Spring sadece:
expand
trust progress

🧠 Cinematic Kurallar
Hero alanları:
scroll scale:
1 → 0.94
Avatar:
translateY = scrollOffset * 0.1
Aura:
primary opacity varyasyonu
Blur:
👉 sadece hero alanında
👉 full screen blur YOK

🧾 Liste & Tile Kuralları
Premium tile:
leading icon
title
subtitle
chevron
Divider:
outlineVariant opacity düşük

🧭 Navigation Kuralları
Bottom nav:
icon scale 1.1 aktifken
label fade
sliding indicator
Haptic:
selectionClick

⭐ Trust System Görsel Kuralları
Trust > 70:
subtle pulse
glow opacity düşük
Trust düşüşü:
kırmızı alarm YOK
sadece info banner

🧩 Bileşen Standardı
Her ekran şu bileşenlerle bölünecek:
HeroCard
GlassCard
SectionTitle
QuickActionTile
PremiumListTile
ProgressCard

⚡ Performans Kuralları
const widget maksimum
BackdropFilter sadece gerekli yerde
RepaintBoundary aura alanında
rebuild minimum (Selector)
💀 En Önemli Kural (Design DNA)
FiyatRadar:
👉 Banka gibi güvenilir
👉 Oyun gibi bağımlılık yapmayan
👉 Ama premium hissi olan


🚀 FiyatRadar ULTRA DESIGN SYSTEM v2 — CINEMATIC ENGINE
0) Amaç
Uygulamadaki tüm ekranlarda “premium hissi” aynı kurallarla gelsin.
Her ekran kendi kafasına göre animasyon/blur yapmasın.

1) Global Animation Tokens
Tek yerden kullanılan standartlar:
Fast: 160–200ms (buton press, küçük geçiş)
Base: 240–320ms (kart girişleri, list tile)
Cinematic: 350–520ms (hero giriş, parallax, stage reveal)
Curves:
Default: Curves.easeOutCubic
Expand/Accordion: spring-benzeri ama abartısız (örn Curves.easeOutBack değil; custom/lerp ile yumuşak)
Haptic:
tap: selectionClick
primary CTA: mediumImpact

2) Cinematic Scroll Engine (Ortak davranış)
Her “hero’lu” ekranda aynı davranış:
Hero scale: 1.00 → 0.94
Hero translateY: scrollOffset * 0.12
Avatar parallax: scrollOffset * 0.10
Bunlar için ortak yardımcı:
CinematicScrollController (helper class)
veya basit ScrollController listener + ValueNotifier<double> scrollT
scrollT normalize:
scrollT = clamp(scrollOffset / 160, 0, 1)

3) Global Glow & Aura Rules
Glow “legend mode” gibi sadece belli yerlerde:
Aura opacity = level’e göre (v1 kuralı)
Dark mode:
aura *0.7
glow blur biraz düşer
Glow asla neon değil.
primary/onSurface opacity ile, çok düşük.

4) Glass & Blur Engine
Blur sadece 2 yerde serbest:
Bottom summary bar / bottom nav pill
Hero card background (çok düşük blur)
Kurallar:
Blur max 18 sigma
Blur sadece küçük container alanında
RepaintBoundary kullan

5) Staggered Reveal Engine
Listeler tek tek “premium” gelsin:
Kart/Liste itemları:
delay = index * 35–45ms
animasyon: fade + translateY (4–8px)
Bunu ortak helper ile yap:
StaggeredFadeSlide widget

6) Press Feedback Standard
Bütün tıklanabilir kartlar:
Press: AnimatedScale(0.97)
Opacity: 1 → 0.94 (çok hafif)
Süre: 160ms

7) Navigation Motion Rules
Tab değişimlerinde:
Indicator sliding: 240–320ms easeOutCubic
Active icon scale: 1.10
Label fade: 160–200ms

8) “Design System Compliance”
Her yeni ekran/feature yapılınca şunlar kontrol edilecek:
Hardcode renk yok
spacing 8pt grid
radius tokenlar (22/26/28)
animation tokenlar
blur kuralları
list reveal standardı
