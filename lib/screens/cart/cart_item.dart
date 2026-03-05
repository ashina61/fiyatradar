class CartItem {
  const CartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  final String id;
  final String name;
  final String imageUrl;
  final double unitPrice;
  final int quantity;

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? unitPrice,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}
