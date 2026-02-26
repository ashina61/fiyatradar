# Cloud Functions Backlog (Kritik İş Mantığı Taşıma)

Bu doküman `CODE_REVIEW_AUDIT.md` Faz 4 ve `docs/phase1_security_test_queue.md` içindeki aşağıdaki açık maddeleri tamamlamak için hazırlanmıştır:
- Cloud Functions backlog oluşturma
- Her işlem için input şeması + yetki matrisi
- Geçişte geriye uyumluluk planı

## 1) Fonksiyon Backlog'u

| Fonksiyon | Öncelik | Amaç |
|---|---:|---|
| `points.applyEvent` | P0 | Puan kazanım/kayıp olaylarını server-side doğrulamak |
| `admin.setBanStatus` | P0 | Ban/unban işlemlerini sadece yetkili akıştan geçirmek |
| `admin.updateRoles` | P0 | `isAdmin/role` değişikliklerini merkezi yetki denetimiyle yapmak |
| `moderation.resolveReport` | P1 | Rapor çözümleme ve içerik aksiyonlarını audit trail ile yürütmek |
| `price.verify` | P1 | Fiyat doğrulama/itiraz akışını client'tan server-side'a taşımak |

---

## 2) Input Şeması ve Yetki Matrisi

## `points.applyEvent`
**Input şeması**
```json
{
  "idempotencyKey": "string",
  "userId": "string",
  "eventType": "PRICE_ADD|PRICE_VERIFY|INVITE|PENALTY",
  "delta": 5,
  "metadata": { "source": "mobile", "refId": "optional" }
}
```
**Yetki**
- Auth zorunlu
- `userId == auth.uid` (normal kullanıcı)
- Admin için override yalnız claim ile

**Doğrulamalar**
- `delta` aralığı: `[-100, 100]`
- `idempotencyKey` tekil olmalı
- Dakikalık rate-limit

## `admin.setBanStatus`
**Input şeması**
```json
{
  "targetUid": "string",
  "isBanned": true,
  "reason": "string"
}
```
**Yetki**
- `admin=true` claim zorunlu

**Doğrulamalar**
- `targetUid != auth.uid` (self-ban engeli)
- `isBanned=true` ise `reason` zorunlu
- `reason` uzunluk sınırı (5-500)

## `admin.updateRoles`
**Input şeması**
```json
{
  "targetUid": "string",
  "role": "user|moderator|admin"
}
```
**Yetki**
- `super_admin=true` claim zorunlu

**Doğrulamalar**
- `role` whitelist
- kritik rol değişiminde 2 adımlı onay (opsiyonel, roadmap)

## `moderation.resolveReport`
**Input şeması**
```json
{
  "reportId": "string",
  "action": "dismiss|hide|ban_user|warn_user",
  "note": "string"
}
```
**Yetki**
- `admin=true` veya `moderator=true`

**Doğrulamalar**
- `action` whitelist
- immutable audit trail kaydı

---

## 3) Geriye Uyumluluk Geçiş Planı

1. **Dual-write geçişi (1-2 sprint)**
   - Mevcut client write akışı korunur
   - Functions çağrısı paralel loglanır

2. **Soft-enforce (1 sprint)**
   - Kritik alanlarda rules kademeli sıkılaştırılır
   - Eski client sürümleri için geçici fallback izlenir

3. **Hard cutover**
   - Client tarafı doğrudan kritik write yetkileri kapatılır
   - Sadece Functions yolu açık kalır

4. **Temizlik**
   - Eski client-side business logic kaldırılır
   - Dokümantasyon ve runbook güncellenir

---

## 4) Kabul Kriterleri
- Her fonksiyon için input şeması ve authz matrisi dokümante edilmiş olmalı.
- Kritk write alanlarında doğrudan client erişimi rules ile kapalı olmalı.
- Fonksiyon çağrıları için `adminActions` / audit kaydı üretimi zorunlu olmalı.
- Geriye uyumluluk geçiş adımları release planına bağlanmalı.
