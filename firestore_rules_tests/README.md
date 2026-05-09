# Firestore Rules Tests

Bu klasör, `firestore.rules` için emulator tabanlı regresyon testlerini içerir.

## Kural dosyasını senkron tutma

`firestore_rules_tests/firestore.rules`, kök dizindeki `firestore.rules` dosyasının birebir kopyasıdır.
Kök kural dosyasını değiştirdikten sonra CI hata vermemesi için şu komutla test fixture dosyasını güncelleyin:

```bash
cp firestore.rules firestore_rules_tests/firestore.rules
```

## Çalıştırma

1. Bağımlılıkları yükleyin:
   - `npm install`
2. Firebase emulator'u açın (Firestore, port 8080):
   - `npx firebase-tools emulators:start --only firestore`
3. Testleri çalıştırın:
   - `npm test`

Alternatif tek komut:
- `npx firebase-tools emulators:exec --only firestore --project fiyatradar-rules-ci "npm test"`

Bu testler `.github/workflows/flutter_ci.yml` içinde otomatik çalışır.
