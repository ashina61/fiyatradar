import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/basket/cart_comparison_state.dart';
import '../../features/basket/basket_view_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/cart_comparison_service.dart';
import '../../utils/formatters.dart';
import '../add_price/add_price_screen.dart';
import 'fiyatradar_app.dart';
import 'tab_provider.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  String? _expandedStoreId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final activeTab = ref.watch(homeTabProvider);

    return auth.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Oturum bilgisi alınamadı.'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sepet için giriş yapmalısınız.'),
              ),
            ),
          );
        }

        final vm = ref.watch(basketViewModelProvider);

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.8,
                colors: [Color(0xFFFFFFFF), FRColors.background],
              ),
            ),
            child: Column(
              children: [
                _Header(activeTab: activeTab),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOut,
                    child: activeTab == HomeTab.sepet
                        ? _CartView(
                            key: const ValueKey('sepet'),
                            viewModel: vm,
                            onAddProduct: () => _showProductPicker(),
                            onCalculate: () => _triggerCalculate(),
                            onAddPrice: _navigateToAddPrice,
                          )
                        : _CompareView(
                            key: const ValueKey('karsilastir'),
                            pulseController: _pulseController,
                            state: vm.comparisonState,
                            onCalculate: () => _triggerCalculate(),
                            expandedStoreId: _expandedStoreId,
                            onToggleStore: (storeId) {
                              setState(() {
                                _expandedStoreId =
                                    _expandedStoreId == storeId ? null : storeId;
                              });
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _triggerCalculate() async {
    final vm = ref.read(basketViewModelProvider);
    if (vm.items.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Önce sepetine ürün ekle.')));
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Fiyatlar analiz ediliyor...')));

    await vm.calculate();
    if (!mounted) return;
    ref.read(homeTabProvider.notifier).setTab(HomeTab.karsilastir);
  }

  void _navigateToAddPrice(ProductModel? product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddPriceScreen()),
    );
  }

  Future<void> _showProductPicker() async {
    final vm = ref.read(basketViewModelProvider);
    final productsAsync = ref.read(allProductsProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final products = productsAsync.valueOrNull ?? const <ProductModel>[];
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: productsAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                      ? const Center(child: Text('Eklenebilir ürün bulunamadı.'))
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.all(20),
                          itemBuilder: (_, index) {
                            final p = products[index];
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              tileColor: FRColors.background,
                              title: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(p.brand.isNotEmpty ? p.brand : 'Marka yok'),
                              trailing: const Icon(Icons.add_circle_outline),
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                await vm.addProduct(p.id);
                                if (!mounted) return;
                                Navigator.of(context).pop();
                              },
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemCount: products.length,
                        ),
            );
          },
        );
      },
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.activeTab});

  final HomeTab activeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
          decoration: BoxDecoration(
            color: FRColors.background.withOpacity(0.9),
            border: Border(
              bottom: BorderSide(
                color: FRColors.primary.withOpacity(0.06),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: FRColors.primary, width: 4),
                  ),
                ),
                child: Text(
                  'Sepetim',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: FRColors.dark,
                      ),
                ),
              ),
              const SizedBox(height: 18),
              _CustomTab(activeTab: activeTab),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomTab extends ConsumerWidget {
  const _CustomTab({required this.activeTab});

  final HomeTab activeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = (constraints.maxWidth - 10) / 2;
        return Container(
          height: 50,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: FRColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: activeTab == HomeTab.sepet ? 0 : tabWidth,
                child: Container(
                  width: tabWidth,
                  height: 40,
                  decoration: BoxDecoration(
                    color: FRColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: FRColors.primary.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _TabButton(
                    text: 'Sepet',
                    active: activeTab == HomeTab.sepet,
                    onTap: () =>
                        ref.read(homeTabProvider.notifier).setTab(HomeTab.sepet),
                  ),
                  _TabButton(
                    text: 'Karşılaştır',
                    active: activeTab == HomeTab.karsilastir,
                    onTap: () => ref
                        .read(homeTabProvider.notifier)
                        .setTab(HomeTab.karsilastir),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.text,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: active ? FRColors.primary : FRColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView({
    super.key,
    required this.viewModel,
    required this.onAddProduct,
    required this.onCalculate,
    required this.onAddPrice,
  });

  final BasketViewModel viewModel;
  final VoidCallback onAddProduct;
  final VoidCallback onCalculate;
  final void Function(ProductModel? product) onAddPrice;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoadingItems) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = viewModel.items;
    final estimated = viewModel.computedEstimatedTotal;
    final totalProducts = items.fold<int>(0, (sum, item) => sum + item.quantity);

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 42, color: FRColors.muted),
              const SizedBox(height: 12),
              const Text('Sepetin şu an boş'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: onAddProduct,
                child: const Text('Ürün Ekle'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _surfaceDecoration(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryItem(Icons.shopping_bag_rounded, '$totalProducts Ürün'),
              Container(width: 1, height: 24, color: FRColors.primary.withOpacity(0.1)),
              _summaryItem(
                Icons.payments_rounded,
                '${formatTRY(estimated.total, keepTrailingZeros: true)} Tahmini',
                iconColor: FRColors.gold,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alışveriş Listeniz',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: FRColors.dark,
                  ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [FRColors.gold, FRColors.primary]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: FRColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextButton.icon(
                onPressed: onAddProduct,
                icon: const Icon(Icons.add_circle, color: FRColors.surface),
                label: const Text('Ürün Ekle'),
                style: TextButton.styleFrom(
                  foregroundColor: FRColors.surface,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ...items.map((item) {
          final product = viewModel.productMap[item.productId];
          final name = product?.name ?? 'Ürün';
          final image = product?.effectiveImage;
          final hasPrice = item.lastKnownPrice != null;
          final linePrice = hasPrice ? item.lastKnownPrice! * item.quantity : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _surfaceDecoration(24),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 85,
                      height: 85,
                      color: FRColors.background,
                      child: image == null || image.isEmpty
                          ? const Icon(Icons.image_not_supported_outlined, color: FRColors.muted)
                          : Image.network(image, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: FRColors.dark,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                hasPrice
                                    ? formatTRY(linePrice!, keepTrailingZeros: true)
                                    : 'Fiyat bilgisi yok',
                                style: TextStyle(
                                  color: hasPrice ? FRColors.primary : FRColors.muted,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: FRColors.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () => viewModel.updateQuantity(
                                      item.productId,
                                      item.quantity - 1,
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    color: FRColors.danger,
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  IconButton(
                                    onPressed: () => viewModel.updateQuantity(
                                      item.productId,
                                      item.quantity + 1,
                                    ),
                                    icon: const Icon(Icons.add),
                                    color: FRColors.dark,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => onAddPrice(product),
                              child: const Text('Fiyat Ekle'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (estimated.hasMissingPrices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${estimated.missingPriceCount} üründe fiyat bilgisi eksik. Yine de hesaplanır.',
              style: const TextStyle(color: FRColors.warning),
            ),
          ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onCalculate,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: FRColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: FRColors.primary.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'En Uygunu Bul',
                  style: TextStyle(
                    color: FRColors.surface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.east_rounded, color: FRColors.surface),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? FRColors.muted, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: FRColors.dark,
          ),
        ),
      ],
    );
  }
}

class _CompareView extends StatelessWidget {
  const _CompareView({
    super.key,
    required this.pulseController,
    required this.state,
    required this.onCalculate,
    required this.expandedStoreId,
    required this.onToggleStore,
  });

  final AnimationController pulseController;
  final CartComparisonState state;
  final VoidCallback onCalculate;
  final String? expandedStoreId;
  final ValueChanged<String> onToggleStore;

  @override
  Widget build(BuildContext context) {
    if (state.status == CartComparisonStatus.idle) {
      return Center(
        child: FilledButton.icon(
          onPressed: onCalculate,
          icon: const Icon(Icons.calculate),
          label: const Text('Sepeti Hesapla'),
        ),
      );
    }

    if (state.status == CartComparisonStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == CartComparisonStatus.error) {
      return Center(
        child: Text(state.errorMessage ?? 'Karşılaştırma yapılırken hata oluştu.'),
      );
    }

    final markets = [...state.topMarkets];
    if (markets.isEmpty) {
      return Center(
        child: Text(state.emptyReason ?? 'Karşılaştıracak market verisi bulunamadı.'),
      );
    }

    final winner = state.bestMarket ?? markets.first;
    final winnerTotal = winner.totalPrice;
    final savings = markets.length > 1 ? (markets[1].totalPrice - winnerTotal) : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [FRColors.dark, FRColors.primary],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: FRColors.dark.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: FRColors.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, size: 16, color: FRColors.dark),
                        SizedBox(width: 6),
                        Text(
                          'EN UYGUN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: FRColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: pulseController,
                    builder: (context, child) {
                      final scale = 1 + (pulseController.value * 0.03);
                      final glow = 10 + (pulseController.value * 15);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: FRColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: FRColors.gold, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: FRColors.surface.withOpacity(0.8),
                                blurRadius: glow,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.savings, size: 18, color: FRColors.gold),
                              const SizedBox(width: 6),
                              Text(
                                '${formatTRY(savings < 0 ? 0 : savings)} KAZANÇ',
                                style: const TextStyle(
                                  color: FRColors.dark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          winner.storeName,
                          style: const TextStyle(
                            color: FRColors.surface,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_distanceLabel(winner.distanceKm)} • ${winner.missingCount == 0 ? 'Tüm ürünler var' : '${winner.missingCount} eksik'}',
                          style: TextStyle(
                            color: FRColors.surface.withOpacity(0.72),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatTRY(winner.totalPrice),
                    style: const TextStyle(
                      color: FRColors.surface,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: FRColors.surface,
                    foregroundColor: FRColors.dark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${winner.storeName} rotası hazırlanıyor...')),
                    );
                  },
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('Markete Git'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Alternatif Marketler',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: FRColors.dark,
              ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: _surfaceDecoration(28),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: markets
                .asMap()
                .entries
                .where((entry) => entry.value.storeId != winner.storeId)
                .map((entry) {
              final rank = entry.key + 1;
              final market = entry.value;
              final expanded = expandedStoreId == market.storeId;
              final difference = market.totalPrice - winner.totalPrice;

              return InkWell(
                onTap: () => onToggleStore(market.storeId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: market.missingCount > 0
                                      ? FRColors.danger.withOpacity(0.1)
                                      : (expanded
                                          ? FRColors.gold
                                          : FRColors.primary.withOpacity(0.06)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  market.missingCount > 0 ? '!' : '$rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: market.missingCount > 0
                                        ? FRColors.danger
                                        : (expanded ? FRColors.dark : FRColors.muted),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    market.storeName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: FRColors.dark,
                                    ),
                                  ),
                                  Text(
                                    '${_distanceLabel(market.distanceKm)} • ${market.missingCount == 0 ? 'Eksik Yok' : '${market.missingCount} Eksik'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: market.missingCount > 0 ? FRColors.danger : FRColors.muted,
                                      fontWeight: market.missingCount > 0 ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatTRY(market.totalPrice),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: FRColors.dark,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: market.missingCount > 0
                                      ? FRColors.danger.withOpacity(0.1)
                                      : FRColors.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  market.missingCount > 0
                                      ? 'Stok Yok'
                                      : '+${formatTRY(difference)} Fark',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: market.missingCount > 0 ? FRColors.danger : FRColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: _DetailRows(market: market, winner: winner),
                        crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 250),
                      ),
                      if (entry.key != markets.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Divider(color: FRColors.primary.withOpacity(0.06), height: 1),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _distanceLabel(double? km) {
    if (km == null) return 'Mesafe yok';
    return '${km.toStringAsFixed(1)} km';
  }
}

class _DetailRows extends StatelessWidget {
  const _DetailRows({required this.market, required this.winner});

  final CartMarketResultSummary market;
  final CartMarketResultSummary winner;

  @override
  Widget build(BuildContext context) {
    final winnerMap = {
      for (final line in winner.lines) line.productId: line,
    };

    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.only(top: 15),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: FRColors.primary.withOpacity(0.12),
            style: BorderStyle.solid,
          ),
        ),
      ),
      child: Column(
        children: [
          for (final line in market.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      line.productName,
                      style: const TextStyle(fontSize: 13, color: FRColors.dark),
                    ),
                  ),
                  _lineBadge(line, winnerMap[line.productId]),
                ],
              ),
            ),
          if (market.missingCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: FRColors.danger, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${market.missingCount} ürün bu markette bulunamadı.',
                    style: const TextStyle(color: FRColors.danger, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _lineBadge(CartMarketProductPrice line, CartMarketProductPrice? bestLine) {
    final diff = bestLine == null ? 0.0 : (line.unitPrice - bestLine.unitPrice);
    final same = diff.abs() < 0.005;

    if (same) {
      return Text(
        '${formatTRY(line.unitPrice)} (Aynı)',
        style: const TextStyle(fontSize: 12, color: FRColors.muted, fontWeight: FontWeight.w600),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FRColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${formatTRY(line.unitPrice)} (+${formatTRY(diff)})',
        style: const TextStyle(fontSize: 12, color: FRColors.danger, fontWeight: FontWeight.w800),
      ),
    );
  }
}

BoxDecoration _surfaceDecoration(double radius) {
  return BoxDecoration(
    color: FRColors.surface,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: FRColors.primary.withOpacity(0.04),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
    border: Border.all(color: FRColors.primary.withOpacity(0.03)),
  );
}
