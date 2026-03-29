# Design Foundation (Canonical)

Bu doküman FiyatRadar için **tek resmi design foundation** kaynağını tanımlar.

> Not: Store domain kararları design foundation kapsamında değil, `docs/store-policy.md` altında canonical olarak yönetilir.

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

## Enforcement

1. PR checklist design-token kurallarını merge gate olarak zorunlu kılar.
2. CI tarafında `scripts/check_engineering_rules.sh` yeni eklenen `.dart` satırlarında şu pattern’leri bloke eder:
   - `Color(0x...)`
   - `BorderRadius.circular(...)`
   - `EdgeInsets.all/symmetric/only/fromLTRB(...)`
3. Legacy istisna gerekiyorsa satırda `LEGACY_EXCEPTION: reason=...; owner=...; remove_by=YYYY-MM-DD` formatı zorunludur.
4. Path bazlı geçici istisnalar `docs/legacy-exception-allowlist.md` içinde takip edilir.

## Migration intent

Bu task migration değildir. Amaç canonical foundation zeminini **enforce edilebilir** hale getirmektir.
