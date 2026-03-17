import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/banner_model.dart';

final bannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('banners')
      .where('isActive', isEqualTo: true)
      .orderBy('order')
      .snapshots()
      .map((snap) => snap.docs.map(BannerModel.fromDoc).toList());
});
