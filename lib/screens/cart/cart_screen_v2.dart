import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/basket/basket_view_model.dart';
import '../../features/basket/cart_comparison_state.dart';
import '../../models/basket_item_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../services/cart_comparison_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../add_price/add_price_screen.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/premium_scaffold_shell.dart';
import '../../theme/fr_colors.dart';
import '../../theme/fr_radius.dart';
import '../../theme/fr_spacing.dart';
import '../../theme/fr_typography.dart';
import 'cart_result_tab.dart';

class CartScreenV2 extends ConsumerStatefulWidget {
  const CartScreenV2({super.key});

  @override
  ConsumerState<CartScreenV2> createState() => _CartScreenV2State();
}

class _CartScreenV2State extends ConsumerState<CartScreenV2>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const _LoginPromptCard();

        final viewModel = ref.watch(basketViewModelProvider);
        final itemCount = ref.watch(basketViewModelProvider.select((vm) => vm.items.fold<int>(0, (s, i) => s + i.quantity)));
        final estimatedTotal = ref.watch(basketViewModelProvider.select((vm) => vm.computedEstimatedTotal));

        return Scaffold(
          backgroundColor: FRColors.background,
          // AppBar'ı iptal ettik, Porsche Header'ı Body'nin içine entegre ediyoruz.
          body: Column(
            children: [
              // 💥 İŞTE YENİ PORSCHE HEADER (AnimatedBuilder ile Performanslı) 💥
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  return _PremiumCartHeader(
                    selectedIndex: _tabController.index,
                    onChanged: (index) => _tabController.animateTo(index),
                  );
                },
              ),

              // 💥 İÇERİK KISMI 💥
              Expanded(
                child: PremiumScaffoldShell(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(), // Kaydırmayı kapattık, menüden geçilecek
                    children: [
                      // ── Tab 1: Sepetim ──
                      _CartBody(
                        viewModel: viewModel,
                        itemCount: itemCount,
                        estimatedTotal: estimatedTotal,
                        onAddProduct: () => _showProductPicker(context, viewModel),
                        onAddPrice: (product) => _navigateToAddPrice(context, product),
                        onCalculate: () => _handleCalculate(viewModel),
                      ),
                      // ── Tab 2: Karşılaştır ──
                      CartResultTab(
                        state: viewModel.comparisonState,
                        onCalculate: () => _handleCalculate(viewModel),
                        onGoToCart: () => _tabController.animateTo(0),
                        onAddPrice: () => _navigateToAddPrice(context, null),
                        onRetry: () => _handleCalculate(viewModel),
                        onSelectStores: () => _showStoreFilterSheet(context, viewModel),
                        selectedStoreNames: viewModel.selectedStoreNames,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: FRColors.camelDeep))),
      error: (_, __) => const Scaffold(body: SizedBox.shrink()),
    );
  }

  // ---------------------------------------------------------------------------
  // EYLEM METOTLARI (Logic aynı kaldı)
  // ---------------------------------------------------------------------------
  Future<void> _handleCalculate(BasketViewModel viewModel) async {
    if (viewModel.items.isEmpty) {
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(content: const Text('Hesaplama için en az bir ürün ekleyin.'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: FRRadius.all(12))),
        );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [Icon(Icons.check_circle, color: FRColors.camelStrong), SizedBox(width: 8), Text("Fiyatlar analiz ediliyor...", style: TextStyle(color: FRColors.camelStrong, fontWeight: FontWeight.bold))]),
        backgroundColor: FRColors.espressoSoft, duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: FRRadius.all(100)),
      ),
    );
    HapticFeedback.mediumImpact();
    await viewModel.calculate();

    if (!mounted) return;
    if (viewModel.comparisonState.status != CartComparisonStatus.loading && viewModel.comparisonState.status != CartComparisonStatus.idle) {
      Future.delayed(const Duration(milliseconds: 300), () { _tabController.animateTo(1); });
    }
  }

  void _navigateToAddPrice(BuildContext context, ProductModel? product) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AddPriceScreen()));
  }

  Future<void> _showStoreFilterSheet(BuildContext context, BasketViewModel viewModel) async {
    await viewModel.loadStoresIfNeeded();
    if (!context.mounted) return;
    final initialSelection = Set<String>.from(viewModel.selectedStoreIds);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FRColors.white.withOpacity(0),
      builder: (ctx) {
        final tempSelection = Set<String>.from(initialSelection);
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildStoreList(List<StoreModel> stores) {
              if (stores.isEmpty) return const Center(child: Text('Mağaza bulunamadı.', style: TextStyle(fontWeight: FontWeight.bold)));
              return ListView.separated(
                padding: FRSpaceInsets.symmetric(vertical: 8), itemCount: stores.length, separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, index) {
                  final store = stores[index]; final isSelected = tempSelection.contains(store.id);
                  return Container(
                    margin: FRSpaceInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: isSelected ? FRColors.camelDeep.withOpacity(0.1) : FRColors.white.withOpacity(0), borderRadius: FRRadius.all(14)),
                    child: CheckboxListTile(
                      activeColor: FRColors.camelDeep, value: isSelected, shape: RoundedRectangleBorder(borderRadius: FRRadius.all(14)),
                      title: Text(store.displayName, style: _t(fontWeight: FontWeight.bold, color: FRColors.espressoSoft)),
                      subtitle: Text(store.isOnline ? 'Online' : [store.neighborhood, store.district].where((e) => e.isNotEmpty).join(', '), style: _t(color: FRColors.textMuted)),
                      onChanged: (val) { setModalState(() { if (val == true) tempSelection.add(store.id); else tempSelection.remove(store.id); }); },
                    ),
                  );
                },
              );
            }

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75, decoration: const BoxDecoration(color: FRColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const SizedBox(height: 12), Container(width: 40, height: 4, decoration: BoxDecoration(color: FRColors.camelOverlay(0.25), borderRadius: FRRadius.all(2))),
                    Padding(
                      padding: FRSpaceInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const Expanded(child: Text('Mağaza Seç', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: FRColors.espressoSoft))),
                          Container(padding: FRSpaceInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: FRColors.camelDeep.withOpacity(0.1), borderRadius: FRRadius.all(20)), child: Text('${tempSelection.length} seçili', style: _t(color: FRColors.camelDeep, fontWeight: FontWeight.w800))),
                        ],
                      ),
                    ),
                    Padding(padding: FRSpaceInsets.symmetric(horizontal: 20), child: const TabBar(indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent, labelColor: FRColors.camelDeep, unselectedLabelColor: FRColors.textMuted, tabs: [Tab(text: 'Yakınımda'), Tab(text: 'Online')])),
                    Expanded(child: Padding(padding: FRSpaceInsets.symmetric(horizontal: 12), child: TabBarView(children: [buildStoreList(viewModel.nearbyStores), buildStoreList(viewModel.onlineStores)]))),
                    SafeArea(
                      child: Padding(
                        padding: FRSpaceInsets.fromLTRB(20, 8, 20, 16),
                        child: SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: () { viewModel.setSelectedStoreIds(Set<String>.from(tempSelection)); if (Navigator.canPop(ctx)) Navigator.of(ctx).pop(); }, style: FilledButton.styleFrom(backgroundColor: FRColors.camelDeep, shape: RoundedRectangleBorder(borderRadius: FRRadius.all(16))), child: const Text('Uygula', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProductPicker(BuildContext context, BasketViewModel viewModel) {
    // Aynı product picker bottom sheet kodun
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: FRColors.white.withOpacity(0),
      builder: (ctx) {
        final controller = TextEditingController();
        return StatefulBuilder(
          builder: (_, setModalState) {
            final query = controller.text.trim().toLowerCase();
            final allProducts = ref.watch(allProductsProvider).valueOrNull ?? [];
            final filtered = allProducts.where((p) => query.isEmpty || p.name.toLowerCase().contains(query) || p.brand.toLowerCase().contains(query)).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.80, decoration: const BoxDecoration(color: FRColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                children: [
                  const SizedBox(height: 12), Container(width: 40, height: 4, decoration: BoxDecoration(color: FRColors.camelOverlay(0.25), borderRadius: FRRadius.all(2))),
                  Padding(
                    padding: FRSpaceInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ürün Ekle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: FRColors.espressoSoft)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller, onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(hintText: 'Ürün veya marka ara...', prefixIcon: const Icon(Icons.search_rounded, color: FRColors.textMuted), suffixIcon: query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { controller.clear(); setModalState(() {}); }) : null, filled: true, fillColor: FRColors.background, border: OutlineInputBorder(borderRadius: FRRadius.all(14), borderSide: BorderSide.none), contentPadding: FRSpaceInsets.symmetric(horizontal: 16, vertical: 14)),
                        ),
                      ],
                    ),
                  ),
                  if (filtered.isEmpty) const Expanded(child: Center(child: Text('Ürün bulunamadı', style: TextStyle(fontWeight: FontWeight.bold, color: FRColors.espressoSoft))))
                  else Expanded(
                    child: ListView.separated(
                      padding: FRSpaceInsets.fromLTRB(12, 4, 12, 16), itemCount: filtered.length, separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (_, index) {
                        final product = filtered[index]; final hasPrice = product.lastPrice != null;
                        return Material(
                          color: FRColors.white.withOpacity(0),
                          child: InkWell(
                            borderRadius: FRRadius.all(14),
                            onTap: () { HapticFeedback.selectionClick(); viewModel.addProduct(product.id); if (Navigator.canPop(ctx)) Navigator.pop(ctx); },
                            child: Padding(
                              padding: FRSpaceInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Row(
                                children: [
                                  AppNetworkImage(imageUrl: product.mainImage, cacheKey: product.id, width: 50, height: 50, fit: BoxFit.cover, borderRadius: FRRadius.all(12)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(fontWeight: FontWeight.bold, color: FRColors.espressoSoft)),
                                        const SizedBox(height: 2), Text(product.brand.isNotEmpty ? product.brand : 'Marka bilgisi yok', style: _t(fontSize: 12, color: FRColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                  if (hasPrice) Container(padding: FRSpaceInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: FRColors.camelDeep.withOpacity(0.1), borderRadius: FRRadius.all(8)), child: Text(formatTRY(product.lastPrice!), style: _t(color: FRColors.camelDeep, fontWeight: FontWeight.w800))),
                                  const SizedBox(width: 8), Container(padding: FRSpaceInsets.all(6), decoration: const BoxDecoration(color: FRColors.camelDeep, shape: BoxShape.circle), child: const Icon(Icons.add_rounded, size: 18, color: FRColors.white)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🏎️ YEPYENİ PREMIUM PORSCHE HEADER (Karanlık ve Overlap Tasarım)
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumCartHeader extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;

  const _PremiumCartHeader({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: FRSpaceInsets.only(bottom: 26), // Üzerine binen menünün altındaki listeyi ezmemesi için boşluk
      child: Stack(
        clipBehavior: Clip.none, 
        alignment: Alignment.bottomCenter,
        children: [
          // 💥 1. ZİFİRİ KARANLIK LÜKS BAŞLIK 💥
          Container(
            width: double.infinity,
            padding: FRSpaceInsets.only(
              top: MediaQuery.of(context).padding.top + 16, 
              bottom: 44, // Alt menüye yer açıyoruz
              left: 20, right: 20,
            ),
            decoration: const BoxDecoration(
              color: FRColors.espressoSoft,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
              boxShadow: [BoxShadow(color: FRColors.shadowStrong, blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Row(
              children: [
                // Geri Butonu
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: FRColors.espresso, borderRadius: FRRadius.all(14)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: FRColors.white, size: 20),
                  ),
                ),
                // Ortalanmış Başlık
                const Expanded(
                  child: Center(
                    child: Text('Sepetim', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: FRColors.white, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(width: 44), // Simetri için boşluk
              ],
            ),
          ),

          // 💥 2. KESİŞİM MENÜSÜ (Havada Asılı Duran Karamel Kadran) 💥
          Positioned(
            bottom: -26, // Karanlık ve aydınlığın tam kesişimi
            left: 24, right: 24,
            child: Container(
              height: 52, padding: FRSpaceInsets.all(4),
              decoration: BoxDecoration(
                color: FRColors.white, borderRadius: FRRadius.all(100),
                boxShadow: [BoxShadow(color: FRColors.camelOverlay(0.10), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Stack(
                children: [
                  // Hareket Eden Karamel Kutu
                  AnimatedAlign(
                    alignment: selectedIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: FRColors.camelDeep, borderRadius: FRRadius.all(100),
                          boxShadow: [BoxShadow(color: FRColors.camelDeep.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                      ),
                    ),
                  ),
                  // Tuş Metinleri
                  Row(
                    children: [
                      _buildSegmentBtn('Sepet', 0),
                      _buildSegmentBtn('Karşılaştır', 1),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBtn(String title, int index) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(index);
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
              color: isSelected ? FRColors.white : FRColors.textMuted,
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// ALT SAYFALAR (_CartBody VE EKLENTİLERİ AYNI KALDI, SADECE RENKLER PORSCHE)
// ─────────────────────────────────────────────────────────────────────────────

class _CartBody extends StatefulWidget {
  const _CartBody({required this.viewModel, required this.itemCount, required this.estimatedTotal, required this.onAddProduct, required this.onAddPrice, required this.onCalculate});
  final BasketViewModel viewModel; final int itemCount; final BasketEstimatedTotal estimatedTotal; final VoidCallback onAddProduct; final void Function(ProductModel? product) onAddPrice; final VoidCallback onCalculate;

  @override
  State<_CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<_CartBody> {
  @override
  Widget build(BuildContext context) {
    if (widget.viewModel.isLoadingItems) return Center(child: Padding(padding: FRSpaceInsets.all(48), child: const CircularProgressIndicator(color: FRColors.camelDeep)));
    if (widget.viewModel.items.isEmpty) return _EmptyCartView(onAdd: widget.onAddProduct);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: FRSpaceInsets.fromLTRB(24, 10, 24, 24),
            physics: const BouncingScrollPhysics(),
            children: [
              _StatsHeader(itemCount: widget.itemCount, estimatedTotal: widget.estimatedTotal),
              const SizedBox(height: 24),
              _SectionLabel(label: 'Alışveriş Listeniz', onAddProduct: widget.onAddProduct),
              const SizedBox(height: 15),
              ...widget.viewModel.items.asMap().entries.map((entry) {
                final index = entry.key; final item = entry.value; final product = widget.viewModel.productMap[item.productId];
                return TweenAnimationBuilder<double>(
                  key: ValueKey(item.productId), tween: Tween(begin: 0, end: 1), duration: Duration(milliseconds: 300 + (index * 50)), curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child)),
                  child: Padding(
                    padding: FRSpaceInsets.only(bottom: 14),
                    child: Dismissible(
                      key: ValueKey('dismiss_${item.productId}'), direction: DismissDirection.endToStart,
                      onDismissed: (_) { HapticFeedback.mediumImpact(); widget.viewModel.updateQuantity(item.productId, 0); },
                      background: Container(alignment: Alignment.centerRight, padding: FRSpaceInsets.only(right: 24), decoration: BoxDecoration(color: FRColors.danger, borderRadius: FRRadius.all(24)), child: const Icon(Icons.delete_outline_rounded, color: FRColors.white, size: 28)),
                      child: _CartProductCard(item: item, product: product, onQuantityChanged: (qty) => widget.viewModel.updateQuantity(item.productId, qty), onRemove: () => widget.viewModel.updateQuantity(item.productId, 0), onAddPrice: () => widget.onAddPrice(product)),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        _CartActionBar(itemCount: widget.itemCount, estimatedTotal: widget.estimatedTotal, isLoading: widget.viewModel.isCalculating, onCalculate: widget.onCalculate),
      ],
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.itemCount, required this.estimatedTotal});
  final int itemCount; final BasketEstimatedTotal estimatedTotal;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: FRSpaceInsets.all(16),
      decoration: BoxDecoration(color: FRColors.white, borderRadius: FRRadius.all(20), boxShadow: [BoxShadow(color: FRColors.camelDeep.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))], border: Border.all(color: FRColors.camelDeep.withOpacity(0.03))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(children: [const Icon(Icons.shopping_bag_rounded, color: FRColors.textMuted, size: 20), const SizedBox(width: 8), Text('$itemCount Ürün', style: _t(fontWeight: FontWeight.w800, color: FRColors.espressoSoft, fontSize: 14))]),
          Container(width: 1, height: 24, color: FRColors.camelDeep.withOpacity(0.1)),
          Row(children: [const Icon(Icons.payments_rounded, color: FRColors.camelStrong, size: 20), const SizedBox(width: 8), Text('${formatTRY(estimatedTotal.total, keepTrailingZeros: true)} Tahmini', style: _t(fontWeight: FontWeight.w800, color: FRColors.espressoSoft, fontSize: 14))]),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.onAddProduct});
  final String label; final VoidCallback? onAddProduct;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _t(fontSize: 18, fontWeight: FontWeight.w800, color: FRColors.espressoSoft)),
        if (onAddProduct != null)
          InkWell(
            onTap: onAddProduct, borderRadius: FRRadius.all(14),
            child: Container(
              padding: FRSpaceInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [FRColors.camelStrong, FRColors.camelDeep], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: FRRadius.all(14), boxShadow: [BoxShadow(color: FRColors.camelDeep.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 4))]),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_circle, color: FRColors.white, size: 16), SizedBox(width: 6), Text('Ürün Ekle', style: TextStyle(color: FRColors.white, fontWeight: FontWeight.w800, fontSize: 13))]),
            ),
          )
      ],
    );
  }
}

class _CartProductCard extends StatelessWidget {
  const _CartProductCard({required this.item, required this.product, required this.onQuantityChanged, required this.onRemove, required this.onAddPrice});
  final BasketItemModel item; final ProductModel? product; final ValueChanged<int> onQuantityChanged; final VoidCallback onRemove; final VoidCallback onAddPrice;

  @override
  Widget build(BuildContext context) {
    final hasPrice = item.lastKnownPrice != null;
    return Container(
      padding: FRSpaceInsets.all(14),
      decoration: BoxDecoration(color: FRColors.white, borderRadius: FRRadius.all(24), boxShadow: [BoxShadow(color: FRColors.camelDeep.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))], border: Border.all(color: FRColors.camelDeep.withOpacity(0.03))),
      child: Row(
        children: [
          Container(width: 85, height: 85, decoration: BoxDecoration(color: FRColors.background, borderRadius: FRRadius.all(18)), child: AppNetworkImage(imageUrl: product?.mainImage, cacheKey: product?.id ?? item.productId, width: 85, height: 85, fit: BoxFit.cover, borderRadius: FRRadius.all(18))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product?.name ?? 'Ürün', maxLines: 2, overflow: TextOverflow.ellipsis, style: _t(fontWeight: FontWeight.w700, fontSize: 16, color: FRColors.espressoSoft)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    hasPrice ? Text(formatTRY(item.lastKnownPrice!), style: _t(fontWeight: FontWeight.w800, fontSize: 19, color: FRColors.camelDeep)) : GestureDetector(onTap: onAddPrice, child: Container(padding: FRSpaceInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: FRColors.danger.withOpacity(0.1), borderRadius: FRRadius.all(8)), child: Text("Fiyat Ekle", style: _t(color: FRColors.danger, fontWeight: FontWeight.w800, fontSize: 12)))),
                    _QuantityControl(quantity: item.quantity, onChanged: onQuantityChanged, onRemove: onRemove),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatefulWidget {
  const _QuantityControl({required this.quantity, required this.onChanged, required this.onRemove});
  final int quantity; final ValueChanged<int> onChanged; final VoidCallback onRemove;
  @override
  State<_QuantityControl> createState() => _QuantityControlState();
}
class _QuantityControlState extends State<_QuantityControl> {
  Timer? _repeatTimer;
  @override
  void dispose() { _repeatTimer?.cancel(); super.dispose(); }
  void _changeBy(int delta) { HapticFeedback.selectionClick(); final next = widget.quantity + delta; if (next <= 0) { widget.onRemove(); return; } widget.onChanged(next); }
  void _onLongPressStart(int delta) { _changeBy(delta); _repeatTimer?.cancel(); _repeatTimer = Timer.periodic(const Duration(milliseconds: 140), (_) => _changeBy(delta)); }
  void _onLongPressEnd() => _repeatTimer?.cancel();

  @override
  Widget build(BuildContext context) {
    final isOne = widget.quantity <= 1;
    return Container(
      padding: FRSpaceInsets.all(4),
      decoration: BoxDecoration(color: FRColors.camelDeep.withOpacity(0.06), borderRadius: FRRadius.all(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(onTap: () => _changeBy(-1), onLongPressStart: (_) => _onLongPressStart(-1), onLongPressEnd: (_) => _onLongPressEnd(), child: Container(width: 30, height: 30, decoration: BoxDecoration(color: FRColors.white, borderRadius: FRRadius.all(10), boxShadow: [BoxShadow(color: FRColors.espresso.withOpacity(0.08), blurRadius: 6)]), child: Icon(isOne ? Icons.delete_outline_rounded : Icons.remove_rounded, size: 18, color: isOne ? FRColors.danger : FRColors.espressoSoft))),
          Container(constraints: const BoxConstraints(minWidth: 32), alignment: Alignment.center, child: AnimatedSwitcher(duration: const Duration(milliseconds: 150), transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child), child: Text('${widget.quantity}', key: ValueKey(widget.quantity), style: _t(fontWeight: FontWeight.w700, fontSize: 15, color: FRColors.espressoSoft)))),
          GestureDetector(onTap: () => _changeBy(1), onLongPressStart: (_) => _onLongPressStart(1), onLongPressEnd: (_) => _onLongPressEnd(), child: Container(width: 30, height: 30, decoration: BoxDecoration(color: FRColors.white, borderRadius: FRRadius.all(10), boxShadow: [BoxShadow(color: FRColors.espresso.withOpacity(0.08), blurRadius: 6)]), child: const Icon(Icons.add_rounded, size: 18, color: FRColors.espressoSoft))),
        ],
      ),
    );
  }
}

class _CartActionBar extends StatelessWidget {
  const _CartActionBar({required this.itemCount, required this.estimatedTotal, required this.isLoading, required this.onCalculate});
  final int itemCount; final BasketEstimatedTotal estimatedTotal; final bool isLoading; final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: FRSpaceInsets.fromLTRB(24, 0, 24, 120),
      child: InkWell(
        onTap: itemCount == 0 || isLoading ? null : onCalculate,
        borderRadius: FRRadius.all(20),
        child: Container(
          width: double.infinity, padding: FRSpaceInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(color: FRColors.camelDeep, borderRadius: FRRadius.all(20), boxShadow: [BoxShadow(color: FRColors.camelDeep.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) Padding(padding: FRSpaceInsets.only(right: 8), child: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: FRColors.white))) else const Text('En Uygunu Bul', style: TextStyle(color: FRColors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8), const Icon(Icons.east_rounded, color: FRColors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: FRSpaceInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: FRSpaceInsets.all(28), decoration: BoxDecoration(color: FRColors.camelDeep.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.shopping_cart_outlined, size: 48, color: FRColors.camelDeep)),
            const SizedBox(height: 24), const Text('Sepetiniz boş', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: FRColors.espressoSoft)),
            const SizedBox(height: 8), const Text('Ürün ekleyerek marketler arasında\nfiyat karşılaştırması yapın.', textAlign: TextAlign.center, style: TextStyle(color: FRColors.textMuted, height: 1.5)),
            const SizedBox(height: 28),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Ürün Ekle', style: TextStyle(fontWeight: FontWeight.bold)), style: FilledButton.styleFrom(backgroundColor: FRColors.camelDeep, padding: FRSpaceInsets.symmetric(horizontal: 28, vertical: 16), shape: RoundedRectangleBorder(borderRadius: FRRadius.all(16)))),
          ],
        ),
      ),
    );
  }
}

class _LoginPromptCard extends StatelessWidget {
  const _LoginPromptCard();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FRColors.background,
      body: Center(
        child: Padding(
          padding: FRSpaceInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: FRSpaceInsets.all(24), decoration: BoxDecoration(color: FRColors.camelDeep.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.lock_outline_rounded, size: 40, color: FRColors.camelDeep)),
              const SizedBox(height: 20), const Text('Giriş Yapın', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: FRColors.espressoSoft)),
              const SizedBox(height: 8), const Text('Sepet özelliğini kullanmak için\nhesabınıza giriş yapmalısınız.', textAlign: TextAlign.center, style: TextStyle(color: FRColors.textMuted, height: 1.5)),
              const SizedBox(height: 24),
              FilledButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Devam etmek için giriş yapın.'))); }, style: FilledButton.styleFrom(backgroundColor: FRColors.camelDeep, padding: FRSpaceInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: FRRadius.all(16))), child: const Text('Giriş Yap', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _t({
  double fontSize = 14,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: FRTypography.fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? FRColors.textPrimary,
    height: height,
    letterSpacing: letterSpacing,
  );
}
