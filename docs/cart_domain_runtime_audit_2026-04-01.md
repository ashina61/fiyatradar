# Cart Domain Final Audit & Consolidation Plan (2026-04-01)

## 1) Active files

### Runtime entry / navigation
- `lib/main.dart` (`AppStartGate` -> `MainScreen`)
- `lib/app_router.dart` (`/main` -> `MainScreen`)
- `lib/screens/main_screen.dart` (tab index `3` -> `HomeShellScreen`)
- `lib/screens/cart/home_shell_screen.dart` (`HomeShellScreen` -> `CartScreenV2`)

### Active cart runtime (UI + state + data)
- `lib/screens/cart/cart_screen_v2.dart`
- `lib/screens/cart/cart_result_tab.dart`
- `lib/features/basket/basket_view_model.dart`
- `lib/features/basket/basket_repository.dart`
- `lib/features/basket/cart_comparison_state.dart`
- `lib/services/cart_comparison_service.dart`
- `lib/services/firestore_service.dart` (basket/store/product streams used by VM)
- `lib/providers/auth_provider.dart` (`authStateProvider`, `authUidProvider`)
- `lib/providers/product_provider.dart` (`allProductsProvider` in product picker)

## 2) Active runtime chain

1. Authenticated user lands in `MainScreen`.
2. Bottom tab `Sepet` (`index: 3`) renders `HomeShellScreen`.
3. `HomeShellScreen` delegates directly to `CartScreenV2`.
4. `CartScreenV2` watches `authStateProvider` and then `basketViewModelProvider`.
5. `basketViewModelProvider` binds auth uid (`authUidProvider`) into `BasketViewModel.setUser`.
6. `BasketViewModel` subscribes Firestore basket stream + products; cart item changes are persisted via `FirestoreService`.
7. `calculate()` fetches latest prices through `BasketRepository.fetchPricesForBasketItems` and computes comparison via `CartComparisonService.compare`.
8. Result is normalized into `CartComparisonState` (`success|empty|error`) and shown by `CartResultTab`.

## 3) Active vs legacy table / verdict

| Domain parçası | Durum | Verdict |
|---|---|---|
| `main.dart` -> `MainScreen` -> `HomeShellScreen` -> `CartScreenV2` | Active production path | **Keep (canonical)** |
| `features/basket/BasketViewModel + BasketRepository + CartComparisonService` | Active production path | **Keep + harden** |
| `screens/cart/cart_result_tab.dart` | Active production path | **Keep + simplify messaging** |
| `screens/cart/home_shell_screen.dart` | Compat wrapper | **Freeze (thin adapter)** |
| `features/basket/basket_screen.dart` | Not wired to router/tab; old UX using same VM | **Legacy compat candidate (freeze)** |
| `screens/cart/cart_provider.dart` | Mock seeded local cart provider | **Mock candidate (remove)** |
| `screens/cart/comparison_provider.dart` | Hardcoded market comparison mock | **Mock candidate (remove)** |
| `screens/cart/tab_provider.dart` | Old tab state provider not referenced | **Dead candidate (remove)** |
| `features/cart_analysis/*` | Parallel cart+comparison system; no runtime reference | **Dead/legacy candidate (remove or archive)** |
| `screens/cart/market_comparison.dart` + `screens/cart/cart_item.dart` | Old model layer used by mock providers | **Dead candidate (remove with providers)** |

## 4) Top technical risks

1. **Parallel domain implementations still in tree**
   - Active path: `CartScreenV2` + `BasketViewModel`
   - Inactive alternatives: `features/cart_analysis/*`, `basket_screen.dart`, `screens/cart/*_provider.dart`
   - Risk: accidental re-linking, maintenance split, regression confusion.

2. **Location permission side-effect remains in active calculate path**
   - `BasketViewModel.calculate()` always calls `locationService.getCurrentPosition()`.
   - `CartComparisonService.compare()` ignores the received `userPosition` (`final _ = userPosition`) and sets `nearestMarket: null`.
   - Result: unnecessary permission prompt / latency without product value.

3. **Store-policy mismatch risk (nearest/location remnants)**
   - Policy says location/nearest logic is non-core; active code still requests location during calculation.
   - This creates behavioral drift vs documented canonical policy.

4. **Data-source fallback complexity can hide stale behavior**
   - `BasketRepository` attempts `latest_prices` then falls back to `prices` and `priceReports`.
   - Works for compatibility but increases semantic ambiguity in production result consistency.

5. **UI duplication debt**
   - `basket_screen.dart` and `cart_screen_v2.dart` both expose basket UX over similar VM responsibilities.
   - Even if only one is routed today, duplicated UI flow slows product convergence.

## 5) Remove / freeze / delete candidates

