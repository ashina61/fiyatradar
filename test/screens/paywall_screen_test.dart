import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:fiyatradar/screens/paywall_screen.dart';
import 'package:fiyatradar/services/premium_service.dart';
import 'package:fiyatradar/state/app_state.dart';
import 'package:fiyatradar/ui/components.dart';

/// In-memory stand-in for [PremiumService]. Extends the real type via the
/// `protected` test constructor so it can be injected into [PaywallScreen]
/// without ever touching Play Billing or Firebase, and overrides every member
/// the paywall reads. Each scenario is built with [configure].
class FakePremiumService extends PremiumService {
  FakePremiumService() : super.protected();

  bool fAvailable = true;
  bool fLoading = false;
  bool fQueried = true;
  String? fError;
  List<ProductDetails> fProducts = const [];
  String? fMonthlyRecurring;
  String? fYearlyRecurring;

  int purchaseCalls = 0;
  ProductDetails? lastPurchased;
  int restoreCalls = 0;
  int reloadCalls = 0;

  @override
  bool get available => fAvailable;
  @override
  bool get loadingProducts => fLoading;
  @override
  bool get productsQueried => fQueried;
  @override
  String? get productsError => fError;
  @override
  List<ProductDetails> get availableProducts => fProducts;
  @override
  bool get hasPurchasableProducts => fProducts.isNotEmpty;
  @override
  String? get monthlyRecurringPrice => fMonthlyRecurring;
  @override
  String? get yearlyRecurringPrice => fYearlyRecurring;
  @override
  ProductDetails? get monthlyProduct => _find(PremiumService.monthlySku);
  @override
  ProductDetails? get yearlyProduct => _find(PremiumService.yearlySku);

