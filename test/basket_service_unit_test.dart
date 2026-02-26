import 'package:flutter_test/flutter_test.dart';
import 'package:fiyatradar/models/basket_item_model.dart';
import 'package:fiyatradar/models/price_model.dart';
import 'package:fiyatradar/services/basket_service.dart';

void main() {
  test('calculateRecommendations computes best mix and missing ids', () async {
    final service = BasketService.withPriceFetcher((_) async => [
          PriceModel(
            id: '1',
            productId: 'p1',
            userId: 'u1',
            price: 10,
            branchStoreId: 'A',
            storeName: 'A',
            reportedAt: DateTime(2024, 1, 1),
            isApproved: true,
          ),
          PriceModel(
            id: '2',
            productId: 'p1',
            userId: 'u1',
            price: 12,
            branchStoreId: 'B',
            storeName: 'B',
            reportedAt: DateTime(2024, 1, 1),
            isApproved: true,
          ),
          PriceModel(
            id: '3',
            productId: 'p2',
            userId: 'u1',
            price: 5,
            branchStoreId: 'B',
            storeName: 'B',
            reportedAt: DateTime(2024, 1, 1),
            isApproved: true,
          ),
        ]);

    final result = await service.calculateRecommendations([
      BasketItemModel(productId: 'p1', quantity: 1),
      BasketItemModel(productId: 'p2', quantity: 2),
      BasketItemModel(productId: 'p3', quantity: 1),
    ]);

    expect(result.bestMixTotal, 20);
    expect(result.missingProductIds, ['p3']);
    expect(result.perStoreCoverage['B'], 2);
  });

  test('ignores unapproved or zero-price rows', () async {
    final service = BasketService.withPriceFetcher((_) async => [
          PriceModel(
            id: '1',
            productId: 'p1',
            userId: 'u1',
            price: 0,
            branchStoreId: 'A',
            storeName: 'A',
            reportedAt: DateTime(2024, 1, 1),
            isApproved: true,
          ),
          PriceModel(
            id: '2',
            productId: 'p1',
            userId: 'u1',
            price: 7,
            branchStoreId: 'B',
            storeName: 'B',
            reportedAt: DateTime(2024, 1, 1),
            isApproved: false,
          ),
          PriceModel(
            id: '3',
            productId: 'p1',
            userId: 'u1',
            price: 9,
            branchStoreId: 'C',
            storeName: 'C',
            reportedAt: DateTime(2024, 1, 1),
            isApproved: true,
          ),
        ]);

    final result = await service.calculateRecommendations([
      BasketItemModel(productId: 'p1', quantity: 1),
    ]);

    expect(result.bestMixTotal, 9);
    expect(result.missingProductIds, isEmpty);
    expect(result.perStoreTotal.keys, ['C']);
  });
}
