import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/safe_query_builder.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _generateInviteCode(String uid) {
    final normalized = uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (normalized.length >= 6) {
      return normalized.substring(0, 6).toUpperCase();
    }
    return uid.substring(0, uid.length.clamp(1, 6)).toUpperCase();
  }

  // Email/Password Sign In
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _updateLastLogin(credential.user!.uid);
        return await getUserModel(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Email/Password Sign Up
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? inviteCode,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final normalizedInviteCode =
            inviteCode?.trim().toUpperCase().replaceAll(' ', '');
        final newInviteCode = _generateInviteCode(credential.user!.uid);
        await credential.user!.updateDisplayName(name);

        final user = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: name,
          inviteCode: newInviteCode,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(user.toFirestore());

        if (normalizedInviteCode != null && normalizedInviteCode.isNotEmpty) {
          try {
            final inviterQuery = SafeQueryBuilder.safeWhere(
              _firestore.collection('users'),
              'inviteCode',
              normalizedInviteCode,
              expectedType: String,
            );
            final inviterSnapshot = await inviterQuery.limit(1).get();
            if (inviterSnapshot.docs.isNotEmpty) {
              final inviterId = inviterSnapshot.docs.first.id;
              await _firestore.collection('users').doc(credential.user!.uid).update({
                'invitedBy': inviterId,
              });
              await _firestore.collection('users').doc(inviterId).update({
                'inviteCount': FieldValue.increment(1),
                'points': FieldValue.increment(AppConstants.pointsForInvite),
              });
            }
          } catch (e) {
            debugPrint("FIRESTORE QUERY ERROR -> $e");
          }
        }

        return user;
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Google Sign In
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;

        // Check if user document exists
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

        if (!docSnapshot.exists) {
          // Create new user document
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'Kullanici',
            photoUrl: user.photoURL,
            inviteCode: _generateInviteCode(user.uid),
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );

          await _firestore.collection('users').doc(user.uid).set(newUser.toFirestore());
          return newUser;
        } else {
          final data = docSnapshot.data();
          if (data != null && data['inviteCode'] == null) {
            await _firestore.collection('users').doc(user.uid).update({
              'inviteCode': _generateInviteCode(user.uid),
            });
          }
          // Update last login
          await _updateLastLogin(user.uid);
          return await getUserModel(user.uid);
        }
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google ile giris yapilamadi: $e',
      );
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Get User Model
  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateLastLogin(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    final lastLoginAt = (data?['lastLoginAt'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    final isNewDay = lastLoginAt == null ||
        lastLoginAt.year != now.year ||
        lastLoginAt.month != now.month ||
        lastLoginAt.day != now.day;
    final inviteCode = data?['inviteCode'] as String?;

    final updates = <String, dynamic>{
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    if (inviteCode == null || inviteCode.isEmpty) {
      updates['inviteCode'] = _generateInviteCode(uid);
    }

    if (isNewDay) {
      updates['points'] = FieldValue.increment(AppConstants.pointsForDailyLogin);
    }

    await _firestore.collection('users').doc(uid).update(updates);
  }

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? photoUrl,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  Future<void> makeAdmin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isAdmin': true,
    });
  }

  Future<void> addPoints(String uid, int points) async {
    await _firestore.collection('users').doc(uid).update({
      'points': FieldValue.increment(points),
    });
  }

  Future<void> incrementPriceEntries(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'priceEntries': FieldValue.increment(1),
    });
  }

  Future<void> incrementValidations(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'validations': FieldValue.increment(1),
    });
  }

  Future<void> toggleSavedProduct(String uid, String productId) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final savedProducts = List<String>.from(doc.data()?['savedProducts'] ?? []);
      if (savedProducts.contains(productId)) {
        savedProducts.remove(productId);
      } else {
        savedProducts.add(productId);
      }
      await _firestore.collection('users').doc(uid).update({
        'savedProducts': savedProducts,
      });
    }
  }

  // Get auth error message in Turkish
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayitli kullanici bulunamadi.';
      case 'wrong-password':
        return 'Yanlis sifre girdiniz.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullaniliyor.';
      case 'weak-password':
        return 'Sifre cok zayif. En az 6 karakter kullanin.';
      case 'invalid-email':
        return 'Gecersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre disi birakilmis.';
      case 'too-many-requests':
        return 'Cok fazla deneme yaptiniz. Lutfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu islem simdilik kullanilamaz.';
      case 'network-request-failed':
        return 'Baglanti hatasi. Internet baglantinizi kontrol edin.';
      case 'google-sign-in-failed':
        return e.message ?? 'Google ile giris yapilamadi.';
      case 'invalid-credential':
        return 'E-posta veya sifre hatali.';
      default:
        return 'Bir hata olustu: ${e.message}';
    }
  }
}
