import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oturum tanılama + manuel çıkış bayrağı.
///
/// İKİ amacı var:
///  1. `explicitLogout` bayrağı: kullanıcı GERÇEKTEN manuel çıkış yaptıysa
///     (veya hesabını sildiyse) işaretlenir. Cold start'ta currentUser null
///     olduğunda, bu bayrak true ise oturum geri-yükleme beklenmeden login
///     ekranı gösterilebilir. false ise restore tamamlanana kadar beklenir.
///  2. Debug kayıtları (`lastRoute`, `lastRouteReason`, `lastAuthUid`, ...):
///     PC/logcat olmadan, cihaz üstünde "neden login'e düştüm?" sorusunun
///     yanıtını görebilmek için SharedPreferences'a yazılır.
///
/// ÖNEMLİ: `explicitLogout` dışındaki hiçbir kayıt login/route kararını
/// ETKİLEMEZ — yalnız teşhis amaçlıdır. Tüm yazımlar best-effort'tur; hata
/// yutulur, hiçbir koşulda oturum akışını bloklamaz.
class SessionDiagnostics {
  SessionDiagnostics._();

  static const String _kExplicitLogout = 'session_explicit_logout';
  static const String _kLastLogoutAt = 'session_last_logout_at';
  static const String _kLastAuthUid = 'session_last_auth_uid';
  static const String _kLastAuthEmail = 'session_last_auth_email';
  static const String _kLastAuthProvider = 'session_last_auth_provider';
  static const String _kLastAuthSeenAt = 'session_last_auth_seen_at';
  static const String _kLastRoute = 'session_last_route';
  static const String _kLastRouteReason = 'session_last_route_reason';
  static const String _kLastRestoreResult = 'session_last_restore_result';

  /// Manuel çıkış / hesap silme anında çağrılır. Bir sonraki cold start'ta
  /// AuthGate, oturum geri-yüklemeyi beklemeden login ekranı gösterir.
  static Future<void> markExplicitLogout() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kExplicitLogout, true);
      await p.setString(_kLastLogoutAt, DateTime.now().toIso8601String());
    } catch (_) {/* best-effort */}
  }

  /// Başarılı giriş (e-posta/Google/misafir) sonrası çağrılır.
  static Future<void> clearExplicitLogout() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kExplicitLogout, false);
    } catch (_) {/* best-effort */}
  }

  static Future<bool> isExplicitLogout() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_kExplicitLogout) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Cold start'ta geri yüklenmesi BEKLENEN bir oturum var mı?
  /// `true` → daha önce bir kullanıcı görüldü ve manuel çıkış yapılmadı;
  /// AuthGate restore timeout'unda login'e düşmek yerine beklemeyi uzatır.
  /// (Ör. Play Store güncellemesi sonrası ilk soğuk açılışta restore 8 sn'yi
  /// aşabiliyor — kullanıcı "otomatik çıkış yapıldı" sanıyordu.)
  static Future<bool> expectsPersistedSession() async {
    try {
      final p = await SharedPreferences.getInstance();
      final explicit = p.getBool(_kExplicitLogout) ?? false;
      if (explicit) return false;
      final lastUid = p.getString(_kLastAuthUid) ?? '';
      return lastUid.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Oturumdaki kullanıcı görüldüğünde son kimlik bilgilerini kaydeder.
  /// Canlı bir oturum görülmesi, önceki manuel çıkış işaretini de geçersiz
  /// kılar — yarım kalmış logout (işaret yazıldı ama signOut tamamlanmadı)
  /// senaryosunda bayat bayrak bir sonraki açılışta login'e düşürmesin.
  static Future<void> recordAuthSeen(User user) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool(_kExplicitLogout) ?? false) {
        await p.setBool(_kExplicitLogout, false);
      }
      await p.setString(_kLastAuthUid, user.uid);
      await p.setString(
        _kLastAuthEmail,
        user.isAnonymous ? 'anonim' : (user.email ?? '—'),
      );
      final provider = user.isAnonymous
          ? 'anonymous'
          : (user.providerData.isNotEmpty
              ? user.providerData.first.providerId
              : 'password');
      await p.setString(_kLastAuthProvider, provider);
      await p.setString(_kLastAuthSeenAt, DateTime.now().toIso8601String());
    } catch (_) {/* best-effort */}
  }

  /// AuthGate'in verdiği son route kararını kaydeder (debug amaçlı).
  static Future<void> recordRoute(String route, String reason) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kLastRoute, route);
      await p.setString(_kLastRouteReason, reason);
    } catch (_) {/* best-effort */}
  }

  /// Oturum geri-yükleme sonucunu kaydeder (ör. `user_found:restored`).
  static Future<void> recordRestoreResult(String result) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kLastRestoreResult, result);
    } catch (_) {/* best-effort */}
  }

  /// Ayarlar > Hakkında içindeki debug kartının okuduğu anlık görüntü.
  static Future<Map<String, String>> snapshot() async {
    try {
      final p = await SharedPreferences.getInstance();
      return <String, String>{
        'lastAuthUid': p.getString(_kLastAuthUid) ?? '—',
        'lastAuthEmail': p.getString(_kLastAuthEmail) ?? '—',
        'lastAuthProvider': p.getString(_kLastAuthProvider) ?? '—',
        'lastAuthSeenAt': p.getString(_kLastAuthSeenAt) ?? '—',
        'lastRoute': p.getString(_kLastRoute) ?? '—',
        'lastRouteReason': p.getString(_kLastRouteReason) ?? '—',
        'lastAuthRestoreResult': p.getString(_kLastRestoreResult) ?? '—',
        'lastExplicitLogout': (p.getBool(_kExplicitLogout) ?? false).toString(),
        'lastLogoutAt': p.getString(_kLastLogoutAt) ?? '—',
      };
    } catch (_) {
      return const <String, String>{};
    }
  }
}
