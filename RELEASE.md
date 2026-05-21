# FiyatRadar — Release Build Rehberi

Bu doküman Play Store yüklemesi için imzalı **AAB** (Android App Bundle)
nasıl üretilir, hem CI'da (GitHub Actions) hem local'de açıklar.

## 1. GitHub Actions ile imzalı release AAB

Workflow: [`.github/workflows/release-build.yml`](.github/workflows/release-build.yml)

Tetikleyiciler:
- `workflow_dispatch` — Actions sekmesinden manuel "Run workflow".
- `push` → `main` — her main commit'inde otomatik build.

### Gerekli repository secrets

GitHub repo → **Settings → Secrets and variables → Actions → New
repository secret** ile aşağıdaki üç secret'ı ekleyin:

| Secret adı | İçerik |
| --- | --- |
| `KEYSTORE_BASE64` | `upload-keystore.jks` dosyasının base64'lenmiş hali. Local'de `base64 -w 0 upload-keystore.jks` çıktısını secret değerine yapıştırın. |
| `KEYSTORE_PASSWORD` | Keystore parolası (32 karakter alfanümerik). |
| `KEY_PASSWORD` | Anahtar (alias=`upload`) parolası. Mevcut keystore'da keystore parolası ile aynı; ileride farklılaştırırsanız bu değeri ayrıca güncelleyin. |

> `KEY_ALIAS` workflow'da sabit (`upload`) olarak geçilir; secret olarak
> eklemeye gerek yok. Keystore üretilirken alias değiştirilirse
> `.github/workflows/release-build.yml` içindeki `KEY_ALIAS` env değerini
> ve `build.gradle` içindeki signing config'i güncelleyin.

Artifact: `app-release-aab` adıyla 30 gün boyunca workflow run'ında
indirilebilir (`build/app/outputs/bundle/release/app-release.aab`).
Job sonunda decode edilen keystore dosyası runner'dan silinir.

## 2. Local'de imzalı AAB üretme

1. **Keystore'u temin et.** Üretim keystore'u repo'da değildir; güvenli
   vault'tan (1Password / Bitwarden) `upload-keystore.jks` dosyasını
   indirip `android/upload-keystore.jks` konumuna kopyalayın. `.jks`
   uzantısı `.gitignore`'da; yanlışlıkla commit edilmez.
2. **`android/key.properties` oluştur.** `android/key.properties.example`
   şablonunu kopyalayıp parolaları doldurun:
   ```bash
   cp android/key.properties.example android/key.properties
   $EDITOR android/key.properties
   ```
   `storeFile` değeri `key.properties`'in bulunduğu klasöre göre
   *relative* yazılır; `../upload-keystore.jks` (yani repo kökünden
   `android/upload-keystore.jks`) örnek dosyada hazır.
3. **Build:**
   ```bash
   flutter pub get
   flutter build appbundle --release
   ```
4. Çıktı: `build/app/outputs/bundle/release/app-release.aab`.

### Yeni keystore üretmek

İlk defa keystore üreteceksen:

```bash
keytool -genkeypair -v \
  -keystore android/upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -dname "CN=Adem, O=FiyatRadar, L=Istanbul, ST=Istanbul, C=TR"
```

`-storepass` / `-keypass` argümanlarını boş bırakırsanız `keytool`
interaktif olarak sorar. Üretilen parolayı **1Password / Bitwarden**'a
kaydedin; kaybolursa Play Console'da uygulamanın imza anahtarını
döndürmek (Play App Signing key rotation) gerekecek.

## 3. Version yönetimi

`pubspec.yaml` içinde:

```yaml
version: 1.0.1+3
```

- Soldaki `1.0.1` → Play Console'da görünen **versionName**.
- `+` sonrası `3` → **versionCode**. Play Store her yüklemede *önceki
  versionCode'dan büyük* bir değer ister.

Her release çıkmadan önce versionCode'u manuel +1 artırın
(`1.0.1+3` → `1.0.1+4`). Patch/minor/major bump yapıyorsanız versionName
de güncellenmeli (`1.0.1` → `1.0.2`). İleride bunu CI'da otomatize
edebiliriz (örn. `${{ github.run_number }}` ile versionCode override
edip workflow input olarak versionName almak).

## 4. Sorun giderme

- **`Keystore was tampered with, or password was incorrect`** — secret
  olarak eklediğin `KEYSTORE_PASSWORD` ile keystore üretim sırasında
  girdiğin parola farklı. 1Password'daki kaydı doğrula, gerekirse
  keystore'u yeniden üret.
- **`Failed to read key upload from store ...`** — `KEY_ALIAS` veya
  `KEY_PASSWORD` yanlış. Keystore tek alias (`upload`) ile üretildi;
  başka alias kullanmadığından emin ol.
- **CI'da `KEYSTORE_BASE64 secret is empty`** — secret'ı eklemeyi
  unutmuşsun veya yanlış adla eklemişsin (`KEYSTORE_BASE64` tam
  bu şekilde olmalı).
- **`Release build requested but no signing config available`** — release
  build için ne env değişkenleri ne `android/key.properties` mevcut.
  Eskiden bu durumda sessizce debug imzasına düşülüyor ve AAB Play
  Console'a yüklendiğinde "debug signed" hatasıyla reddediliyordu; artık
  build erken patlar. `key.properties` dosyasını doğrula veya CI
  değişkenlerini local shell'e export et. `flutter run` (debug build)
  her iki kaynak da yoksa bile çalışmaya devam eder.
- **`KEYSTORE_PATH set to '…' but resolved file does not exist`** —
  env değişkeni doğru tanımlı ama keystore dosyası gösterilen konumda
  yok. CI'da bu, decode adımının atlanmasını veya çalışma dizininin
  beklenmedik olmasını gösterir; local'de KEYSTORE_PATH'i absolute
  path olarak ver veya repo köküne göre relatif yaz (örn.
  `android/upload-keystore.jks`).
