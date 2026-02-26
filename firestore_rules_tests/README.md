# Firestore Rules Tests

Bu klasör, `firestore.rules` için emulator tabanlı regresyon testlerini içerir.

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
