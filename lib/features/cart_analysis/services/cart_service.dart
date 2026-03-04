import '../models/cart_item.dart';
import '../repositories/cart_repository.dart';

class CartService {
  const CartService(this._repository);

  final CartRepository _repository;

  Stream<List<CartItem>> watchCartItems(String userId) => _repository.watchCartItems(userId);

  Future<void> incrementItem(String userId, CartItem item) {
    return _repository.updateQuantity(userId, item.id, item.quantity + 1);
  }

  Future<void> decrementItem(String userId, CartItem item) {
    return _repository.updateQuantity(userId, item.id, item.quantity - 1);
  }

  Future<void> addItem(String userId, CartItem item) {
    return _repository.addOrUpdateItem(userId, item);
  }

  Future<void> removeItem(String userId, CartItem item) {
    return _repository.removeItem(userId, item.id);
  }
}
