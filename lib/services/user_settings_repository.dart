import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserSettingsRepository {
  UserSettingsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<UserModel?> fetchCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return null;
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }

    return UserModel.fromFirestore(doc);
  }

  Future<void> savePersonalInfo({
    required String firstName,
    required String lastName,
    required String city,
    required String username,
    required String neighborhood,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Aktif kullanıcı bulunamadı.');
    }

    await _firestore.collection('users').doc(uid).set({
      'name': '$firstName $lastName'.trim(),
      'displayName': '$firstName $lastName'.trim(),
      'firstName': firstName,
      'lastName': lastName,
      'city': city,
      'cityName': city,
      'username': username.trim().toLowerCase(),
      'neighborhood': neighborhood,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateNotificationPreference({
    required bool? alarm,
    required bool? campaign,
    required bool? badge,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Aktif kullanıcı bulunamadı.');
    }

    await _firestore.collection('users').doc(uid).set({
      'notificationPrefs': {
        if (alarm != null) 'priceAlerts': alarm,
        if (campaign != null) 'campaignAlerts': campaign,
        if (badge != null) 'badgeAlerts': badge,
      },
      if (alarm != null) 'alarmNotifications': alarm,
      if (campaign != null) 'campaignNotifications': campaign,
      if (badge != null) 'badgeNotifications': badge,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
