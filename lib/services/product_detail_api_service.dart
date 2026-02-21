import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_detail_api_model.dart';

class ProductDetailApiService {
  ProductDetailApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = String.fromEnvironment(
    'PRODUCT_API_BASE_URL',
    defaultValue: 'https://api.fiyatradar.com',
  );

  Future<ProductDetailResponse> fetchProductDetails(String productId) async {
    final response = await _client.get(Uri.parse('$_baseUrl/products/$productId/details'));
    _ensureSuccess(response);
    return ProductDetailResponse.fromJson(_decode(response.body));
  }

  Future<List<PriceHistoryPoint>> fetchPriceHistory(String productId) async {
    final response = await _client.get(Uri.parse('$_baseUrl/products/$productId/price-history?days=30'));
    _ensureSuccess(response);
    final json = _decode(response.body);
    final list = (json['points'] as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(PriceHistoryPoint.fromJson).toList();
  }

  Future<void> postComment(String productId, String text) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/products/$productId/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
    _ensureSuccess(response);
  }

  Future<void> votePrice(String priceId, bool isApproved) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/prices/$priceId/vote'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'isApproved': isApproved}),
    );
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API hata (${response.statusCode}): ${response.body}');
    }
  }

  Map<String, dynamic> _decode(String body) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Beklenmeyen API formatı');
  }
}
