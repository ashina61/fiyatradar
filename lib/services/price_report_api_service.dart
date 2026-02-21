import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/price_report.dart';
import '../models/store.dart';
import 'store_service.dart';

class PriceReportApiService {
  PriceReportApiService({FirebaseFirestore? firestore})
      : _storeService = StoreService(firestore: firestore ?? FirebaseFirestore.instance);

  final StoreService _storeService;

  Future<List<Store>> fetchStores({double? lat, double? lng, required String type}) {
    return _storeService.fetchStores(type: type, lat: lat, lng: lng);
  }

  Future<void> submitPrice(PriceReport reportData) {
    return _storeService.submitPrice(reportData);
  }
}
