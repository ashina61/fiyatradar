import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/price_report.dart';
import '../models/store.dart';

class StoreService {
  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }

  StoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<Store>> fetchStores({required String type, double? lat, double? lng}) async {
    _log('[StoreService] Firestore query: stores (type=$type)');
    final snapshot = await _firestore.collection('stores').get();
    final isOnlineMode = type == 'online';

    final mapped = snapshot.docs.map((doc) {
      final data = doc.data();
      final displayName = (data['displayName'] ?? data['name'] ?? '').toString();
      final isOnline = data['type'] == 'online' || data['isOnline'] == true;
      return Store(
        id: doc.id,
        name: displayName,
        type: isOnline ? 'online' : 'nearby',
        distanceMeters: 0,
        logoUrl: displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        subtitle: [data['district'], data['city']]
            .whereType<String>()
            .where((part) => part.trim().isNotEmpty)
            .join(', '),
      );
    }).where((store) => (store.type == 'online') == isOnlineMode).toList(growable: false);

    return mapped;
  }

  Future<void> submitPrice(PriceReport report) async {
    _log('[StoreService] Firestore write: priceReports');
    await _firestore.collection('priceReports').add({
      ...report.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
