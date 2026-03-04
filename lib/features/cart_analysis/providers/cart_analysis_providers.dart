import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../models/cart_item.dart';
import '../models/market_comparison.dart';
import '../repositories/cart_repository.dart';
import '../services/cart_service.dart';
import '../services/market_comparison_service.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return FirestoreCartRepository(FirebaseFirestore.instance);
});

final cartServiceProvider = Provider<CartService>((ref) {
  return CartService(ref.watch(cartRepositoryProvider));
});

final marketComparisonServiceProvider = Provider<MarketComparisonService>((ref) {
  return MarketComparisonService(FirebaseFirestore.instance);
});

final activeUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

final cartItemsProvider = StreamProvider<List<CartItem>>((ref) {
  final userId = ref.watch(activeUserIdProvider);
  if (userId == null) {
    return Stream.value(const <CartItem>[]);
  }
  return ref.watch(cartServiceProvider).watchCartItems(userId);
});

final marketComparisonsProvider = FutureProvider<MarketComparisonBundle>((ref) async {
  final items = await ref.watch(cartItemsProvider.future);
  return ref.watch(marketComparisonServiceProvider).compare(items);
});
