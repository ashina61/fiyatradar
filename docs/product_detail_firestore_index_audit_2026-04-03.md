# Product Detail Firestore Composite Index Audit (2026-04-03)

## Offending query (runtime)
`ProductDetailNotifier.load()` calls `ProductDetailApiService.fetchPriceHistory(productId)` on Product Detail screen load.

```dart
final snapshot = await _pricesRef
    .where('productId', isEqualTo: productId)
    .where('status', isEqualTo: 'active')
    .where('reportedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
    .orderBy('reportedAt')
    .limit(_historyLimit)
    .get();
```

## Query shape
- Collection: `priceReports`
- where clauses:
  - `productId == <productId>`
  - `status == 'active'`
  - `reportedAt >= <since>`
- orderBy clauses:
  - `reportedAt ASC`
- limit clauses:
  - `limit(240)` (`_historyLimit`)

## Why Firestore asks for composite index
This query combines:
1. multiple filters on different fields (`productId`, `status`, `reportedAt`), and
2. a range filter + `orderBy` on `reportedAt`.

Firestore needs a composite index that starts with equality filters and ends with the ordered/range field.

## Decision
Keep the existing query shape.

Reason:
- It matches Product Detail history behavior (last 90 days, chronological chart data).
- `limit(240)` bounds read cost.
- Simplifying by removing filters/order would either change behavior or increase scanned docs.

## Exact index definition
Use a **COLLECTION** index on `priceReports` with fields in this order:
1. `productId` — `ASCENDING`
2. `status` — `ASCENDING`
3. `reportedAt` — `ASCENDING`

Equivalent `firestore.indexes.json` entry:

```json
{
  "collectionGroup": "priceReports",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "productId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "reportedAt", "order": "ASCENDING" }
  ]
}
```

## Repo status check
This exact index already exists in `firestore.indexes.json`; if you still see the runtime error, the most likely issue is that indexes were not deployed to the current Firebase project/environment.
