import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/price_report.dart';
import '../models/store.dart';

class PriceReportApiService {
  PriceReportApiService({
    http.Client? client,
    this.baseUrl = 'https://api.fiyatradar.com/v1',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<List<Store>> fetchStores({
    double? lat,
    double? lng,
    required String type,
  }) async {
    final uri = Uri.parse('$baseUrl/stores').replace(
      queryParameters: {
        'type': type,
        if (lat != null) 'lat': lat.toString(),
        if (lng != null) 'lng': lng.toString(),
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['stores'] as List<dynamic>? ?? const []);
      return items
          .map((e) => Store.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    throw Exception('Mağazalar alınamadı (${response.statusCode})');
  }

  Future<void> submitPrice(PriceReport reportData) async {
    final uri = Uri.parse('$baseUrl/price-reports');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(reportData.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Fiyat gönderilemedi (${response.statusCode})');
    }
  }
}
