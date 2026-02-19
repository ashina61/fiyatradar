## Summary
- 

## Validation
- [ ] Tests/checks run and noted below
- [ ] Manual QA completed

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
