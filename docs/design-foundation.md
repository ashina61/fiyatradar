# Design Foundation (Canonical)

Bu doküman FiyatRadar için **tek resmi design foundation** kaynağını tanımlar.

## Canonical token sources

- `lib/theme/fr_colors.dart` → renk tokenları (canonical)
- `lib/theme/fr_spacing.dart` → spacing tokenları
- `lib/theme/fr_radius.dart` → radius tokenları
- `lib/theme/fr_typography.dart` → typography tokenları
- `lib/theme/fr_elevation.dart` → shadow/elevation tokenları
- `lib/theme/fr_foundation.dart` → tek import yüzeyi

## Deprecated sources (legacy compatibility)

- `lib/utils/theme.dart::AppColors` (**deprecated**)
- `lib/utils/theme.dart::AppTheme` (**deprecated**)

> Not: Legacy kaynaklar mevcut ekranları kırmamak için korunur.
> Yeni kod bu kaynaklara yeni token ekleyemez.

## Usage rules

1. Yeni feature ekranı `lib/theme/fr_foundation.dart` import eder.
2. Yeni local `Color(0x...)` sabiti eklenmez.
3. Yeni local spacing/radius magic number eklenmez.
4. Yeni typography helper (`_textStyle`, `_jakarta`, vb.) yerine foundation typography tokenları kullanılır.

## Migration intent

Bu task migration değildir. Amaç yalnızca canonical foundation zemini kurmaktır.
