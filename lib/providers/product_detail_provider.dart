import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_detail_api_model.dart';
import '../services/firestore_service.dart';
import '../services/product_detail_api_service.dart';

final productDetailApiServiceProvider = Provider<ProductDetailApiService>((ref) {
  return ProductDetailApiService();
});

class ProductDetailState {
  const ProductDetailState({
    this.isLoading = true,
    this.isSubmittingComment = false,
    this.isSubmittingVote = false,
    this.data,
    this.history = const [],
    this.error,
  });

  final bool isLoading;
  final bool isSubmittingComment;
  final bool isSubmittingVote;
  final ProductDetailResponse? data;
  final List<PriceHistoryPoint> history;
  final String? error;

  ProductDetailState copyWith({
    bool? isLoading,
    bool? isSubmittingComment,
    bool? isSubmittingVote,
    ProductDetailResponse? data,
    List<PriceHistoryPoint>? history,
    String? error,
  }) {
    return ProductDetailState(
      isLoading: isLoading ?? this.isLoading,
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
      isSubmittingVote: isSubmittingVote ?? this.isSubmittingVote,
      data: data ?? this.data,
      history: history ?? this.history,
      error: error,
    );
  }
}

class ProductDetailNotifier extends StateNotifier<ProductDetailState> {
  ProductDetailNotifier(this._api, this._productId)
      : super(const ProductDetailState()) {
    load();
  }

  final ProductDetailApiService _api;
  final String _productId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final detail = await _api.fetchProductDetails(_productId);
      final history = await _api.fetchPriceHistory(_productId);
      state = state.copyWith(isLoading: false, data: detail, history: history, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> postComment(String text) async {
    state = state.copyWith(isSubmittingComment: true, error: null);
    try {
      await _api.postComment(_productId, text);
      final nextComments = await _api.fetchComments(_productId);
      final current = state.data;
      if (current != null) {
        state = state.copyWith(
          data: ProductDetailResponse(
            id: current.id,
            title: current.title,
            imageUrl: current.imageUrl,
            categories: current.categories,
            viewCount: current.viewCount,
            priceEntryCount: current.priceEntryCount,
            bestPrice: current.bestPrice,
            stats: current.stats,
            trust: current.trust,
            comments: nextComments,
            marketPrices: current.marketPrices,
            recentPrices: current.recentPrices,
          ),
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(isSubmittingComment: false, error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isSubmittingComment: false);
    }
  }

  Future<PriceVoteResult?> votePrice({required String priceId, required bool isApproved}) async {
    state = state.copyWith(isSubmittingVote: true, error: null);
    try {
      final result = await _api.votePrice(priceId, isApproved);
      final nextSnapshot = await _api.fetchPriceSnapshot(_productId);
      final current = state.data;
      if (current != null) {
        state = state.copyWith(
          data: ProductDetailResponse(
            id: current.id,
            title: current.title,
            imageUrl: current.imageUrl,
            categories: current.categories,
            viewCount: current.viewCount,
            priceEntryCount: nextSnapshot.priceEntryCount,
            bestPrice: nextSnapshot.bestPrice,
            stats: nextSnapshot.stats,
            trust: nextSnapshot.trust,
            comments: current.comments,
            marketPrices: nextSnapshot.marketPrices,
            recentPrices: nextSnapshot.recentPrices,
          ),
        );
      }
      return result;
    } catch (e) {
      state = state.copyWith(isSubmittingVote: false, error: e.toString());
      return null;
    } finally {
      state = state.copyWith(isSubmittingVote: false);
    }
  }
}

final productDetailProvider =
    StateNotifierProvider.family<ProductDetailNotifier, ProductDetailState, String>((ref, productId) {
  return ProductDetailNotifier(ref.watch(productDetailApiServiceProvider), productId);
});
