import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart'; // Modelimizi içeri aldık

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Giriş yapmış adamın ID'sini al
  String? get currentUserId => _auth.currentUser?.uid;

  // Profil bilgilerini Firebase'den çek
  Future<UserModel?> getUserProfile() async {
    try {
      if (currentUserId == null) return null;
      
      DocumentSnapshot doc = await _db.collection('users').doc(currentUserId).get();
      
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
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
      await _db.collection('users').doc(currentUserId).update(user.toMap());
      return true;
    } catch (e) {
      print("Profil güncellenirken hata: $e");
      // Eğer kullanıcı dökümanı daha önce hiç oluşmamışsa (hata verirse), set ile sıfırdan oluştur:
      try {
        await _db.collection('users').doc(currentUserId).set(user.toMap());
        return true;
      } catch (e2) {
        return false;
      }
    }
  }
}
