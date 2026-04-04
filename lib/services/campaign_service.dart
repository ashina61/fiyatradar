import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campaign_basket_model.dart';
import '../utils/safe_query_builder.dart';

class CampaignService {
  CampaignService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _campaignBasketsRef =>
      _firestore.collection('campaignBaskets');
  CollectionReference<Map<String, dynamic>> get _bannersRef =>
      _firestore.collection('banners');

  Future<List<String>> getCampaignProductIdsForBanner(String bannerId) async {
    final sub = await _bannersRef.doc(bannerId).collection('campaignProducts').get();
    return sub.docs
        .map((doc) => (doc.data()['productId'] ?? doc.id).toString())
        .where((id) => id.trim().isNotEmpty)
        .toList();
  }

  Future<CampaignBasketModel?> getCampaignById(String id) async {
    if (id.trim().isEmpty) return null;
    final doc = await _campaignBasketsRef.doc(id).get();
    if (!doc.exists) return null;
    return CampaignBasketModel.fromFirestore(doc);
  }

  Stream<List<CampaignBasketModel>> getAllCampaigns() {
    return _campaignBasketsRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map(CampaignBasketModel.fromFirestore).toList();
      list.sort((a, b) {
        final aOrder = a.sortOrder ?? 999999;
        final bOrder = b.sortOrder ?? 999999;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  Stream<List<CampaignBasketModel>> getActiveCampaigns() {
    final query =
        SafeQueryBuilder.safeWhere(_campaignBasketsRef, 'isActive', true, expectedType: bool);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map(CampaignBasketModel.fromFirestore).toList();
      list.sort((a, b) {
        final aOrder = a.sortOrder ?? 999999;
        final bOrder = b.sortOrder ?? 999999;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  Future<String> addCampaign(CampaignBasketModel campaign) async {
    final doc = await _campaignBasketsRef.add({
      ...campaign.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateCampaign(String id, Map<String, dynamic> data) async {
    await _campaignBasketsRef.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCampaign(String id) async {
    await _campaignBasketsRef.doc(id).delete();
  }
}
