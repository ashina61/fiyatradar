import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/basket/basket_view_model.dart';

class CartItem {
  final String productId;
  final String productName;
  final String? imageUrl;
  final double price;
  final int quantity;
  final String platformName;
  final int trustScore;

  const CartItem({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.price,
    required this.quantity,
    required this.platformName,
    required this.trustScore,
  });
}

class CartNotifier extends AutoDisposeNotifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    final vm = ref.watch(basketViewModelProvider);
    return vm.items.map((basketItem) {
      final product = vm.productMap[basketItem.productId];

      final platformName = (product?.lastStore ?? '').trim().isNotEmpty
          ? product!.lastStore!.trim()
          : 'Platform';

      final entryCount = product?.priceEntryCount ?? 0;
      final baseTrust = entryCount >= 10
          ? 92 + (entryCount ~/ 10).clamp(0, 8)
          : entryCount >= 5
              ? 82 + (entryCount ~/ 5).clamp(0, 9)
              : 72 + entryCount.clamp(0, 9);
      final trustScore = baseTrust.clamp(72, 100);

      return CartItem(
        productId: basketItem.productId,
        productName: (product?.name ?? '').trim().isNotEmpty
            ? product!.name.trim()
            : 'Ürün',
        imageUrl: (product?.mainImage ?? '').trim().isNotEmpty
            ? product!.mainImage
            : null,
        price: basketItem.lastKnownPrice ?? product?.lastPrice ?? 0,
        quantity: basketItem.quantity,
        platformName: platformName,
        trustScore: trustScore,
      );
    }).toList(growable: false);
  }

  Future<void> clear() async {
    final vm = ref.read(basketViewModelProvider);
    final productIds =
        vm.items.map((item) => item.productId).toList(growable: false);
    for (final productId in productIds) {
      await vm.updateQuantity(productId, 0);
    }
    ref.invalidateSelf();
  }
}

final cartProvider =
    AutoDisposeNotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);
