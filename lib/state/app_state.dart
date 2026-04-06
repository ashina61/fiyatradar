import 'package:flutter/widgets.dart';
import '../models/product.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

  final List<Product> products = [];
  final List<CartItem> cart = [];

  final List<String> categories = const [
    'Tümü',
    'Kahvaltılık',
    'Meyve & Sebze',
    'İçecek',
    'Atıştırmalık',
    'Süt Ürünleri',
    'Temizlik',
  ];

  final List<String> stores = const [
    'A101',
    'BİM',
    'ŞOK',
    'Migros',
    'CarrefourSA',
    'Tarım Kredi',
  ];

  void _seed() {
    products.addAll([
      Product(
        id: 'p1',
        name: 'Tam Yağlı Süt 1L',
        brand: 'Sütaş',
        category: 'Süt Ürünleri',
        emoji: '🥛',
        unit: '1 L',
        priceHistory: [
          PriceEntry(
              store: 'BİM', price: 32.50, date: DateTime.now().subtract(const Duration(days: 6))),
          PriceEntry(
              store: 'A101', price: 33.90, date: DateTime.now().subtract(const Duration(days: 3))),
          PriceEntry(
              store: 'Migros', price: 35.50, date: DateTime.now().subtract(const Duration(days: 1))),
        ],
      ),
      Product(
        id: 'p2',
        name: 'Türk Kahvesi 250g',
        brand: 'Kurukahveci',
        category: 'İçecek',
        emoji: '☕',
        unit: '250 g',
        priceHistory: [
          PriceEntry(
              store: 'Migros', price: 145.00, date: DateTime.now().subtract(const Duration(days: 5))),
          PriceEntry(
              store: 'A101', price: 139.50, date: DateTime.now().subtract(const Duration(days: 2))),
        ],
      ),
      Product(
        id: 'p3',
        name: 'Zeytinyağı 1L',
        brand: 'Komili',
        category: 'Kahvaltılık',
        emoji: '🫒',
        unit: '1 L',
        priceHistory: [
          PriceEntry(
              store: 'ŞOK', price: 289.00, date: DateTime.now().subtract(const Duration(days: 4))),
          PriceEntry(
              store: 'CarrefourSA', price: 305.00, date: DateTime.now().subtract(const Duration(days: 1))),
        ],
      ),
      Product(
        id: 'p4',
        name: 'Yumurta 30’lu',
        brand: 'Köy',
        category: 'Kahvaltılık',
        emoji: '🥚',
        unit: '30 adet',
        priceHistory: [
          PriceEntry(
              store: 'A101', price: 159.00, date: DateTime.now().subtract(const Duration(days: 2))),
        ],
      ),
      Product(
        id: 'p5',
        name: 'Domates 1kg',
        brand: 'Yerli',
        category: 'Meyve & Sebze',
        emoji: '🍅',
        unit: '1 kg',
        priceHistory: [
          PriceEntry(
              store: 'Tarım Kredi', price: 24.90, date: DateTime.now().subtract(const Duration(days: 1))),
          PriceEntry(
              store: 'Migros', price: 32.50, date: DateTime.now()),
        ],
      ),
      Product(
        id: 'p6',
        name: 'Çikolata 80g',
        brand: 'Eti',
        category: 'Atıştırmalık',
        emoji: '🍫',
        unit: '80 g',
        priceHistory: [
          PriceEntry(
              store: 'BİM', price: 22.50, date: DateTime.now().subtract(const Duration(days: 3))),
        ],
      ),
    ]);
  }

  Product? findById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  void addPrice({
    required String productId,
    required String store,
    required double price,
  }) {
    final p = findById(productId);
    if (p == null) return;
    p.priceHistory.add(
      PriceEntry(store: store, price: price, date: DateTime.now()),
    );
    notifyListeners();
  }

  void addProduct(Product p) {
    products.add(p);
    notifyListeners();
  }

  void addToCart(Product p) {
    final existing = cart.where((c) => c.product.id == p.id).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      cart.add(CartItem(product: p));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    cart.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  void changeQty(String productId, int delta) {
    for (final c in cart) {
      if (c.product.id == productId) {
        c.quantity += delta;
        if (c.quantity <= 0) {
          cart.remove(c);
        }
        break;
      }
    }
    notifyListeners();
  }

  double get cartTotal {
    double total = 0;
    for (final c in cart) {
      total += (c.product.lowestPrice ?? 0) * c.quantity;
    }
    return total;
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }
}
