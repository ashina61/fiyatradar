// lib/screens/cart/cart_screen.dart
// V10 Migration — Comparison Tool (NOT Checkout)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/cart_provider.dart';
import '../../theme/fr_colors.dart';
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
    final activeCombination = _showBestCombination ? bestCombination : singlePlatformOption;

    return Scaffold(
      backgroundColor: FRColors.backgroundWarm,
      body: Column(
        children: [
          _buildDarkHeader(context, cartItems.length),
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyCart()
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _buildSummaryCard(bestCombination, singlePlatformOption),
                      _buildCombinationToggle(),
                      _buildSectionLabel('ÜRÜNLERİNİZ'),
                      ...activeCombination.items.map((item) => _buildCartItem(item)),
                      _buildPlatformDistribution(bestCombination),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
          if (cartItems.isNotEmpty) _buildActionBar(bestCombination),
        ],
      ),
    );
  }

  Widget _buildDarkHeader(BuildContext context, int itemCount) {
    return Container(
      decoration: const BoxDecoration(
        color: FRColors.espresso,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sepet',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'FİYAT KARŞILAŞTIRMA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: FRColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (itemCount > 0)
                GestureDetector(
                  onTap: () => _clearCart(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 15, color: Colors.white.withOpacity(0.7)),
                        const SizedBox(width: 5),
                        Text(
                          'Temizle',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(CartCombination best, CartCombination single) {
    final savings = single.total - best.total;
    final savingsPercent = savings > 0 && single.total > 0 ? (savings / single.total * 100) : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FRColors.espresso,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'EN İYİ KOMBİNASYON',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: FRColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatTRY(best.total),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          if (savings > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: FRColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: FRColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_down_rounded, size: 14, color: FRColors.success),
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
          const SizedBox(height: 10),
          Text(
            '${best.platformCount} platformdan ${best.itemCount} ürün',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45)),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinationToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(14),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? FRColors.espresso : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: isActive ? FRColors.tan : FRColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : FRColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: FRColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x08170D08), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: FRColors.backgroundWarm,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FRColors.border),
                  ),
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.category_outlined, size: 26, color: FRColors.tan),
                          ),
                        )
                      : const Icon(Icons.category_outlined, size: 26, color: FRColors.tan),
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
                        style: const TextStyle(fontSize: 11, color: FRColors.textSubtle),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatTRY(item.price * item.quantity),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: FRColors.tan,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (item.quantity > 1)
                      Text(
                        '${formatTRY(item.price)}/adet',
                        style: const TextStyle(fontSize: 10, color: FRColors.textSubtle),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: FRColors.backgroundWarm,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
              border: Border(top: BorderSide(color: FRColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: FRColors.espresso,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      item.platformName.isNotEmpty ? item.platformName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: FRColors.tan,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.trustScore >= 90
                        ? FRColors.successSurface
                        : FRColors.backgroundWarm,
                    borderRadius: BorderRadius.circular(8),
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
                        color: item.trustScore >= 90 ? FRColors.success : FRColors.textSubtle,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${item.trustScore}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.trustScore >= 90 ? FRColors.success : FRColors.textSubtle,
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

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x0A170D08), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 36, color: FRColors.textSubtle),
          ),
          const SizedBox(height: 20),
          const Text(
            'Karşılaştırma Listesi Boş',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: FRColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Arama sayfasından ürün ekleyin\nve fiyatları karşılaştırın',
            style: TextStyle(fontSize: 13, color: FRColors.textSubtle, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformDistribution(CartCombination combination) {
    final platforms = _groupItemsByPlatform(combination.items);
    if (platforms.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FRColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PLATFORM DAĞILIMI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: FRColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          ...platforms.entries.map((entry) {
            final platformTotal = entry.value.fold<double>(
              0,
              (sum, item) => sum + (item.price * item.quantity),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: FRColors.espresso,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        entry.key.isNotEmpty ? entry.key[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
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
                          style: const TextStyle(fontSize: 11, color: FRColors.textSubtle),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatTRY(platformTotal),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: FRColors.tan,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: FRColors.surface,
        border: const Border(top: BorderSide(color: FRColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openPlatformLinks(combination),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FRColors.espresso,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 18, color: FRColors.tan),
                    SizedBox(width: 8),
                    Text(
                      'Platformlara Git',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _shareCart(combination),
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Listeyi Paylaş'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FRColors.textPrimary,
                  side: const BorderSide(color: FRColors.border),
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fiyatlar platformlarda değişebilir. Son fiyatları kontrol edin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: FRColors.textSubtle),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Logic helpers ────────────────────────────────────────────────────────

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Listeyi Temizle?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: FRColors.textPrimary),
        ),
        content: const Text(
          'Tüm ürünler karşılaştırma listesinden kaldırılacak.',
          style: TextStyle(fontSize: 13, color: FRColors.textSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('İptal', style: TextStyle(color: FRColors.textMuted)),
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
              backgroundColor: FRColors.espresso,
              foregroundColor: FRColors.tan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Temizle', style: TextStyle(fontWeight: FontWeight.w700)),
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
    const urls = {
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
