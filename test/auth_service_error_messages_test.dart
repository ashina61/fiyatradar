import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fiyatradar/services/auth_service.dart';

void main() {
  test('maps known Firebase auth errors to Turkish messages', () {
    expect(
      AuthService.mapAuthError(FirebaseAuthException(code: 'wrong-password')),
      'Yanlış şifre girdiniz.',
    );
    expect(
      AuthService.mapAuthError(FirebaseAuthException(code: 'invalid-email')),
      'Geçersiz e-posta adresi.',
    );
    expect(
      AuthService.mapAuthError(FirebaseAuthException(code: 'network-request-failed')),
      'Bağlantı hatası. İnternet bağlantınızı kontrol edin.',
    );
  });

  test('uses Firebase message for google-sign-in-failed when provided', () {
    final msg = AuthService.mapAuthError(
      FirebaseAuthException(code: 'google-sign-in-failed', message: 'Özel hata'),
    );
    expect(msg, 'Özel hata');
  });

  test('falls back to generic message for unknown code', () {
    final msg = AuthService.mapAuthError(
      FirebaseAuthException(code: 'unknown-code', message: 'Bilinmeyen'),
    );
    expect(msg, 'Bir hata oluştu: Bilinmeyen');
  });
}
