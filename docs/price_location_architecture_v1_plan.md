# Price/Location Architecture Correction Plan (Production V1)

## 1) Current architecture problems (repo-inspected)

- `products.priceHistory` is an unbounded embedded array used as the runtime source of truth for all price flows; this does not scale for write/read size and couples catalog + transactional data. (`Product.priceHistory`, `Product.fromDoc`, `AppState.addPrice`).  
- Add Price currently uses a flat `stores` list and client-side filtering, not regional place records; no source-type split (physical/online/bazaar) exists in the flow.  
- Home/Explore/Basket/Product calculations derive “best/lowest” from global `priceHistory`, so out-of-region physical prices can become default best price.  
- Admin “market management” currently operates on `stores` collection and includes full-collection scans for duplicate checks / rename propagation across every product history entry.
- Firestore rules are still centered on `products.priceHistory` mutation by clients and have no dedicated `store_places`, `store_chains`, `price_entries`, `price_summaries` governance path.

## 2) Proposed Production V1 architecture

### Collections

- `products` (global catalog only; no unbounded price arrays).
- `store_chains` (brand-level identity: A101, BİM, ŞOK, Migros, CarrefourSA, etc.).
- `store_places` (location-level place records, includes online pseudo-places and bazaar points).
- `price_entries` (source of truth for price submissions).
- `price_summaries` (materialized read models for best/latest by scope).

### Fields

- Align with product requirement document:
  - `store_chains`: `name`, `normalizedName`, `type`, `isActive`, timestamps.
  - `store_places`: chain refs, type, display/normalized names, region, geo, moderation status, activity, usage metrics, creator, timestamps.
  - `price_entries`: product snapshots, price, scope, source type, chain/place refs, region/geo, reporting + moderation + voting signals, timestamps.
  - `price_summaries`: denormalized best/latest scoped outputs (`product+district`, `product+city`, `product+online`, `product+place`).

### Indexes likely needed

- `store_places`:  
  - `(isActive, type, city, district, usageCount desc)`  
  - `(isActive, type, normalizedName)` for prefix-search.
- `price_entries`:  
  - `(productId, sourceType, city, district, createdAt desc)`  
  - later: `(productId, status, scope, createdAt desc)` and `(placeId, productId, createdAt desc)`.

### Read/write flow

- **Add Price**: User chooses source type first ➜ query `store_places` with source + region constraints + limit(20-30) + search ➜ write to `price_entries` ➜ temporary compatibility write to `products.priceHistory`.
- **Product Detail/Home/Explore**: consume `price_summaries` first; fallback to scoped `price_entries` queries if summary missing; local physical scope is primary default, online separate, Turkey-wide non-default.
- **Admin**: filter-first list queries for `store_places` and moderation queues; no full list render.

## 3) Migration plan (safe phases)

1. **Phase A (compat start)**  
   Add new collections, rules, indexes, models. Keep `products.priceHistory` as read-compatible legacy.
2. **Phase B (dual-write)**  
   Add Price writes `price_entries` + legacy `priceHistory` compatibility write.
3. **Phase C (read migration)**  
   Product Detail/Home/Explore read scoped `price_entries` / `price_summaries`; stop defaulting to global array.
4. **Phase D (backfill)**  
   Batch-export old `priceHistory` into `price_entries` with `legacy.backfilled=true`.
5. **Phase E (deprecation)**  
   Freeze legacy writes, then remove runtime dependency on `priceHistory`.

## 4) Implementation plan (max 8 PR-sized steps)

1. Add v1 data models (`store_places`, source/scope enums, entry payload contract).
2. Add Firestore collection accessors + rules + required indexes for constrained place/entry queries.
3. Implement Add Price source-type selection and region-limited `store_places` query (limit 30 + search).
4. Implement pending `store_place` request write path from Add Price when no place exists.
5. Switch Add Price persistence to dual-write (`price_entries` primary + `products.priceHistory` compatibility).
6. Add repository/service for scoped `price_entries` reads (district/city/online/turkey-wide).
7. Migrate Product Detail/Home/Explore read-path to region-aware scoped data.
8. Add admin filter-first screens for chains/places/moderation (pagination + merge/deactivate actions).

## 5) Security note (explicit limitation)

Current codebase still allows client-originated price write paths. Without Cloud Functions (or equivalent trusted backend), the app is **not fully secure** for points/trust/vote/moderation/admin invariants. This turn only tightens schema/rules and starts migration; full trust enforcement remains backend work.
