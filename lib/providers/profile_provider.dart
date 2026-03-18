import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

// Bu provider'ı ekranlarında ref.watch(profileProvider) diye dinleyeceksin
final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserModel?>>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  ProfileNotifier() : super(const AsyncLoading()) {
    loadProfile();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firebase'den Gerçek Veriyi Çek!
  Future<void> loadProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        // Adam giriş yapmamışsa mock data gösterme, hata fırlat!
        state = AsyncError("Kullanıcı girişi bulunamadı.", StackTrace.current);
        return;
      }

      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        // Gerçek veriyi State'e aktar
        state = AsyncData(UserModel.fromFirestore(doc));
      } else {
        // Firebase'de adamın kaydı yoksa, null döndür (Sahte Adem Bayram yok!)
        state = const AsyncData(null); 
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Firebase'e Gerçek Veriyi Yaz!
  Future<bool> updateProfile(UserModel updatedUser) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      await _db.collection('users').doc(uid).set(updatedUser.toFirestore(), SetOptions(merge: true));
      // Veritabanı başarıyla güncellendi, şimdi ekrandaki state'i de anında güncelle!
      state = AsyncData(updatedUser);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Firebase Yazma Hatası: $e');
      return false;
    }
  }
}
