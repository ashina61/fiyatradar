import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart_item.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(_mockCartItems);

  static final List<CartItem> _mockCartItems = [
    const CartItem(
      id: 'nutella',
      name: 'Nutella 400g',
      imageUrl:
          'https://images.unsplash.com/photo-1628840042765-356cda07504e?q=80&w=200&auto=format&fit=crop',
      unitPrice: 36,
      quantity: 1,
    ),
    const CartItem(
      id: 'kola',
      name: 'Sarıyer Kola 330mL',
      imageUrl:
          'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?q=80&w=200&auto=format&fit=crop',
      unitPrice: 40,
      quantity: 1,
    ),
    const CartItem(
      id: 'yumurta',
      name: "15'li L Boy Yumurta",
      imageUrl:
          'https://images.unsplash.com/photo-1587486913049-53fc88980cfc?q=80&w=200&auto=format&fit=crop',
      unitPrice: 15,
      quantity: 1,
    ),
  ];

  void increaseQuantity(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(quantity: item.quantity + 1)
        else
          item,
    ];
  }

  void removeOrDecrease(String id) {
    final target = state.firstWhere((item) => item.id == id);
    if (target.quantity <= 1) {
      state = state.where((item) => item.id != id).toList();
      return;
    }
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(quantity: item.quantity - 1)
        else
          item,
    ];
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.totalPrice);
});
