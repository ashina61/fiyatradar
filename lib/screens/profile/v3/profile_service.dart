import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_model.dart';

class ProfileService {
  ProfileService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<UserModel> getUserProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('Kullanıcı oturumu bulunamadı.');
      }

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        throw Exception('Kullanıcı profili bulunamadı.');
      }

      final data = doc.data() ?? <String, dynamic>{};
      data['id'] = uid;
      return UserModel.fromMap(data);
    } catch (e) {
      throw Exception('Profil verisi alınamadı: $e');
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('Kullanıcı oturumu bulunamadı.');
      }

      await _firestore.collection('users').doc(uid).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Profil güncellenemedi: $e');
    }
  }
}
