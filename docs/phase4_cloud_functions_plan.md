# Faz 4 - Cloud Functions Geçiş Planı

Bu plan, client tarafında kalan kritik iş mantığını güvenli server-side fonksiyonlara taşımak içindir.

## 1. points.applyEvent
- **Amaç:** Kullanıcı puan artırma/azaltma işlemlerini sunucu tarafına taşımak.
- **Yetki:** Auth zorunlu, yalnız kendi userId için; admin override ayrı claim.
- **Input:** `{ userId, eventType, delta, metadata }`
- **Kontroller:** rate-limit, delta sınırı, idempotency key.

## 2. admin.setBanStatus
- **Amaç:** Ban/unban işlemini sadece admin tarafında yönetmek.
- **Yetki:** Custom claim `admin=true`.
- **Input:** `{ targetUid, isBanned, reason }`
- **Kontroller:** actor log, reason zorunluluğu (ban için), self-ban engeli.

## 3. admin.updateRoles
- **Amaç:** isAdmin/role gibi alanları yalnız fonksiyon üzerinden güncellemek.
- **Yetki:** Super-admin claim.
- **Input:** `{ targetUid, role }`
- **Kontroller:** rol whitelist, denetim kaydı.

## 4. moderation.resolveReport
- **Amaç:** Rapor çözümleme ve içerik durum güncellemesi.
- **Yetki:** Admin/moderator claim.
- **Input:** `{ reportId, action, note }`
- **Kontroller:** action whitelist, immutable audit trail.

## Operasyonel Notlar
- Functions + Firestore rules birlikte çalışmalı; rules kritik alanlara client write izni vermemeli.
- Tüm fonksiyon çağrıları için audit kayıtları `adminActions` altında tutulmalı.
- CI aşamasında functions lint+test pipeline'ı zorunlu olmalı.


Detaylı backlog/şema/geçiş planı için: `docs/cloud_functions_backlog.md`.
