// lib/screens/cart/cart_screen.dart
// V10 Migration — Comparison Tool (NOT Checkout)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/cart_provider.dart';
import '../../theme/fr_colors.dart';
import '../../theme/fr_radius.dart';
import '../../theme/fr_spacing.dart';
import '../../utils/formatters.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _showBestCombination = true;

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final bestCombination = _calculateBestCombination(cartItems);
    final singlePlatformOption = _calculateSinglePlatformOption(cartItems);

    return Scaffold(
      backgroundColor: FRColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildSummaryCard(bestCombination, singlePlatformOption),
            _buildCombinationToggle(),
            Expanded(
              child: _buildItemList(
                _showBestCombination ? bestCombination : singlePlatformOption,
              ),
            ),
            _buildPlatformDistribution(bestCombination),
            _buildActionBar(bestCombination),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: FRColors.background,
      elevation: 0,
      toolbarHeight: 56,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: FRColors.textPrimary,
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        'Karşılaştırma',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: FRColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          color: FRColors.textMuted,
          onPressed: () => _clearCart(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSummaryCard(CartCombination best, CartCombination single) {
    final savings = single.total - best.total;
    final savingsPercent =
        savings > 0 && single.total > 0 ? (savings / single.total * 100) : 0;

    return Container(
      margin: FRSpaceInsets.all(16),
      padding: FRSpaceInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FRColors.tan.withOpacity(0.08),
            FRColors.tan.withOpacity(0.02),
          ],
        ),
        borderRadius: FRRadius.all(FRRadius.xl),
        border: Border.all(color: FRColors.tan.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          const Text(
            'En İyi Kombinasyon',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: FRColors.textSubtle,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatTRY(best.total),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: FRColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          if (savings > 0)
            Container(
              padding: FRSpaceInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: FRColors.successBg(0.1),
                borderRadius: FRRadius.all(FRRadius.pill),
                border: Border.all(color: FRColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_down_rounded,
                    size: 14,
                    color: FRColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₺${savings.toStringAsFixed(0)} tasarruf (%${savingsPercent.toStringAsFixed(0)})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: FRColors.success,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '${best.platformCount} platformdan ${best.itemCount} ürün',
            style: const TextStyle(
              fontSize: 11,
              color: FRColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinationToggle() {
    return Container(
      margin: FRSpaceInsets.symmetric(horizontal: 16),
      padding: FRSpaceInsets.all(4),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: FRRadius.all(FRRadius.lg),
        border: Border.all(color: FRColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption(
              label: 'En İyi Karışık',
              icon: Icons.layers_rounded,
              isActive: _showBestCombination,
              onTap: () => setState(() => _showBestCombination = true),
            ),
          ),
          Expanded(
            child: _buildToggleOption(
              label: 'Tek Platform',
              icon: Icons.store_rounded,
              isActive: !_showBestCombination,
              onTap: () => setState(() => _showBestCombination = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRadius.all(FRRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: FRSpaceInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? FRColors.tan : Colors.transparent,
          borderRadius: FRRadius.all(FRRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? FRColors.background : FRColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? FRColors.background : FRColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(CartCombination combination) {
    if (combination.items.isEmpty) {
      return _buildEmptyCart();
    }

    return ListView.separated(
      padding: FRSpaceInsets.fromLTRB(16, 16, 16, 16),
      itemCount: combination.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = combination.items[index];
        return _buildCartItem(item);
      },
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: FRColors.surfaceAlt,
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 32,
              color: FRColors.textSubtle,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Karşılaştırma listesi boş',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: FRColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Arama sayfasından ürün ekleyin',
            style: TextStyle(
              fontSize: 12,
              color: FRColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: FRRadius.all(FRRadius.lg),
        border: Border.all(color: FRColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: FRSpaceInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: FRColors.surfaceAlt,
                    borderRadius: FRRadius.all(FRRadius.md),
                    border: Border.all(color: FRColors.border),
                  ),
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: FRRadius.all(FRRadius.md),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.category_outlined,
                              size: 28,
                              color: FRColors.tan,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.category_outlined,
                          size: 28,
                          color: FRColors.tan,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: FRColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adet: ${item.quantity}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: FRColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatTRY(item.price * item.quantity),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: FRColors.tan,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: FRSpaceInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: FRColors.surfaceAlt,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              border: const Border(top: BorderSide(color: FRColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: FRColors.tan,
                    borderRadius: FRRadius.all(FRRadius.sm),
                  ),
                  child: Center(
                    child: Text(
                      item.platformName.isNotEmpty
                          ? item.platformName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: FRColors.background,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.platformName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FRColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: FRSpaceInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.trustScore >= 90
                        ? FRColors.successBg(0.12)
                        : FRColors.surface,
                    borderRadius: FRRadius.all(FRRadius.sm),
                    border: Border.all(
                      color: item.trustScore >= 90
                          ? FRColors.success.withOpacity(0.3)
                          : FRColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        size: 10,
                        color: item.trustScore >= 90
                            ? FRColors.success
                            : FRColors.textSubtle,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${item.trustScore}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.trustScore >= 90
                              ? FRColors.success
                              : FRColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformDistribution(CartCombination combination) {
    final platforms = _groupItemsByPlatform(combination.items);

    return Container(
      margin: FRSpaceInsets.fromLTRB(16, 0, 16, 16),
      padding: FRSpaceInsets.all(16),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: FRRadius.all(FRRadius.lg),
        border: Border.all(color: FRColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Dağılımı',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FRColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...platforms.entries.map((entry) {
            final platformTotal = entry.value.fold<double>(
              0,
              (sum, item) => sum + (item.price * item.quantity),
            );

            return Padding(
              padding: FRSpaceInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: FRColors.surfaceAlt,
                      borderRadius: FRRadius.all(FRRadius.md),
                      border: Border.all(color: FRColors.border),
                    ),
                    child: Center(
                      child: Text(
                        entry.key.isNotEmpty ? entry.key[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: FRColors.tan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: FRColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${entry.value.length} ürün',
                          style: const TextStyle(
                            fontSize: 11,
                            color: FRColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatTRY(platformTotal),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: FRColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionBar(CartCombination combination) {
    return Container(
      padding: FRSpaceInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            FRColors.background.withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openPlatformLinks(combination),
              style: ElevatedButton.styleFrom(
                backgroundColor: FRColors.tan,
                foregroundColor: FRColors.background,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: FRRadius.all(FRRadius.lg),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Platform\'lara Git',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _shareCart(combination),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Listeyi Paylaş'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FRColors.textPrimary,
                side: const BorderSide(color: FRColors.border),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: FRRadius.all(FRRadius.lg),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Fiyatlar platformlarda değişebilir. Son fiyatları platformda kontrol edin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: FRColors.textSubtle,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  CartCombination _calculateBestCombination(List<CartItem> items) {
    double total = 0;
    final platforms = <String>{};

    for (final item in items) {
      total += item.price * item.quantity;
      platforms.add(item.platformName);
    }

    return CartCombination(
      items: items,
      total: total,
      itemCount: items.length,
      platformCount: platforms.length,
    );
  }

  CartCombination _calculateSinglePlatformOption(List<CartItem> items) {
    return _calculateBestCombination(items);
  }

  Map<String, List<CartItem>> _groupItemsByPlatform(List<CartItem> items) {
    final grouped = <String, List<CartItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.platformName, () => []).add(item);
    }
    return grouped;
  }

  void _clearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: FRColors.surface,
        title: const Text('Listeyi Temizle?'),
        content: const Text(
          'Tüm ürünler karşılaştırma listesinden kaldırılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(cartProvider.notifier).clear();
              if (!mounted) return;
              Navigator.pop(dialog);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Liste temizlendi.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FRColors.tan,
              foregroundColor: FRColors.background,
            ),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPlatformLinks(CartCombination combination) async {
    final platforms = _groupItemsByPlatform(combination.items);

    for (final platform in platforms.keys) {
      final url = _getPlatformUrl(platform);
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Platform linkleri açıldı.')),
      );
    }
  }

  String? _getPlatformUrl(String platform) {
    final urls = {
      'Trendyol': 'https://www.trendyol.com',
      'Hepsiburada': 'https://www.hepsiburada.com',
      'Amazon': 'https://www.amazon.com.tr',
      'N11': 'https://www.n11.com',
      'ÇiçekSepeti': 'https://www.ciceksepeti.com',
      'Platform': 'https://www.fiyatradar.com',
    };
    return urls[platform];
  }

  void _shareCart(CartCombination combination) {
    final text =
        'FiyatRadar Karşılaştırma Listesi:\n\n'
        '${combination.items.map((i) => '- ${i.productName}: ${formatTRY(i.price * i.quantity)} (${i.platformName})').join('\n')}\n\n'
        'Toplam: ${formatTRY(combination.total)}\n\n'
        'FiyatRadar ile akıllı alışveriş yap!';

    Share.share(text);
  }
}

class CartCombination {
  final List<CartItem> items;
  final double total;
  final int itemCount;
  final int platformCount;

  const CartCombination({
    required this.items,
    required this.total,
    required this.itemCount,
    required this.platformCount,
  });
}
