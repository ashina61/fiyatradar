import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/price_report.dart';
import '../models/store.dart';

class StoreService {
  StoreService({
    http.Client? client,
    this.baseUrl = 'https://api.fiyatradar.com/v1',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<List<Store>> fetchStores({
    required String type,
    double? lat,
    double? lng,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/stores').replace(
        queryParameters: {
          'type': type,
          if (lat != null) 'lat': lat.toString(),
          if (lng != null) 'lng': lng.toString(),
        },
      );

      final response = await _client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Mağazalar alınamadı (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final storesRaw = data['stores'] as List<dynamic>? ?? const [];
      return storesRaw
          .map((item) => Store.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on SocketException {
      return _mockStores(type);
    } on http.ClientException {
      return _mockStores(type);
    } catch (_) {
      if (_usesPrimaryApiHost) {
        return _mockStores(type);
      }
      rethrow;
    }
  }

  bool get _usesPrimaryApiHost => Uri.parse(baseUrl).host == 'api.fiyatradar.com';

  List<Store> _mockStores(String type) {
    const fallback = [
      Store(id: '1', name: 'Migros', type: 'nearby', distanceMeters: 0, logoUrl: ''),
      Store(id: '2', name: 'A101', type: 'nearby', distanceMeters: 0, logoUrl: ''),
      Store(id: '3', name: 'Trendyol', type: 'online', distanceMeters: 0, logoUrl: ''),
    ];

    return fallback.where((store) => store.type == type).toList(growable: false);
  }

  Future<void> submitPrice(PriceReport report) async {
    final uri = Uri.parse('$baseUrl/price-reports');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(report.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Fiyat gönderilemedi (${response.statusCode})');
    }
  }
}
