import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fiyatradar/models/price_reporting.dart';
import 'package:fiyatradar/services/basket_pricing_service.dart';

PriceGroupModel _group({
  required String chainName,
  required String productId,
  required double price,
  String confidence = 'high',
  DateTime? lastReportedAt,
}) {
  // PriceGroupModel.fromDoc kullanmak yerine doğrudan constructor — saf
  // unit test, Firebase bağlantısı yok.
  return PriceGroupModel(
    id: '${chainName}_$productId',
    productId: productId,
    productName: productId,
    chainId: chainName.toLowerCase(),
    chainName: chainName,
    cityId: 'adana',
    cityName: 'Adana',
    districtId: 'seyhan',
    districtName: 'Seyhan',
    latestPrice: price,
    trustedPrice: price,
    avgPrice: price,
    minPrice: price,
    maxPrice: price,
    reportCount: 5,
    verifiedCount: 3,
    photoReportCount: 1,
    confidence: confidence,
    sourceType: PriceReportSourceType.locationSupported,
    lastReportedAt: lastReportedAt,
  );
}

void main() {
  const svc = BasketPricingService();

  group('BasketPricingService.calculateSingleStoreTotals', () {
    test('coverage en yüksek market 1. sırada', () {
      final items = [
        (productId: 'milk', quantity: 1),
        (productId: 'bread', quantity: 1),
      ];
      final groups = [
        _group(chainName: 'A101', productId: 'milk', price: 15),
        _group(chainName: 'A101', productId: 'bread', price: 8),
        // BIM'de sadece milk var → coverage 50%, ucuz olsa bile loser.
        _group(chainName: 'BIM', productId: 'milk', price: 12),
      ];
      final result = svc.calculateSingleStoreTotals(
        items: items,
        groups: groups,
      );
      expect(result.first.chainName, 'A101');
      expect(result.first.foundItemCount, 2);
      expect(result.first.coverage, 1.0);
      expect(result.last.chainName, 'BIM');
      expect(result.last.coverage, 0.5);
    });

    test('30+ gün eski fiyatlı market loser konumuna düşer', () {
      final old = DateTime.now().subtract(const Duration(days: 45));
      final fresh = DateTime.now().subtract(const Duration(days: 2));
      final items = [(productId: 'milk', quantity: 1)];
      final groups = [
        _group(
          chainName: 'BIM',
          productId: 'milk',
          price: 10,
          lastReportedAt: old,
        ),
        _group(
          chainName: 'A101',
          productId: 'milk',
          price: 12,
          lastReportedAt: fresh,
        ),
      ];
      final result = svc.calculateSingleStoreTotals(
        items: items,
        groups: groups,
      );
      // Coverage eşit (1.0), fresh olan ileri sırada.
      expect(result.first.chainName, 'A101');
      expect(result.first.isStale, isFalse);
      expect(result.last.isStale, isTrue);
      expect(result.last.oldestPriceAgeDays, greaterThan(30));
    });
  });

  group('BasketPricingService.buildSmartSuggestion', () {
    test('küçük fark için tek market öner mesajı', () {
      final mixed = BasketMixedEstimate(
        estimatedTotal: 990,
        marketCount: 3,
        lines: const [],
      );
      final singles = [
        BasketStoreEstimate(
          chainName: 'A101',
          estimatedTotal: 1000,
          foundItemCount: 5,
          missingItemCount: 0,
          confidence: 'high',
          usedPriceSource: 'trustedPrice',
          missingProductIds: const [],
          oldestPriceAgeDays: 5,
        ),
      ];
      final s = svc.buildSmartSuggestion(singles: singles, mixed: mixed);
      expect(s, isNotNull);
      // 3+ market önerisi pratik değil → tek market vurgulanır.
      expect(s!.message, contains('pratik değil'));
    });

    test('büyük fark + 2 market için karma sepet öner', () {
      final mixed = BasketMixedEstimate(
        estimatedTotal: 800,
        marketCount: 2,
        lines: const [],
      );
      final singles = [
        BasketStoreEstimate(
          chainName: 'A101',
          estimatedTotal: 1000,
          foundItemCount: 5,
          missingItemCount: 0,
          confidence: 'high',
          usedPriceSource: 'trustedPrice',
          missingProductIds: const [],
          oldestPriceAgeDays: 5,
        ),
      ];
      final s = svc.buildSmartSuggestion(singles: singles, mixed: mixed);
      expect(s, isNotNull);
      // 2 market + ₺200 fark → split önerisi.
      expect(s!.message, contains('mantıklı'));
    });
  });
}
