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

  Stream<UserModel?> watchUserModel(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  String _generateInviteCode(String uid) {
    final normalized = uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (normalized.length >= 6) {
      return normalized.substring(0, 6).toUpperCase();
    }
    return uid.substring(0, uid.length.clamp(1, 6)).toUpperCase();
  }

  String? _normalizeUsername(String? username) {
    final normalized = username?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<void> ensureUsernameAvailable(String username) async {
    final reservedDoc = await _firestore.collection('usernames').doc(username).get();
    if (reservedDoc.exists) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'Bu kullanıcı adı zaten kullanılıyor.',
      );
    }

    final existing = await SafeQueryBuilder.safeWhere(
      _firestore.collection('users'),
      'username',
      username,
      expectedType: String,
    ).limit(1).get();

    if (existing.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'Bu kullanıcı adı zaten kullanılıyor.',
      );
    }
  }

  // Email/Password Sign In
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
    String? cityCode,
    String? cityName,
    String? neighborhood,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final firebaseUser = credential.user!;
        await firebaseUser.reload();
        final refreshedUser = _auth.currentUser;
        if (refreshedUser == null || !refreshedUser.emailVerified) {
          await signOut();
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Giriş başarısız. Lütfen önce e-postanızı doğrulayın.',
          );
        }

        await _updateLastLogin(firebaseUser.uid);
        if ((cityName ?? '').trim().isNotEmpty) {
          await _firestore.collection('users').doc(firebaseUser.uid).set({
            'cityCode': cityCode,
            'cityName': cityName,
            'city': cityName,
            'neighborhood': neighborhood,
          }, SetOptions(merge: true));
        }
        return await getUserModel(firebaseUser.uid);
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
    String? cityCode,
    String? cityName,
    String? username,
    String? neighborhood,
    String legalConsentVersion = 'v1.0',
  }) async {
    try {
      final normalizedUsername = _normalizeUsername(username);
      if (normalizedUsername == null) {
        throw FirebaseAuthException(
          code: 'invalid-username',
          message: 'Geçerli bir kullanıcı adı girin.',
        );
      }

      await ensureUsernameAvailable(normalizedUsername);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final firebaseUser = credential.user!;
        final normalizedInviteCode =
            inviteCode?.trim().toUpperCase().replaceAll(' ', '');
        final newInviteCode = _generateInviteCode(firebaseUser.uid);
        await firebaseUser.updateDisplayName(name);

        String? inviterId;
        if (normalizedInviteCode != null && normalizedInviteCode.isNotEmpty) {
          final inviterQuery = SafeQueryBuilder.safeWhere(
            _firestore.collection('users'),
            'inviteCode',
            normalizedInviteCode,
            expectedType: String,
          );
          final inviterSnapshot = await inviterQuery.limit(1).get();
          if (inviterSnapshot.docs.isNotEmpty) {
            inviterId = inviterSnapshot.docs.first.id;
          }
        }

        final user = UserModel(
          uid: firebaseUser.uid,
          email: email,
          name: name,
          cityCode: cityCode,
          cityName: cityName,
          city: cityName,
          username: normalizedUsername,
          lastUsernameChange: Timestamp.now(),
          neighborhood: neighborhood,
          inviteCode: newInviteCode,
          invitedBy: inviterId,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        final batch = _firestore.batch();
        final userRef = _firestore.collection('users').doc(firebaseUser.uid);
        batch.set(userRef, {
          ...user.toFirestore(),
          'termsAcceptedAt': FieldValue.serverTimestamp(),
          'legalConsentVersion': legalConsentVersion,
          'displayName': normalizedUsername,
          'photoURL': '',
          'city': cityName,
          'username': normalizedUsername,
          'lastUsernameChange': FieldValue.serverTimestamp(),
          'neighborhood': neighborhood,
          'totalPoints': 0,
          'weeklyPoints': 0,
          'monthlyPoints': 0,
          'streakDays': 0,
          'trustScorePercent': 0,
          'trustTotalVotes': 0,
          'trustVerifiedTotal': 0,
          'trustWrongTotal': 0,
          'trustScoreStatus': 'veri_az',
          'trustScore': 0.0,
          'level': 'Gözlemci',
        }, SetOptions(merge: true));

        batch.set(_firestore.collection('usernames').doc(normalizedUsername), {
          'uid': firebaseUser.uid,
          'username': normalizedUsername,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (inviterId != null) {
          batch.update(userRef, {
            'invitedBy': inviterId,
          });
          batch.update(_firestore.collection('users').doc(inviterId), {
            'inviteCount': FieldValue.increment(1),
            'points': FieldValue.increment(AppConstants.pointsForInvite),
          });
        }

        await batch.commit();
        await firebaseUser.sendEmailVerification();
        await signOut();
        return user;
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Google Sign In
  Future<UserModel?> signInWithGoogle({
    bool recordLegalConsent = false,
    String legalConsentVersion = 'v1.0',
  }) async {
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
            name: user.displayName ?? 'Kullanıcı',
            photoUrl: user.photoURL,
            inviteCode: _generateInviteCode(user.uid),
            username: _normalizeUsername(user.displayName) ?? _normalizeUsername(user.email?.split('@').first) ?? user.uid,
            lastUsernameChange: Timestamp.now(),
            city: null,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );

          final batch = _firestore.batch();
          batch.set(_firestore.collection('users').doc(user.uid), {
            ...newUser.toFirestore(),
            'displayName': newUser.username,
            'photoURL': user.photoURL ?? '',
            'city': null,
            'username': newUser.username,
            'lastUsernameChange': FieldValue.serverTimestamp(),
            'totalPoints': 0,
            'weeklyPoints': 0,
            'monthlyPoints': 0,
            'streakDays': 0,
            'trustScorePercent': 0,
            'trustScore': 0.0,
            'level': 'Gözlemci',
            if (recordLegalConsent) 'termsAcceptedAt': FieldValue.serverTimestamp(),
            if (recordLegalConsent) 'legalConsentVersion': legalConsentVersion,
          }, SetOptions(merge: true));
          batch.set(_firestore.collection('usernames').doc(newUser.username), {
            'uid': user.uid,
            'username': newUser.username,
            'createdAt': FieldValue.serverTimestamp(),
          });
          await batch.commit();
          return newUser;
        } else {
          final data = docSnapshot.data();
          final updates = <String, dynamic>{};
          if (data != null && data['inviteCode'] == null) {
            updates['inviteCode'] = _generateInviteCode(user.uid);
          }
          if (updates.isNotEmpty) {
            await _firestore.collection('users').doc(user.uid).update(updates);
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
        message: 'Google ile giriş yapılamadı: $e',
      );
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Doğrulama e-postası gönderilecek kullanıcı bulunamadı.',
        );
      }

      await user.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Doğrulama e-postası gönderilecek kullanıcı bulunamadı.',
        );
      }

      if (refreshedUser.emailVerified) {
        throw FirebaseAuthException(
          code: 'email-already-verified',
          message: 'Bu e-posta adresi zaten doğrulanmış.',
        );
      }

      await refreshedUser.sendEmailVerification();
    } finally {
      await signOut();
    }
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

  Future<void> updateUsername({
    required String uid,
    required String username,
    Timestamp? changedAt,
  }) async {
    final normalizedUsername = _normalizeUsername(username);
    if (normalizedUsername == null) {
      throw FirebaseAuthException(
        code: 'invalid-username',
        message: 'Geçerli bir kullanıcı adı girin.',
      );
    }

    final userRef = _firestore.collection('users').doc(uid);
    final userDoc = await userRef.get();
    final currentUsername = _normalizeUsername(userDoc.data()?['username'] as String?);
    final usernameChangedAt = changedAt ?? Timestamp.now();

    if (currentUsername == normalizedUsername) {
      await userRef.set({
        'username': normalizedUsername,
        'displayName': normalizedUsername,
        'lastUsernameChange': usernameChangedAt,
      }, SetOptions(merge: true));
      return;
    }

    await ensureUsernameAvailable(normalizedUsername);

    final batch = _firestore.batch();
    batch.set(userRef, {
      'username': normalizedUsername,
      'displayName': normalizedUsername,
      'lastUsernameChange': usernameChangedAt,
    }, SetOptions(merge: true));
    batch.set(_firestore.collection('usernames').doc(normalizedUsername), {
      'uid': uid,
      'username': normalizedUsername,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUsernameChange': usernameChangedAt,
    });

    if (currentUsername != null && currentUsername.isNotEmpty) {
      batch.delete(_firestore.collection('usernames').doc(currentUsername));
    }

    await batch.commit();
  }

  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Aktif kullanıcı bulunamadı.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
  }

  Future<void> updateEmailWithReauth({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null || (user.email?.trim().isEmpty ?? true)) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Aktif kullanıcı bulunamadı.',
      );
    }

    final normalizedEmail = newEmail.trim();
    await reauthenticate(email: user.email!.trim(), password: currentPassword);
    await user.updateEmail(normalizedEmail);
    await _firestore.collection('users').doc(user.uid).set({
      'email': normalizedEmail,
    }, SetOptions(merge: true));
  }

  Future<void> updatePasswordWithReauth({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || (user.email?.trim().isEmpty ?? true)) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Aktif kullanıcı bulunamadı.',
      );
    }

    await reauthenticate(email: user.email!.trim(), password: currentPassword);
    await user.updatePassword(newPassword.trim());
  }

  Future<void> makeAdmin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isAdmin': true,
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

  static String mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre girdiniz.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'requires-recent-login':
        return 'Lütfen önce kimliğinizi yeniden doğrulayın.';
      case 'email-change-needs-verification':
        return 'Yeni e-posta için doğrulama gerekiyor.';
      case 'email-not-verified':
        return 'Giriş başarısız. Lütfen önce e-postanızı doğrulayın.';
      case 'email-already-verified':
        return 'Bu e-posta adresi zaten doğrulanmış.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şimdilik kullanılamaz.';
      case 'network-request-failed':
        return 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.';
      case 'google-sign-in-failed':
        return e.message ?? 'Google ile giriş yapılamadı.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'password-renewal-period-save-failed':
        return 'Şifre yenileme hatırlatıcısı kaydedilemedi.';
      case 'username-already-in-use':
        return 'Bu kullanıcı adı zaten kullanılıyor.';
      case 'invalid-username':
        return 'Geçerli bir kullanıcı adı girin.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }

  // Get auth error message in Turkish
  String getErrorMessage(FirebaseAuthException e) => mapAuthError(e);
}
