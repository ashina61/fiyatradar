import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/banner_model.dart';
import '../utils/safe_query_builder.dart';

class BannerService {
  BannerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _bannersRef =>
      _firestore.collection('banners');

  Stream<List<BannerModel>> getActiveBanners() {
    final query =
        SafeQueryBuilder.safeWhere(_bannersRef, 'isActive', true, expectedType: bool);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map(BannerModel.fromFirestore)
          .where((banner) => banner.isActive)
          .toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Stream<List<BannerModel>> getAllBanners() {
    return _bannersRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map(BannerModel.fromFirestore).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Future<String> addBanner(BannerModel banner) async {
    final doc = await _bannersRef.add(banner.toMap());
    return doc.id;
  }

  Future<void> updateBanner(String bannerId, Map<String, dynamic> data) async {
    await _bannersRef.doc(bannerId).update(data);
  }

  Future<void> deleteBanner(String bannerId) async {
    await _bannersRef.doc(bannerId).delete();
  }
}
