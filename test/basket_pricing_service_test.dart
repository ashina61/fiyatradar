import 'package:flutter_test/flutter_test.dart';
import 'package:fiyatradar/models/basket_item_model.dart';
import 'package:fiyatradar/models/price_model.dart';
import 'package:fiyatradar/models/product_model.dart';
import 'package:fiyatradar/services/basket_pricing_service.dart';

void main() {
  PriceModel buildPrice({
    required String id,
    required String productId,
    required String storeName,
    required double price,
    bool isApproved = true,
  }) {
    return PriceModel(
      id: id,
      productId: productId,
      userId: 'user',
      price: price,
      storeName: storeName,
      createdAt: DateTime(2024, 1, 1),
      isApproved: isApproved,
      isPending: !isApproved,
    );
  }

  ProductModel buildProduct({
    required String id,
    required String name,
  }) {
    return ProductModel(
      id: id,
      name: name,
      brand: 'brand',
      categories: const ['cat'],
      createdAt: DateTime(2024, 1, 1),
    );
  }

  test('all products available in all markets', () {
    final items = [
      BasketItemModel(productId: 'p1', quantity: 1),
      BasketItemModel(productId: 'p2', quantity: 2),
    ];
    final productMap = {
      'p1': buildProduct(id: 'p1', name: 'Sut'),
      'p2': buildProduct(id: 'p2', name: 'Ekmek'),
    };
    final prices = [
      buildPrice(id: '1', productId: 'p1', storeName: 'A', price: 10),
      buildPrice(id: '2', productId: 'p2', storeName: 'A', price: 5),
      buildPrice(id: '3', productId: 'p1', storeName: 'B', price: 9),
      buildPrice(id: '4', productId: 'p2', storeName: 'B', price: 6),
    ];

    final result = BasketPricingService.forTest().calculateFromPrices(items, productMap, prices);

    expect(result.bestSingleMarket?.marketName, 'A');
    expect(result.bestSingleMarket?.total, 20);
    expect(result.mixedBasket.total, 19);
    expect(result.mixedBasket.missingProductIds, isEmpty);
  });

  test('some products missing in some markets', () {
    final items = [
      BasketItemModel(productId: 'p1', quantity: 1),
      BasketItemModel(productId: 'p2', quantity: 1),
    ];
    final productMap = {
      'p1': buildProduct(id: 'p1', name: 'Sut'),
      'p2': buildProduct(id: 'p2', name: 'Ekmek'),
    };
    final prices = [
      buildPrice(id: '1', productId: 'p1', storeName: 'A', price: 10),
      buildPrice(id: '2', productId: 'p1', storeName: 'B', price: 9),
      buildPrice(id: '3', productId: 'p2', storeName: 'B', price: 4),
    ];

    final result = BasketPricingService.forTest().calculateFromPrices(items, productMap, prices);

    expect(result.bestSingleMarket?.marketName, 'B');
    expect(result.bestSingleMarket?.total, 13);
    expect(result.mixedBasket.total, 13);
    expect(result.perMarketMissingCount['A'], 1);
  });

  test('no single market covers all but mixed is available', () {
    final items = [
      BasketItemModel(productId: 'p1', quantity: 1),
      BasketItemModel(productId: 'p2', quantity: 1),
    ];
    final productMap = {
      'p1': buildProduct(id: 'p1', name: 'Sut'),
      'p2': buildProduct(id: 'p2', name: 'Ekmek'),
    };
    final prices = [
      buildPrice(id: '1', productId: 'p1', storeName: 'A', price: 10),
      buildPrice(id: '2', productId: 'p2', storeName: 'B', price: 4),
    ];

    final result = BasketPricingService.forTest().calculateFromPrices(items, productMap, prices);

    expect(result.bestSingleMarket, isNull);
    expect(result.mixedBasket.total, 14);
    expect(result.mixedBasket.missingProductIds, isEmpty);
  });

  test('mixed basket reports missing product when unavailable', () {
    final items = [
      BasketItemModel(productId: 'p1', quantity: 1),
      BasketItemModel(productId: 'p3', quantity: 1),
    ];
    final productMap = {
      'p1': buildProduct(id: 'p1', name: 'Sut'),
      'p3': buildProduct(id: 'p3', name: 'Peynir'),
    };
    final prices = [
      buildPrice(id: '1', productId: 'p1', storeName: 'A', price: 10),
    ];

    final result = BasketPricingService.forTest().calculateFromPrices(items, productMap, prices);

    expect(result.bestSingleMarket, isNull);
    expect(result.mixedBasket.total, 10);
    expect(result.mixedBasket.missingProductIds, ['p3']);
    expect(result.perMarketMissingCount['A'], 1);
  });

  test('ignores unapproved prices in calculations', () {
    final items = [
      BasketItemModel(productId: 'p1', quantity: 1),
    ];
    final productMap = {
      'p1': buildProduct(id: 'p1', name: 'Sut'),
    };
    final prices = [
      buildPrice(id: '1', productId: 'p1', storeName: 'A', price: 10, isApproved: false),
      buildPrice(id: '2', productId: 'p1', storeName: 'B', price: 12, isApproved: true),
    ];

    final result = BasketPricingService.forTest().calculateFromPrices(items, productMap, prices);

    expect(result.bestSingleMarket?.marketName, 'B');
    expect(result.bestSingleMarket?.total, 12);
    expect(result.mixedBasket.total, 12);
  });

  test('mixed basket always picks cheapest product price across stores', () {
    final items = [
      BasketItemModel(productId: 'p1', quantity: 1),
    ];
    final productMap = {
      'p1': buildProduct(id: 'p1', name: 'Sut'),
    };
    final prices = [
      buildPrice(id: '1', productId: 'p1', storeName: 'A', price: 9),
      buildPrice(id: '2', productId: 'p1', storeName: 'B', price: 12),
      buildPrice(id: '3', productId: 'p1', storeName: 'A', price: 8),
    ];

    final result = BasketPricingService.forTest().calculateFromPrices(items, productMap, prices);

    expect(result.mixedBasket.total, 8);
  });
}
