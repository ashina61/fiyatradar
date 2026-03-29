# Engineering Ruleset (FiyatRadar)

## 1) hard rules

1. Katman sınırı zorunludur: **Repository = data access adapter**, **Service = domain I/O + query**, **Provider = state/orchestration**, **Screen = render + event dispatch**.
2. Provider içinde doğrudan `FirebaseFirestore` query yazılamaz; query yalnız Service/Repository katmanında yazılır.
3. Screen içinde business rule yazılamaz; iş akışı Provider/Service üzerinden yürütülür.
4. `FirestoreService` dependency injection tek kaynaktan alınır; duplicate provider tanımı yasaktır.
5. Mutation sonrası brute-force full reload yasaktır; yalnız etkilenen alan hedefli yenilenir.

## 2) forbidden patterns

1. `build()` içinde side-effect (listener kurma, async çağrı, state mutation) yasaktır.
2. Full snapshot çekip client-side sort/filter yapmak yasaktır.
3. Screen veya Provider içinde doğrudan collection path string’i ile Firestore query yazmak yasaktır.
4. Aynı sorumluluğu iki farklı provider/service içinde duplicate implement etmek yasaktır.
5. Geçici çözüm adıyla kalıcı `hide ...Provider` import hack’i yasaktır.

## 3) file size / split thresholds

1. **Screen** dosyası 350 LOC üstüne çıkarsa section/widget split zorunludur.
2. **Screen** dosyası 700 LOC üstüne çıkarsa ayrı dosyalara bölme zorunludur.
3. **Provider** dosyası 250 LOC üstüne çıkarsa state/action helper ayrımı zorunludur.
4. **Service** dosyası 300 LOC üstüne çıkarsa domain bazlı split zorunludur.
5. Tek method içinde 2’den fazla bağımsız query + ağır mapping varsa method split zorunludur.

## 4) firestore query standards

1. Listeleme/query işlemlerinde server-side `where/orderBy/limit` zorunludur.
2. Pagination gereken akışlarda cursor standardı zorunludur: `orderBy + startAfterDocument`.
3. Offset pagination yasaktır.
4. Count ihtiyacında aggregate `count()` önceliklidir; hata durumunda kontrollü fallback ve log zorunludur.
5. Search akışında full collection fetch yasaktır; indexed alanlar + limitli query kullanılmalıdır.
6. Detail ekranlarında initial load subset + targeted refresh zorunludur; mutation sonrası full `load()` yasaktır.

## 5) design token enforcement rules

1. Yeni kodda local `Color(0x...)` tanımı yasaktır.
2. Yeni kodda local spacing/radius sabitleri (magic number) yasaktır.
3. Renkler yalnız token katmanından (`FRColors` / Theme token) kullanılacaktır.
4. Spacing ve radius değerleri merkezi token sabitlerinden alınacaktır.
5. Legacy dosyalarda mevcut local değerler yalnız untouched bölgede kalabilir; yeni eklenen satırlar token kuralına uymak zorundadır.

## 6) navigation enforcement rules

1. Yeni navigation implementasyonu yalnız **GoRouter** ile yapılacaktır.
2. GoRouter dışında ikinci routing yaklaşımı (Navigator 1.0 custom stack, farklı router paketi) yasaktır.
3. Route tanımları merkezi router modülünde tutulacaktır; screen içinde ad-hoc route kurgusu yasaktır.
4. Auth/start gating tek noktadan çalışacaktır; ekran bazında paralel gating akışı eklemek yasaktır.

## 7) legacy exception policy

1. Legacy istisna yalnız açık etiketle kabul edilir: `LEGACY_EXCEPTION`.
2. Her istisna için zorunlu alanlar: `reason`, `owner`, `remove_by=YYYY-MM-DD`.
3. Legacy istisna süresi maksimum 2 sprinttir.
4. Legacy path/akışa yeni feature eklemek yasaktır; yalnız stabilization/fix yapılabilir.
5. Süresi geçmiş istisna bulunan PR merge edilemez.
6. İstisna eklenen PR’da `.github/pull_request_template.md` içindeki Legacy Exception bölümü doldurulmalı ve `docs/legacy-exception-allowlist.md` güncellenmelidir.

## 8) codex task template v2

Her Codex task’ı aşağıdaki blokları **zorunlu** içerir:

1. **Goal** (tek cümle, ölçülebilir hedef)
2. **Scope Allowlist** (değişebilecek dosyalar)
3. **Out of scope** (dokunulmayacak alanlar)
4. **Non-negotiables** (yasaklar)
5. **Acceptance Criteria** (AC1..ACn, pass/fail)
6. **Delivery Format** (execution plan, changed files, summary, risk, verify)
7. **Verify Commands** (çalıştırılacak net komutlar)

Eksik blok içeren task uygulanmaz.

## 9) merge checklist (mandatory gate)

- [ ] Scope dışı dosya değişmedi.
- [ ] Katman ihlali yok (Repository/Service/Provider/Screen).
- [ ] `build()` içinde side-effect eklenmedi.
- [ ] Full snapshot + client-side sort/filter eklenmedi.
- [ ] Full collection fetch eklenmedi.
- [ ] New query eklendiyse `orderBy/limit/count/index` notu PR açıklamasında var.
- [ ] Firestore path değiştiyse rules path drift kontrolü yapıldı ve sonucu yazıldı.
- [ ] GoRouter dışı navigation eklenmedi.
- [ ] Yeni kodda local `Color(0x...)`, `BorderRadius.circular(...)`, `EdgeInsets.*(...)` yok (script + review).
- [ ] Legacy exception varsa metadata (`reason/owner/remove_by`) ve allowlist kaydı eklendi.
- [ ] Verify komutları çalıştırıldı veya neden çalışmadığı yazıldı.
- [ ] Riskler ve rollback yaklaşımı yazıldı.

## 10) documented vs enforced map

| Rule | Enforcement |
|---|---|
| Local `Color(0x...)` yasağı | Script: `scripts/check_engineering_rules.sh` + PR checklist |
| Local `BorderRadius.circular(...)` yasağı | Script: `scripts/check_engineering_rules.sh` + PR checklist |
| Raw `EdgeInsets.*(...)` yasağı | Script: `scripts/check_engineering_rules.sh` + PR checklist |
| build() side-effect yasağı | PR checklist (review gate) |
| full collection fetch yasağı | PR checklist (review gate) |
| new query `order/limit/count/index` notu | PR checklist (review gate) |
| rules path drift kontrolü | PR checklist (review gate) |
| legacy exception policy | PR checklist + allowlist dosyası + script metadata kontrolü |

## 11) final non-negotiables

1. Scope dışına çıkılmaz.
2. Kod davranışını değiştiren gizli refactor yapılmaz.
3. Katman sınırları ihlal edilmez.
4. Full reload ve full snapshot pattern’i yeni kodda eklenmez.
5. GoRouter dışı navigation eklenmez.
6. Local style sabiti (color/spacing/radius) yeni kodda eklenmez.
7. AC’leri karşılamayan iş merge edilmez.

## 12) store model policy enforcement

1. Store model policy’nin canonical kaynağı `docs/store-policy.md` dosyasıdır.
2. Yeni feature/PR’lar branch/location-first store davranışı ekleyemez.
3. Legacy store alanları yalnız compatibility amaçlı taşınabilir; yeni iş kuralı kaynağı olamaz.