  ProductDetails? _find(String id) {
    for (final p in fProducts) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<bool> purchase(ProductDetails product) async {
    purchaseCalls++;
    lastPurchased = product;
    return true;
  }

  @override
  Future<void> restore() async {
    restoreCalls++;
  }

  @override
  Future<void> reloadProducts() async {
    reloadCalls++;
  }

  @override
  Future<void> init() async {}
}

ProductDetails _product(String id, String price) => ProductDetails(
      id: id,
      title: id,
      description: id,
      price: price,
      rawPrice: 0,
      currencyCode: 'TRY',
    );

/// Footer copy below the CTA — depends ONLY on the selected plan, so it is the
/// most reliable observable of the plan toggle across every product state.
const _yearlyFooter = '7 gün sonra yıllık abonelik başlar';
const _monthlyFooter = 'Aboneliğin Play Store\'da yönetilir';

void main() {
  setUpAll(() {
    // No network in tests; keep google_fonts from attempting HTTP fetches.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpPaywall(
    WidgetTester tester,
    FakePremiumService fake,
  ) async {
    // Tall surface so the whole ListView (debug panel + hero + benefits +
    // toggle + CTA + footer) lays out and every control is hit-testable.
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: AppState(),
          child: PaywallScreen(service: fake),
        ),
      ),
    );
    // One frame to run initState + first build. Never pumpAndSettle: the
    // loading skeleton animates forever.
    await tester.pump();
  }

  FRCta ctaWidget(WidgetTester tester) =>
      tester.widget<FRCta>(find.byType(FRCta));

  bool ctaEnabled(WidgetTester tester) => ctaWidget(tester).onTap != null;

  // FRCta wraps its InkWell in AnimatedScale/AnimatedOpacity, so a center tap
  // lands on a descendant RenderObject rather than the FRCta box itself and
  // trips warnIfMissed. The handler still fires; each call site asserts the
  // real effect (purchaseCalls), so the cosmetic warning is suppressed.
  Future<void> tapCta(WidgetTester tester) async {
    await tester.tap(find.byType(FRCta), warnIfMissed: false);
    await tester.pump();
  }

  group('PaywallScreen — products loaded', () {
    FakePremiumService loaded() => FakePremiumService()
      ..fAvailable = true
      ..fLoading = false
      ..fQueried = true
      ..fProducts = [
        _product(PremiumService.monthlySku, '₺49,99'),
        _product(PremiumService.yearlySku, '₺299,99'),
      ]
      ..fMonthlyRecurring = '₺49,99'
      ..fYearlyRecurring = '₺299,99';

    testWidgets('CTA is enabled and visible', (tester) async {
      final fake = loaded();
      await pumpPaywall(tester, fake);

      expect(find.byType(FRCta), findsOneWidget);
      expect(ctaEnabled(tester), isTrue);
    });

    testWidgets('tapping CTA invokes purchase with the selected (yearly) plan',
        (tester) async {
      final fake = loaded();
      await pumpPaywall(tester, fake);

      await tapCta(tester);

      expect(fake.purchaseCalls, 1);
      expect(fake.lastPurchased?.id, PremiumService.yearlySku);
    });

    testWidgets('plan toggle switches the active plan', (tester) async {
      final fake = loaded();
      await pumpPaywall(tester, fake);

      // Default = yearly.
      expect(find.textContaining(_yearlyFooter), findsOneWidget);
      expect(find.textContaining(_monthlyFooter), findsNothing);

      await tester.tap(find.text('Aylık'));
      await tester.pump();
      expect(find.textContaining(_monthlyFooter), findsOneWidget);

      // Buying now targets the monthly SKU.
      await tapCta(tester);
      expect(fake.lastPurchased?.id, PremiumService.monthlySku);

      await tester.tap(find.text('Yıllık'));
      await tester.pump();
      expect(find.textContaining(_yearlyFooter), findsOneWidget);
    });

    testWidgets('Restore invokes restore()', (tester) async {
      final fake = loaded();
      await pumpPaywall(tester, fake);

      await tester.tap(find.text('Restore'));
      await tester.pump();

      expect(fake.restoreCalls, 1);
    });
  });

  group('PaywallScreen — products loading', () {
    FakePremiumService loading() => FakePremiumService()
      ..fAvailable = true
      ..fLoading = true
      ..fQueried = false
      ..fProducts = const []
      ..fMonthlyRecurring = null
      ..fYearlyRecurring = null;

    testWidgets('CTA is disabled but still rendered', (tester) async {
      final fake = loading();
      await pumpPaywall(tester, fake);

      expect(find.byType(FRCta), findsOneWidget);
      expect(ctaEnabled(tester), isFalse);
    });

    testWidgets('plan toggle stays interactive while loading', (tester) async {
      final fake = loading();
      await pumpPaywall(tester, fake);

      await tester.tap(find.text('Aylık'));
      await tester.pump();
      expect(find.textContaining(_monthlyFooter), findsOneWidget);
    });

    testWidgets('Restore stays interactive while loading', (tester) async {
      final fake = loading();
      await pumpPaywall(tester, fake);

      await tester.tap(find.text('Restore'));
      await tester.pump();
      expect(fake.restoreCalls, 1);
    });
  });

  group('PaywallScreen — products error', () {
    FakePremiumService errored() => FakePremiumService()
      ..fAvailable = true
      ..fLoading = false
      ..fQueried = true
      ..fProducts = const []
      ..fError = 'Ürünler yüklenemedi, internet bağlantını kontrol et.'
      ..fMonthlyRecurring = null
      ..fYearlyRecurring = null;

    testWidgets('CTA disabled and retry button is shown and tappable',
        (tester) async {
      final fake = errored();
      await pumpPaywall(tester, fake);

      expect(ctaEnabled(tester), isFalse);

      final retry = find.text('Tekrar dene');
      expect(retry, findsOneWidget);

      await tester.tap(retry);
      await tester.pump();
      expect(fake.reloadCalls, 1);
    });
  });

  group('PaywallScreen — products empty (store unavailable)', () {
    FakePremiumService empty() => FakePremiumService()
      ..fAvailable = false
      ..fLoading = false
      ..fQueried = true
      ..fProducts = const []
      ..fError =
          'Mağaza bağlantısı kullanılamıyor. Play Store hesabını kontrol et.'
      ..fMonthlyRecurring = null
      ..fYearlyRecurring = null;

    testWidgets('CTA disabled and error/retry state shown', (tester) async {
      final fake = empty();
      await pumpPaywall(tester, fake);

      expect(ctaEnabled(tester), isFalse);
      expect(find.text('Tekrar dene'), findsOneWidget);
      expect(find.text('Mağaza hazır değil'), findsOneWidget);
    });

    testWidgets('Restore bails (no store, nothing cached) without calling restore',
        (tester) async {
      final fake = empty();
      await pumpPaywall(tester, fake);

      await tester.tap(find.text('Restore'));
      await tester.pump();
      expect(fake.restoreCalls, 0);
    });
  });

  // The regression that motivated this sprint: a reload race leaves
  // `available == false` while products + recurring prices are still cached.
  // The CTA, plan toggle, purchase and restore must all keep working — they
  // must NOT gate on the stale `available` flag.
  group('PaywallScreen — cached-but-unavailable regression', () {
    FakePremiumService cached() => FakePremiumService()
      ..fAvailable = false // stale-false
      ..fLoading = false
      ..fQueried = true
      ..fProducts = [
        _product(PremiumService.monthlySku, '₺49,99'),
        _product(PremiumService.yearlySku, '₺299,99'),
      ]
      ..fMonthlyRecurring = '₺49,99'
      ..fYearlyRecurring = '₺299,99';

    testWidgets('CTA is enabled despite available == false', (tester) async {
      final fake = cached();
      await pumpPaywall(tester, fake);

      expect(ctaEnabled(tester), isTrue);
      // Prices render, so the store-unavailable error card must NOT show.
      expect(find.text('Tekrar dene'), findsNothing);
      expect(find.text('Mağaza hazır değil'), findsNothing);
    });

    testWidgets('tapping CTA still starts a purchase', (tester) async {
      final fake = cached();
      await pumpPaywall(tester, fake);

      await tapCta(tester);

      expect(fake.purchaseCalls, 1);
      expect(fake.lastPurchased?.id, PremiumService.yearlySku);
    });

    testWidgets('plan toggle still works', (tester) async {
      final fake = cached();
      await pumpPaywall(tester, fake);

      await tester.tap(find.text('Aylık'));
      await tester.pump();
      expect(find.textContaining(_monthlyFooter), findsOneWidget);
    });

    testWidgets('Restore still calls restore() (not gated on stale available)',
        (tester) async {
      final fake = cached();
      await pumpPaywall(tester, fake);

      await tester.tap(find.text('Restore'));
      await tester.pump();

      expect(fake.restoreCalls, 1);
    });
  });
}
