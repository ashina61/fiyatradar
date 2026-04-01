# Home Screen Runtime Audit (2026-04-01)

## 1) Active files

- Entry/runtime routing: `lib/main.dart` -> `lib/app_router.dart` -> `lib/screens/main_screen.dart`.
- Active Home implementation: `lib/screens/home/home_screen.dart`.
- Home data providers:
  - `lib/providers/product_provider.dart`
  - `lib/providers/user_provider.dart`
  - `lib/providers/notification_provider.dart`
  - `lib/providers/auth_provider.dart`
- Home data services:
  - `lib/services/catalog_service.dart`
  - (partly) `lib/services/firestore_service.dart`
- Dead/legacy Home candidate (not in active tab chain): `lib/screens/home_screen.dart`.

## 2) Active runtime chain

### App -> Home mount chain
1. `main.dart` boots app, `AppStartGate` returns `MainScreen` for authenticated state.
2. `MainScreen` tab index 0 mounts `HomeScreen` from `lib/screens/home/home_screen.dart`.
3. Home watches these providers at build time:
   - `userModelStreamProvider`
   - `categoriesProvider`
   - `trendingProductsProvider`
   - `latestPricesProvider`
   - `homeTopUsersProvider`
   - `todaysNewUsersCountProvider`
   - `unreadCountProvider`
   - `editorPickProductsProvider`

### Home render blocks currently live
Render order inside `CustomScrollView`:
1. Header (profile, points, notification, search bar + barcode entry)
2. Category pills
3. Premium banner (`PremiumBannerSection`)
4. Insight grid (today stats)
5. Trend products horizontal list
6. Editor’s choice hero block
7. Latest prices list (top 5 from stream)
8. Leaders block (top users)
9. Footer CTA (Add Price + scanner)

## 3) Block-by-block verdict

### Core blocks (keep)
- **Header + Search + Barcode quick action**: direct path to discovery and action; core for product lookup speed.
- **Trend products**: strong Product Detail entry path via cards.
- **Latest prices**: strongest “freshness/trust” signal; includes Product Detail deeplink.
- **Footer Add Price CTA**: direct contribution funnel.

### Nice-to-have blocks (deprioritize)
- **Category pills**: useful but currently Home->Search jump behavior means this is a pre-filter launcher, not Home value itself.
- **Editor’s choice**: curated merchandising; can stay only if it doesn’t dominate above-the-fold.

### Freeze candidates (short-term no-invest)
- **Leaders (Öne Çıkan Avcılar)**: gamification/social proof, weak core relation to immediate price value.
- **Insight grid (today prices + today signups)**: partly useful (today prices), partly vanity/ops metric (today signups).
- **Premium banner section**: not core to immediate product/price flow.

### Remove candidates (if simplification wave starts)
- “Today signups” metric card.
- Leaderboard section on Home.
- One of duplicate scanner triggers (header search bar scanner + footer scanner) to reduce interaction noise.

## 4) Top technical risks

1. **Full-scan editor pick stream**
   - `getEditorPickProducts` listens to full `products` snapshots then filters/sorts in memory; this scales poorly.
2. **Mixed provider styles and inconsistent freshness semantics**
   - Home mixes multiple `StreamProvider` and `FutureProvider` sources in one frame; some sections live update, others snapshot-only.
3. **Silent truncation / capped datasets**
   - `latestPricesProvider` is capped (`limit: 10`) while UI displays top 5, and trend math derives from same capped subset.
   - Trend computation may be statistically misleading if recent 10 prices don’t include adequate per-product history.
4. **Dual source/service semantics overlap**
   - Home uses `CatalogService` via providers for products/prices, but user/top-user metrics directly hit `FirebaseFirestore.instance` in provider layer (`homeTopUsersProvider`, `todaysNewUsersCountProvider`).
   - This creates service boundary drift and makes optimization/instrumentation harder.
5. **Legacy surface risk**
   - `lib/screens/home_screen.dart` exists as separate Home widget and can cause confusion/regression during refactors.

## 5) Remove/freeze candidates

### Freeze now
- Premium banner block
- Leaderboard block
- Insight block structure (especially signup KPI)

### Remove in first cleanup wave
- Signup KPI card from Home
- Duplicate scanner entry point (keep one)
- Legacy `lib/screens/home_screen.dart` after confirming no references

## 6) First target recommendation (ordered)

1. **First fix (core clarity):** Reorder Home to emphasize `Search -> Trend Products -> Latest Prices -> Add Price`.
2. **Then freeze:** Mark Premium/Leaderboard/Insight as frozen modules (no new features, bug-fix only).
3. **Then remove:** Remove non-core KPI card(s) and redundant scanner trigger; optionally hide Leaders by feature flag before deletion.
4. **Then refactor data layer:**
   - Convert editor pick query to indexed Firestore query (`where(isEditorPick == true)` + ordered rank), avoid full collection stream.
   - Normalize Home data fetch through one service boundary (prefer `CatalogService`/domain services over direct Firestore in providers).
   - Split Home into explicit core/non-core widgets with separate loading/error handling.

## 7) Verify commands used

- `pwd && rg --files -g 'AGENTS.md'`
- `rg --files | head -n 200`
- `sed -n '1,240p' lib/main.dart`
- `sed -n '1,280p' lib/screens/main_screen.dart`
- `sed -n '1,260p' lib/screens/home/home_screen.dart`
- `sed -n '260,620p' lib/screens/home/home_screen.dart`
- `sed -n '620,980p' lib/screens/home/home_screen.dart`
- `sed -n '980,1300p' lib/screens/home/home_screen.dart`
- `sed -n '1300,1520p' lib/screens/home/home_screen.dart`
- `sed -n '1,260p' lib/screens/home_screen.dart`
- `sed -n '1,260p' lib/app_router.dart`
- `sed -n '1,320p' lib/providers/product_provider.dart`
- `sed -n '1,320p' lib/providers/user_provider.dart`
- `sed -n '1,260p' lib/providers/notification_provider.dart`
- `sed -n '1,360p' lib/services/catalog_service.dart`

## 8) Final severity verdict

**Severity: High (product-focus drift + medium technical scaling risk).**
- Product-focus drift is already visible (too many non-core sections on Home).
- Technical risk is not immediate outage risk, but clear maintainability/perf debt around query strategy and mixed data boundaries.
