import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import 'points_service.dart';

class UserAdminService {
  UserAdminService({
    FirebaseFirestore? firestore,
    PointsService? pointsService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _pointsService = pointsService ?? PointsService();

  final FirebaseFirestore _firestore;
  final PointsService _pointsService;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Stream<List<UserModel>> getAllUsers() {
    return _usersRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> updateUserAdmin(String userId, bool isAdmin) async {
    await _usersRef.doc(userId).update({'isAdmin': isAdmin});
  }

  Future<void> updateUserFcmToken(String userId, String token) async {
    await _usersRef.doc(userId).update({
      'fcmToken': token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _usersRef.doc(userId).update(data);
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUserByAdmin(String userId, Map<String, dynamic> data) async {
    await _usersRef.doc(userId).set(data, SetOptions(merge: true));

    final hasPointsUpdate =
        data.containsKey('totalPoints') || data.containsKey('pointsTotal') || data.containsKey('points');
    final hasRoleUpdate = data.containsKey('role') || data.containsKey('isAdmin');
    if (hasPointsUpdate || hasRoleUpdate) {
      await _pointsService.recomputeUserGamification(userId);
    }
  }

  Future<void> setUserBanStatusByAdmin({
    required String userId,
    required bool isBanned,
    String? reason,
    String? adminUid,
  }) async {
    await _usersRef.doc(userId).set({
      'isBanned': isBanned,
      'role': isBanned ? 'banned' : 'user',
      'isActive': !isBanned,
      'banReason': isBanned ? (reason ?? 'Admin işlemi') : FieldValue.delete(),
      'bannedAt': isBanned ? FieldValue.serverTimestamp() : FieldValue.delete(),
      'bannedByUid': isBanned ? (adminUid ?? '') : FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> softDeleteUserByAdmin(String userId) async {
    await _usersRef.doc(userId).set({
      'isActive': false,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUserByAdmin(String userId) async {
    await softDeleteUserByAdmin(userId);
  }
}
