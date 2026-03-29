## Summary
- 

## Validation
- [ ] Tests/checks run and noted below
- [ ] Manual QA completed

## Engineering Merge Gate (Required)

### Ruleset Compliance
- [ ] Scope dışı dosya değişmedi.
- [ ] `build()` içinde side-effect eklenmedi.
- [ ] Full collection fetch veya full snapshot + client-side sort/filter eklenmedi.
- [ ] Yeni query eklendiyse `orderBy/limit/count/index` notu aşağıdaki alana yazıldı.
- [ ] Firestore path değiştiyse rules path drift kontrolü yapıldı ve sonucu aşağıdaki alana yazıldı.
- [ ] GoRouter dışı navigation eklenmedi.

### Design Token Compliance
- [ ] Yeni kodda local `Color(0x...)` yok.
- [ ] Yeni kodda local `BorderRadius.circular(...)` yok.
- [ ] Yeni kodda raw `EdgeInsets.all/symmetric/only/fromLTRB(...)` yok.
- [ ] Token dışı local spacing/radius/color eklenmedi.

### Legacy Exception Policy
- [ ] LEGACY_EXCEPTION kullanılmadı.
- [ ] Eğer kullanıldıysa satırda `reason/owner/remove_by` metadata formatı eklendi.
- [ ] Eğer kullanıldıysa `docs/legacy-exception-allowlist.md` güncellendi.

## Query Notes (Required if new query added)
- Query path:
- orderBy:
- limit:
- count() impact:
- index requirement:

## Firestore Rules Path Drift Check (Required if path changed)
- Changed path:
- Related rules file/path:
- Drift result:
- Follow-up action:

## Legacy Exception Entries (Fill only if used)
| file | reason | owner | remove_by | tracking_issue |
|---|---|---|---|---|
| _none_ | - | - | - | - |

## UI PR Checklist (Required for UI Changes)
Reference: `docs/ui_pr_checklist.md`

### Design Token Uyum Kontrolü
- [ ] Renkler yalnızca `Theme.of(context).colorScheme` tokenları üzerinden kullanıldı.
- [ ] Yeni/yenilenen widget'larda hardcoded veya `AppColors` tabanlı renk kullanılmadı.
- [ ] Radius değerleri design token standardına uyuyor (`22 / 26 / 28+`).
- [ ] Spacing 8pt grid düzenine uyuyor (`8 / 16 / 24 / 32`).

### Motion & Interaction
- [ ] Motion tokenları kullanıldı (`fast/base/cinematic`, `easeOutCubic` vb.).
- [ ] Press feedback standardı uygulandı (`scale: 0.97`, opacity düşüşü).
- [ ] Haptic standardı uygulandı (`selectionClick`, kritik CTA için gerekli ise `mediumImpact`).
- [ ] Liste animasyonları varsa stagger standardı korundu (`delay ~= index * 35-45ms`, fade + translateY).

### Blur & Visual Quality
- [ ] Blur yalnızca izinli alanlarda kullanıldı (hero veya bottom bar/nav).
- [ ] Blur sigma değeri maksimum 18 sınırını geçmiyor.
- [ ] Neon / agresif glow / aşırı gradient kullanılmadı.

### Süreç Kapısı (Gate)
- [ ] En az bir manuel UI review yapıldı ve notu PR'a eklendi.

## Testing Commands
- [ ] `flutter test`
- [ ] `bash scripts/check_engineering_rules.sh`
