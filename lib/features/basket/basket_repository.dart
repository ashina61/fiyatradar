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
  final Map<String, String> marketNames;
  final int priceDocumentCount;

  const BasketPriceFetchResult({
    required this.latestPricesByItem,
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
    List<BasketItemDescriptor> items,
  ) async {
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
    final marketNames = <String, String>{};

    for (final price in priceDocs) {
      if (!price.isApproved || price.price <= 0) {
        continue;
      }
      final marketId = _marketId(price);
      if (marketId.isEmpty) continue;
      marketNames[marketId] = price.storeName?.isNotEmpty == true ? price.storeName! : marketId;

      for (final item in items) {
        if (item.productId == null || item.productId!.isEmpty) continue;
        if (price.productId != item.productId) continue;
        final current = latestByItem[item.key]?[marketId];
        if (current == null || price.createdAt.isAfter(current.createdAt)) {
          latestByItem[item.key]![marketId] = price;
        }
      }
    }

    return BasketPriceFetchResult(
      latestPricesByItem: latestByItem,
      marketNames: marketNames,
      priceDocumentCount: priceDocs.length,
    );
  }

  Future<List<PriceModel>> _fetchFromCollection({
    required String collectionName,
    required String field,
    required List<String> values,
  }) async {
    if (values.isEmpty) return [];
    final results = <PriceModel>[];
    for (var i = 0; i < values.length; i += _chunkSize) {
      final chunk = values.sublist(
        i,
        i + _chunkSize > values.length ? values.length : i + _chunkSize,
      );
      final query = SafeQueryBuilder.safeWhereIn(
        _firestore.collection(collectionName),
        field,
        chunk,
      );
      final snapshot = await query.get();
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