### Freeze (short-term, do not expand)
- `lib/screens/cart/home_shell_screen.dart` (compat entry only)
- `lib/features/basket/basket_screen.dart` (legacy VM UI path)

### Remove (direct dead/mock)
- `lib/screens/cart/cart_provider.dart`
- `lib/screens/cart/comparison_provider.dart`
- `lib/screens/cart/tab_provider.dart`
- `lib/screens/cart/cart_item.dart`
- `lib/screens/cart/market_comparison.dart`

### Remove or archive as one block
- `lib/features/cart_analysis/models/*`
- `lib/features/cart_analysis/providers/*`
- `lib/features/cart_analysis/repositories/*`
- `lib/features/cart_analysis/services/*`
- `lib/features/cart_analysis/views/cart_analysis_screen.dart`

## 6) Canonical cart recommendation

Production canonical must be:
- **UI:** `CartScreenV2` + `CartResultTab`
- **State:** `BasketViewModel`
- **Fetch:** `BasketRepository`
- **Comparison engine:** `CartComparisonService`

Canonical constraints:
1. Single comparison pipeline only (`BasketViewModel.calculate`).
2. No mock providers in runtime tree.
3. No second cart-analysis runtime.
4. No location/nearest branching in cart decision path unless policy changes.

## 7) First consolidation target

### Target-1 (highest ROI, lowest product risk)
- Remove dead/mock cart providers and old models under `lib/screens/cart/*` that have zero references.
- Freeze legacy `basket_screen.dart` with explicit deprecation note.
- Remove location request from `BasketViewModel.calculate()` until/unless nearest market is truly reintroduced with product policy approval.

Expected immediate outcome:
- Single clear cart runtime surface.
- No mock leakage possibility.
- Better trust/performance in “Hesapla” flow.

## 8) Verify commands used

```bash
pwd && rg --files -g 'AGENTS.md'
find .. -name AGENTS.md -print
rg --files | head -n 200
rg -n "class MainScreen|HomeShellScreen|CartScreenV2|CartResultTab|cart|sepet|Basket|basket" lib/screens/main_screen.dart lib/screens/cart/*.dart lib/app_router.dart lib/main.dart
rg -n "CartScreenV2|HomeShellScreen|MainScreen|CartResultTab|cart_provider|comparison_provider|tab_provider|market_comparison|cart_list_detail_screen|cart_item" lib --glob '!**/*.g.dart'
nl -ba lib/main.dart | sed -n '100,180p'
nl -ba lib/app_router.dart | sed -n '1,120p'
nl -ba lib/screens/main_screen.dart | sed -n '1,220p'
nl -ba lib/screens/cart/home_shell_screen.dart
nl -ba lib/screens/cart/cart_screen_v2.dart | sed -n '1,240p'
nl -ba lib/screens/cart/cart_result_tab.dart | sed -n '1,260p'
nl -ba lib/screens/cart/cart_provider.dart | sed -n '1,220p'
nl -ba lib/screens/cart/comparison_provider.dart | sed -n '1,220p'
nl -ba lib/screens/cart/tab_provider.dart | sed -n '1,160p'
nl -ba lib/features/basket/basket_view_model.dart | sed -n '1,320p'
nl -ba lib/features/basket/basket_view_model.dart | sed -n '320,520p'
nl -ba lib/services/cart_comparison_service.dart | sed -n '1,360p'
nl -ba lib/features/basket/cart_comparison_state.dart | sed -n '1,280p'
nl -ba lib/features/basket/basket_repository.dart | sed -n '1,320p'
nl -ba lib/features/cart_analysis/providers/cart_analysis_providers.dart | sed -n '1,280p'
nl -ba lib/features/cart_analysis/views/cart_analysis_screen.dart | sed -n '1,260p'
rg -n "CartAnalysisScreen|cart_analysis|cartItemsProvider|marketComparisonsProvider|homeTabProvider|comparisonProvider|cartProvider" lib
nl -ba lib/screens/search/personal_lists_screen.dart | sed -n '1,240p'
nl -ba lib/screens/cart/cart_list_detail_screen.dart | sed -n '1,140p'
nl -ba lib/features/basket/basket_screen.dart | sed -n '1,260p'
rg -n "BasketScreen\(|basket_screen.dart" lib
nl -ba docs/store-policy.md | sed -n '1,260p'
nl -ba lib/services/location_service.dart | sed -n '1,220p'
```

## 9) Final severity verdict

- **Severity: HIGH (consolidation debt), MEDIUM (runtime correctness), LOW (immediate outage risk).**
- Production currently works through one dominant path (`CartScreenV2` + `BasketViewModel`), but substantial legacy/mock residue remains and can re-fragment the domain.
