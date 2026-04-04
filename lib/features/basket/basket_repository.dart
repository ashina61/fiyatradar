import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/price_model.dart';
import '../../utils/safe_query_builder.dart';

class BasketItemDescriptor {
  final String key;
  final String? productId;

  const BasketItemDescriptor({
    required this.key,
    this.productId,
  });
}

class BasketPriceFetchResult {
  final Map<String, Map<String, PriceModel>> latestPricesByItem;
  final Set<String> unverifiedPriceItemKeys;
  final Map<String, String> marketNames;
  final int priceDocumentCount;

  const BasketPriceFetchResult({
    required this.latestPricesByItem,
    required this.unverifiedPriceItemKeys,
    required this.marketNames,
    required this.priceDocumentCount,
  });
}

class BasketRepository {
  BasketRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int _chunkSize = 10;

  Future<BasketPriceFetchResult> fetchPricesForBasketItems(
    List<BasketItemDescriptor> items, {
    Set<String>? allowedStoreIds,
  }) async {
    final productIds = items
        .map((item) => item.productId?.trim())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final priceDocs = <PriceModel>[];

    // Denormalized yapı varsa tek sorgu katmanı olarak onu kullan.
    final latestPriceDocs = await _fetchFromCollection(
      collectionName: 'latest_prices',
      field: 'productId',
      values: productIds,
    );
    if (latestPriceDocs.isNotEmpty) {
      priceDocs.addAll(latestPriceDocs);
    } else {
      // Fallback: eski koleksiyonları tara.
      priceDocs.addAll(await _fetchFromCollection(
        collectionName: 'prices',
        field: 'productId',
        values: productIds,
      ));
      if (priceDocs.isEmpty) {
        priceDocs.addAll(await _fetchFromCollection(
          collectionName: 'priceReports',
          field: 'productId',
          values: productIds,
        ));
      }
    }

    final latestByItem = {
      for (final item in items) item.key: <String, PriceModel>{},
    };
    final unverifiedItemKeys = <String>{};
    final marketNames = <String, String>{};

    final pricesByProductByMarket = <String, Map<String, List<PriceModel>>>{};
    for (final price in priceDocs) {
      if (price.price <= 0) continue;
      final marketId = _marketId(price);
      if (marketId.isEmpty) continue;
      if (allowedStoreIds != null && allowedStoreIds.isNotEmpty && !allowedStoreIds.contains(marketId)) {
        continue;
      }
      marketNames[marketId] = price.storeName?.isNotEmpty == true ? price.storeName! : marketId;

      final byMarket = pricesByProductByMarket.putIfAbsent(price.productId, () => {});
      byMarket.putIfAbsent(marketId, () => []).add(price);
    }

    for (final item in items) {
      final productId = item.productId?.trim();
      if (productId == null || productId.isEmpty) continue;
      final byMarket = pricesByProductByMarket[productId];
      if (byMarket == null) continue;

      for (final entry in byMarket.entries) {
        final sorted = [...entry.value]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final approved = sorted.where((price) => price.isApproved).toList();
        final selected = approved.isNotEmpty ? approved.first : sorted.first;
        latestByItem[item.key]![entry.key] = selected;
        if (!selected.isApproved) {
          unverifiedItemKeys.add(item.key);
        }
      }
    }

    return BasketPriceFetchResult(
      latestPricesByItem: latestByItem,
      unverifiedPriceItemKeys: unverifiedItemKeys,
      marketNames: marketNames,
      priceDocumentCount: priceDocs.length,
    );
  }



  Future<PriceModel?> fetchLastPrice(String productId) async {
    final trimmed = productId.trim();
    if (trimmed.isEmpty) return null;

    final latestCandidates = await _fetchFromCollection(
      collectionName: 'latest_prices',
      field: 'productId',
      values: [trimmed],
    );

    var candidates = latestCandidates;
    if (candidates.isEmpty) {
      candidates = await _fetchFromCollection(
        collectionName: 'prices',
        field: 'productId',
        values: [trimmed],
      );
      if (candidates.isEmpty) {
        candidates = await _fetchFromCollection(
          collectionName: 'priceReports',
          field: 'productId',
          values: [trimmed],
        );
      }
    }

    if (candidates.isEmpty) return null;

    final valid = candidates.where((price) => price.price > 0).toList();
    if (valid.isEmpty) return null;

    valid.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final approved = valid.where((price) => price.isApproved).toList();
    return approved.isNotEmpty ? approved.first : valid.first;
  }

  Future<List<PriceModel>> _fetchFromCollection({
    required String collectionName,
    required String field,
    required List<String> values,
  }) async {
    if (values.isEmpty) return [];
    final chunks = <List<String>>[];
    for (var i = 0; i < values.length; i += _chunkSize) {
      chunks.add(
        values.sublist(
          i,
          i + _chunkSize > values.length ? values.length : i + _chunkSize,
        ),
      );
    }

    final snapshots = await Future.wait(
      chunks.map((chunk) {
        final query = SafeQueryBuilder.safeWhereIn(
          _firestore.collection(collectionName),
          field,
          chunk,
        );
        return query.get();
      }),
    );

    final results = <PriceModel>[];
    for (final snapshot in snapshots) {
      results.addAll(snapshot.docs.map(PriceModel.fromFirestore));
    }
    return results;
  }

  String _marketId(PriceModel price) {
    final storeId = price.storeId.trim();
    if (storeId.isNotEmpty) return storeId;
    return (price.storeName ?? '').trim();
  }
}
