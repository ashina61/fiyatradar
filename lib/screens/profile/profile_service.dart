import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Giriş yapmış adamın ID'sini al
  String? get currentUserId => _auth.currentUser?.uid;

  // Profil bilgilerini Firebase'den çek
  Future<UserModel?> getUserProfile() async {
    try {
      if (currentUserId == null) return null;
      
      final doc = await _db.collection('users').doc(currentUserId).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      print("Profil çekilirken hata: $e");
    }
    return null;
  }

  // Profil bilgilerini Firebase'e yaz
  Future<bool> updateUserProfile(UserModel user) async {
    try {
      if (currentUserId == null) return false;
      
      // update kullanıyoruz ki sadece var olanı güncellesin
      await _db.collection('users').doc(currentUserId).update(user.toFirestore());
      return true;
    } catch (e) {
      print("Profil güncellenirken hata: $e");
      // Eğer kullanıcı dökümanı daha önce hiç oluşmamışsa (hata verirse), set ile sıfırdan oluştur:
      try {
        await _db.collection('users').doc(currentUserId).set(user.toFirestore());
        return true;
      } catch (e2) {
        return false;
      }
    }
  }
}
