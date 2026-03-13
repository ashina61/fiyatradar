import 'package:flutter_test/flutter_test.dart';
import 'package:fiyatradar/features/basket/basket_pricing.dart';

void main() {
  test('two markets, three items -> best single and mixed totals', () {
    final items = [
      const BasketItemInput(key: 'p1', name: 'Sut', quantity: 1),
      const BasketItemInput(key: 'p2', name: 'Ekmek', quantity: 2),
      const BasketItemInput(key: 'p3', name: 'Yag', quantity: 1),
    ];
    final pricesIndex = {
      'p1': {'m1': 10.0, 'm2': 12.0},
      'p2': {'m1': 4.0, 'm2': 3.0},
      'p3': {'m1': 20.0, 'm2': 19.0},
    };
    final summary = calculateBasketPricing(
      items: items,
      pricesIndex: pricesIndex,
      marketNames: const {'m1': 'Market 1', 'm2': 'Market 2'},
    );

    expect(summary.bestSingleMarket?.marketId, 'm2');
    expect(summary.bestSingleMarket?.total, 37);
    expect(summary.mixedResult.total, 36);
  });

  test('one market missing an item -> best single chooses other market', () {
    final items = [
      const BasketItemInput(key: 'p1', name: 'Sut', quantity: 1),
      const BasketItemInput(key: 'p2', name: 'Ekmek', quantity: 1),
    ];
    final pricesIndex = {
      'p1': {'m1': 10.0, 'm2': 11.0},
      'p2': {'m2': 5.0},
    };
    final summary = calculateBasketPricing(
      items: items,
      pricesIndex: pricesIndex,
      marketNames: const {'m1': 'Market 1', 'm2': 'Market 2'},
    );

    expect(summary.bestSingleMarket?.marketId, 'm2');
    expect(summary.bestSingleMarket?.total, 16);
    expect(summary.mixedResult.total, 15);
  });

  test('no market has full basket -> best single null, mixed computed', () {
    final items = [
      const BasketItemInput(key: 'p1', name: 'Sut', quantity: 1),
      const BasketItemInput(key: 'p2', name: 'Ekmek', quantity: 1),
    ];
    final pricesIndex = {
      'p1': {'m1': 10.0},
      'p2': {'m2': 6.0},
    };
    final summary = calculateBasketPricing(
      items: items,
      pricesIndex: pricesIndex,
      marketNames: const {'m1': 'Market 1', 'm2': 'Market 2'},
    );

    expect(summary.bestSingleMarket, isNull);
    expect(summary.mixedResult.total, 16);
    expect(summary.mixedResult.missingKeys, isEmpty);
  });

  test('equal prices across markets keeps deterministic best single market', () {
    final items = [
      const BasketItemInput(key: 'p1', name: 'Sut', quantity: 1),
    ];
    final pricesIndex = {
      'p1': {'m1': 10.0, 'm2': 10.0},
    };

    final summary = calculateBasketPricing(
      items: items,
      pricesIndex: pricesIndex,
      marketNames: const {'m1': 'Market 1', 'm2': 'Market 2'},
    );

    expect(summary.bestSingleMarket, isNotNull);
    expect(summary.bestSingleMarket?.total, 10);
  });

  test('missing product is reported in mixed result', () {
    final items = [
      const BasketItemInput(key: 'p1', name: 'Sut', quantity: 1),
      const BasketItemInput(key: 'p2', name: 'Ekmek', quantity: 1),
    ];
    final pricesIndex = {
      'p1': {'m1': 10.0},
      // p2 missing everywhere
    };

    final summary = calculateBasketPricing(
      items: items,
      pricesIndex: pricesIndex,
      marketNames: const {'m1': 'Market 1'},
    );

    expect(summary.bestSingleMarket, isNull);
    expect(summary.mixedResult.total, 10);
    expect(summary.mixedResult.missingKeys, ['p2']);
  });
}
