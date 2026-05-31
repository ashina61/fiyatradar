import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/price_reporting.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';
import '../services/messaging_service.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
import 'main_screen.dart';
import 'paywall_screen.dart';
import 'product_detail_screen.dart';
import 'widgets/profile_avatar.dart';

/// Shared chrome for a "profile sub-page": back button + header + scrolling body.
class _ProfileSubScaffold extends StatelessWidget {
  const _ProfileSubScaffold({
    required this.overline,
    required this.title,
    required this.child,
  });
  final String overline;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  FRIconChip(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: FRPageHeader(
                overline: overline,
                title: title,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ─── Profile info ────────────────────────────────────────────────────────────

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});
  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  Uint8List? _pendingProfileImage;
  String? _pendingProfileImageMimeType;
  String? _pendingProfileImagePath;
  bool? _pendingProfileImageExists;
  int? _pendingProfileImageFileSize;
  bool _saving = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final s = AppStateScope.of(context);
      _nameCtrl.text = s.displayName;
      _userCtrl.text = s.username;
      _phoneCtrl.text = s.phoneNumber ?? '';
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(AppState state) async {
    setState(() => _saving = true);
    try {
      String? imageUrl;
      String? imagePath;
      final pending = _pendingProfileImage;
      if (pending != null) {
        final user = state.user;
        if (user == null) {
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'unauthenticated',
            message: 'Profil fotoğrafını yüklemek için giriş yapmalısın.',
          );
        }
        if (pending.length > 5 * 1024 * 1024) {
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'image-too-large',
            message: 'Profil fotoğrafı 5 MB üstünde.',
          );
        }
        _logProfileUploadContext(user.uid);
        // Retry transient storage failures (network blips, token-refresh races)
        // and write the Auth profile URL too; some widgets / rules key off
        // FirebaseAuth.currentUser.photoURL while Firestore catches up.
        Object? lastError;
        ({String url, String path})? res;
        for (var attempt = 0; attempt < 3; attempt++) {
          try {
            res = await FirebaseService.instance
                .uploadUserProfileImage(
                  uid: user.uid,
                  bytes: pending,
                  contentType: _pendingProfileImageMimeType,
                )
                .timeout(const Duration(seconds: 45));
            lastError = null;
            break;
          } catch (e, st) {
            lastError = e;
            _logProfileUploadError(e, st, attempt: attempt + 1);
            if (!_shouldRetryProfileUpload(e) || attempt == 2) {
              break;
            }
            await Future<void>.delayed(
              Duration(milliseconds: 700 * (attempt + 1)),
            );
          }
        }
        if (res == null) {
          throw lastError ??
              FirebaseException(
                plugin: 'firebase_storage',
                code: 'unknown',
                message: 'Storage upload returned no result.',
              );
        }
        imageUrl = _withProfileAvatarCacheBust(res.url);
        imagePath = res.path;
        try {
          await user.updatePhotoURL(imageUrl);
        } catch (_) {
          // Firestore is the source of truth for app avatars; Auth photoURL is
          // a best-effort mirror for Firebase-backed widgets.
        }
        final oldPath = state.profileImagePath;
        if (oldPath != null && oldPath.isNotEmpty && oldPath != imagePath) {
          await FirebaseService.instance.deleteStorageFile(oldPath);
        }
      }
      await state.updateProfileSettings(
        displayName: _nameCtrl.text,
        username: _userCtrl.text,
        phoneNumber: _phoneCtrl.text,
        profileImageUrl: imageUrl,
        profileImagePath: imagePath,
      );
      if (!mounted) return;
      setState(() {
        _pendingProfileImage = null;
        _pendingProfileImageMimeType = null;
        _pendingProfileImagePath = null;
        _pendingProfileImageExists = null;
        _pendingProfileImageFileSize = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pending == null
                ? 'Profil bilgileri güncellendi.'
                : 'Profil fotoğrafı güncellendi.',
          ),
        ),
      );
    } catch (e, st) {
      _logProfileUploadError(e, st);
      if (!mounted) return;
      final message = _describeProfileError(e);
      if (message == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _withProfileAvatarCacheBust(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri
        .replace(
          queryParameters: <String, String>{
            ...uri.queryParameters,
            'frAvatarUpdated': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        )
        .toString();
  }

  void _logProfileUploadError(
    Object error,
    StackTrace stackTrace, {
    int? attempt,
  }) {
    final prefix = attempt == null
        ? '[profile-image-upload]'
        : '[profile-image-upload attempt=$attempt]';
    if (error is FirebaseException) {
      debugPrint(
        '$prefix FirebaseException plugin=${error.plugin} '
        'code=${error.code} message=${error.message} stackTrace=$stackTrace',
      );
    } else {
      debugPrint('$prefix ${error.runtimeType}: $error');
    }
    debugPrintStack(label: prefix, stackTrace: stackTrace);
  }

  void _logProfileUploadContext(String stateUid) {
    final authUser = FirebaseAuth.instance.currentUser;
    debugPrint(
      '[profile-image-upload] auth uid=${authUser?.uid} '
      'email=${authUser?.email} stateUid=$stateUid',
    );
    debugPrint(
      '[profile-image-upload] selected file path=${_pendingProfileImagePath ?? '-'} '
      'exists=${_pendingProfileImageExists ?? false} '
      'fileSize=${_pendingProfileImageFileSize ?? _pendingProfileImage?.length ?? 0} '
      'bytes=${_pendingProfileImage?.length ?? 0} '
      'mime=${_pendingProfileImageMimeType ?? '-'}',
    );
  }

  bool _shouldRetryProfileUpload(Object error) {
    if (error is TimeoutException) return true;
    if (error is! FirebaseException || error.plugin != 'firebase_storage') {
      return false;
    }
    return switch (error.code) {
      'retry-limit-exceeded' || 'unknown' => true,
      _ => false,
    };
  }

  String? _describeProfileError(Object e) {
    if (e is FirebaseException && e.plugin == 'firebase_storage') {
      switch (e.code) {
        case 'unauthenticated':
          return 'Profil güncellenemedi: tekrar giriş yapman gerekiyor.';
        case 'unauthorized':
          return 'Profil güncellenemedi: bu fotoğrafı yüklemeye yetkin yok.';
        case 'canceled':
          return null;
        case 'object-not-found':
          return 'Profil fotoğrafı yüklenemedi: hedef bulut depolama yolu bulunamadı.';
        case 'quota-exceeded':
          return 'Profil fotoğrafı yüklenemedi: depolama kotası dolmuş, kısa süre sonra tekrar dene.';
        case 'image-too-large':
          return 'Profil fotoğrafı 5 MB üstünde. Daha küçük bir görsel seç.';
        case 'retry-limit-exceeded':
          return 'Profil fotoğrafı yüklenemedi: bağlantı zaman aşımına uğradı. Birazdan tekrar dene.';
        case 'unknown':
          if (kDebugMode) {
            final detail = (e.message ?? '').trim();
            return detail.isEmpty
                ? 'Profil fotoğrafı yüklenemedi: ${e.plugin}/${e.code}.'
                : 'Profil fotoğrafı yüklenemedi: ${e.plugin}/${e.code}: $detail';
          }
          return 'Profil fotoğrafı yüklenemedi: Firebase beklenmeyen bir hata döndürdü. Ayrıntı teknik kayıtlara yazıldı.';
      }
      final detail = (e.message ?? '').trim();
      return detail.isEmpty
          ? 'Profil fotoğrafı yüklenemedi (${e.code}). Tekrar dene.'
          : 'Profil fotoğrafı yüklenemedi (${e.code}): $detail';
    }
    if (e is FirebaseException && e.plugin == 'cloud_firestore') {
      if (e.code == 'permission-denied') {
        if (kDebugMode) {
          final detail = (e.message ?? '').trim();
          return detail.isEmpty
              ? 'Profil güncellenemedi: ${e.plugin}/${e.code}.'
              : 'Profil güncellenemedi: ${e.plugin}/${e.code}: $detail';
        }
        return 'Profil güncellenemedi: profil alanlarını güncelleme yetkisi reddedildi.';
      }
      final detail = (e.message ?? '').trim();
      return detail.isEmpty
          ? 'Profil güncellenemedi (${e.code}).'
          : 'Profil güncellenemedi (${e.code}): $detail';
    }
    if (e is TimeoutException) {
      return 'Profil fotoğrafı yüklenemedi: işlem zaman aşımına uğradı. Birazdan tekrar dene.';
    }
    if (e is StateError) {
      return e.message;
    }
    return 'Profil güncellenemedi: $e';
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    XFile? x;
    try {
      x = await picker.pickImage(
        source: ImageSource.gallery,
        // 720px square is more than enough for the avatar tile and keeps
        // mobile uploads small, which avoids slow-network timeout failures.
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 82,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Galeri açılamadı: $e')),
      );
      return;
    }
    if (x == null) return;
    final mimeType = x.mimeType;
    final filePath = x.path;
    var fileExists = false;
    var fileSize = 0;
    if (filePath.isNotEmpty) {
      final file = File(filePath);
      fileExists = await file.exists();
      if (fileExists) {
        fileSize = await file.length();
      }
    }
    final bytes = await x.readAsBytes();
    debugPrint(
      '[profile-image-upload] picked file path=$filePath exists=$fileExists '
      'fileSize=$fileSize bytes=${bytes.length} mime=${mimeType ?? '-'}',
    );
    if (!mounted) return;
    if (bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Seçtiğin dosya okunamadı, başka bir görsel dene.')),
      );
      return;
    }
    if (bytes.length > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı 5 MB üstünde.')),
      );
      return;
    }
    setState(() {
      _pendingProfileImage = bytes;
      _pendingProfileImageMimeType = mimeType;
      _pendingProfileImagePath = filePath;
      _pendingProfileImageExists = fileExists;
      _pendingProfileImageFileSize = fileSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return _ProfileSubScaffold(
      overline: 'KİMLİK',
      title: 'Profil bilgileri',
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        children: [
          _avatarEditor(state),
          const SizedBox(height: 14),
          _field('Ad Soyad', _nameCtrl, Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _field('Kullanıcı adı', _userCtrl, Icons.alternate_email_rounded),
          _usernameCooldownHint(state),
          const SizedBox(height: 12),
          _field('Telefon (opsiyonel)', _phoneCtrl, Icons.phone_iphone_rounded,
              keyboard: TextInputType.phone),
          const SizedBox(height: 20),
          FRCta(
            label: _saving ? 'Kaydediliyor…' : 'Kaydet',
            icon: Icons.check_rounded,
            onTap: _saving ? null : () => _save(state),
          ),
        ],
      ),
    );
  }

  Widget _usernameCooldownHint(AppState state) {
    final next = state.nextUsernameChangeAvailableAt;
    // İlk değişiklik / cooldown bitmişse uyarı yerine kısa bir bilgi notu;
    // cooldown sürüyorsa kullanıcının kaç gün sonra tekrar deneyebileceğini
    // göster.
    if (next == null || !next.isAfter(DateTime.now())) {
      return Padding(
        padding: const EdgeInsets.only(top: 6), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        child: Text(
          'Kullanıcı adı 3 ayda bir değiştirilebilir.',
          style: frText(11, FontWeight.w600, color: FR.ink3, height: 1.4),
        ),
      );
    }
    final daysLeft = state.daysUntilUsernameChangeAllowed;
    final dateLabel = '${next.day}.${next.month}.${next.year}';
    return Padding(
      padding: const EdgeInsets.only(top: 6), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        decoration: BoxDecoration(
          color: FR.surfaceLo,
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: FR.warn.withOpacity(.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_clock_rounded, size: 14, color: FR.warn),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Kullanıcı adı 3 ayda bir değişebiliyor. '
                'Tekrar değiştirebileceğin tarih: $dateLabel '
                '(${daysLeft > 0 ? "$daysLeft gün kaldı" : "yakında"}).',
                style: frText(11, FontWeight.w700, color: FR.ink2, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, IconData icon,
      {TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: frText(11.5, FontWeight.w800, color: FR.ink3, letter: .4)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: keyboard,
          style: frText(14, FontWeight.w700),
          cursorColor: FR.gold,
          decoration: InputDecoration(prefixIcon: Icon(icon, color: FR.ink3, size: 19)),
        ),
      ],
    );
  }

  Widget _avatarEditor(AppState state) {
    final hasPending = _pendingProfileImage != null;
    return InkWell(
      onTap: _saving ? null : _pickProfileImage,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        decoration: frSurface(radius: FRRad.l),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: FRRad.all(18),
                border: Border.all(color: FR.hairline),
                color: FR.surfaceHi,
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPending
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_pendingProfileImage!, fit: BoxFit.cover),
                        if (_saving)
                          ColoredBox(
                            color: Colors.black.withOpacity(.34),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: FR.gold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : ProfileAvatarImage(
                      imageUrl: state.profileImageUrl,
                      displayName: state.displayName,
                      size: 64,
                      radius: 18,
                      cacheWidth: 192,
                      initialStyle: frDisplay(
                        24,
                        FontWeight.w800,
                        color: FR.gold,
                      ),
                      fallbackColor: FR.surfaceHi,
                      onImageError: (url) => state.clearCachedProfileImageUrl(
                        failedUrl: url,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profil fotoğrafı', style: frText(13, FontWeight.w800)),
                  Text(
                    _saving && hasPending
                        ? 'Yükleniyor…'
                        : (hasPending ? 'Kaydet ile yüklenir' : 'Galeri seç'),
                    style: frText(11.5, FontWeight.w600, color: FR.ink3),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 18, color: FR.ink3),
          ],
        ),
      ),
    );
  }
}

// ─── Notification preferences ───────────────────────────────────────────────

class NotificationPrefsScreen extends StatelessWidget {
  const NotificationPrefsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final s = AppStrings.of(context);
    return _ProfileSubScaffold(
      overline: s.t('notifPrefs.overline'),
      title: s.t('notifPrefs.title'),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
        children: [
          _ToggleRow(
            icon: Icons.notifications_active_rounded,
            title: s.t('notifPrefs.push'),
            subtitle: s.t('notifPrefs.push.sub'),
            value: state.pushNotificationsEnabled,
            onChanged: (v) =>
                state.updateNotificationSettings(pushEnabled: v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.price_change_rounded,
            title: s.t('notifPrefs.priceAlerts'),
            subtitle: s.t('notifPrefs.priceAlerts.sub'),
            value: state.priceAlertsEnabled,
            onChanged: (v) =>
                state.updateNotificationSettings(priceAlertsEnabled: v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.radar_rounded,
            title: s.t('notifPrefs.regional'),
            subtitle: s.t('notifPrefs.regional.sub'),
            value: state.regionalDropPushEnabled,
            onChanged: (v) => state.updateNotificationSettings(
                regionalDropPushEnabled: v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.verified_rounded,
            title: s.t('notifPrefs.verifications'),
            subtitle: s.t('notifPrefs.verifications.sub'),
            value: state.verificationsEnabled,
            onChanged: (v) => state.updateNotificationSettings(
                verificationsEnabled: v),
          ),
          const SizedBox(height: 10),
          // Haftalık özet — kişisel tercih (admin panelindeki sistem ayarından
          // ayrıdır). Pro kullanıcı açıp kapatabilir; Free kullanıcı kilitli
          // Pro satırı görür ve dokununca Pro ekranına yönlenir.
          _WeeklySummaryRow(state: state),
        ],
      ),
    );
  }
}

/// Bildirim tercihlerindeki "Haftalık özet" satırı.
///
/// - Pro: çalışan toggle, `settings.weeklySummaryEnabled` alanına bağlı
///   (varsayılan açık). Değişince snackbar ile teyit verir.
/// - Free: kilitli/Pro görünür; toggle yerine PRO rozeti + kilit ikonu,
///   tüm satır Pro ekranına yönlendirir, hiçbir ayar yazılmaz.
class _WeeklySummaryRow extends StatelessWidget {
  const _WeeklySummaryRow({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (state.premium.isActive) {
      return _ToggleRow(
        icon: Icons.summarize_rounded,
        title: s.t('notifPrefs.weekly'),
        subtitle: s.t('notifPrefs.weekly.proSub'),
        value: state.weeklySummaryEnabled,
        onChanged: (v) async {
          await state.updateNotificationSettings(weeklySummaryEnabled: v);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.t(
                  v ? 'notifPrefs.weekly.on' : 'notifPrefs.weekly.off')),
            ),
          );
        },
      );
    }

    // Free kullanıcı: kilitli Pro satırı.
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      ),
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsetsDirectional.all(14),
        decoration: frSurface(radius: FRRad.l),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: FR.surfaceHi,
                borderRadius: FRRad.all(12),
                border: Border.all(color: FR.hairline),
              ),
              child: Icon(Icons.summarize_rounded, color: FR.ink3, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(s.t('notifPrefs.weekly'),
                            style: frText(13.5, FontWeight.w800)),
                      ),
                      const SizedBox(width: 8),
                      const FRProBadge(compact: true),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(s.t('notifPrefs.weekly.freeSub'),
                      style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.lock_outline_rounded, color: FR.ink3, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── About & release notes ──────────────────────────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openExternalLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı. Lütfen tekrar dene.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileSubScaffold(
      overline: 'UYGULAMA',
      title: 'Hakkında',
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: frSurface(radius: FRRad.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 64,
                  child: Image.asset(
                    'assets/images/fiyatradar_logo.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Premium topluluk destekli market fiyat zekâsı.',
                  style: frText(12.5, FontWeight.w600, color: FR.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.description_outlined,
            title: 'Kullanıcı sözleşmesi',
            subtitle: 'fiyatradar.netlify.app/kullanici-sozlesmesi',
            onTap: () => _openExternalLink(
                context, 'https://fiyatradar.netlify.app/kullanici-sozlesmesi'),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik sözleşmesi',
            subtitle: 'fiyatradar.netlify.app/gizlilik-politikasi',
            onTap: () => _openExternalLink(
                context, 'https://fiyatradar.netlify.app/gizlilik-politikasi'),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.delete_outline_rounded,
            title: 'Hesap ve veri silme talebi',
            subtitle: 'fiyatradar.netlify.app/hesap-silme',
            onTap: () => _openExternalLink(
                context, 'https://fiyatradar.netlify.app/hesap-silme'),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.gavel_outlined,
            title: 'Abonelik ve geri ödeme koşulları',
            subtitle: 'Play Store abonelik kuralları',
            onTap: () => _openExternalLink(
                context, 'https://support.google.com/googleplay/answer/7018481'),
          ),
        ],
      ),
    );
  }
}

/// Yardım ve SSS — kullanıcı güvenini artıran kısa, sade Türkçe açıklamalar.
/// Topluluk verisi, güven yüzdesi, puan/seviye, alarm ve Premium gibi konuları
/// makale uzunluğuna kaçmadan cevaplar.
class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  static const _items = <(String, String)>[
    (
      'FiyatRadar nasıl çalışır?',
      'Topluluk üyeleri markette gördükleri fiyatları paylaşır. Sen de '
          'bölgendeki en güncel fiyatları görür, sepetini marketlere göre '
          'karşılaştırır ve fiyat düşünce bildirim alırsın.',
    ),
    (
      'Fiyatlar nasıl eklenir?',
      'Alttaki “+” sekmesinden ürünü, fiyatı ve marketi seç; istersen raf '
          'fotoğrafı da ekle. Her onaylı katkı sana +10 puan kazandırır.',
    ),
    (
      'Fiyatlara nasıl güvenebilirim?',
      'Her fiyat topluluk tarafından doğrulanabilir. Doğrulanma sayısı, '
          'ekleyen kullanıcının güven skoru ve fotoğraf kanıtı bir fiyatın '
          'güvenilirliğini artırır.',
    ),
    (
      'Güven yüzdesi ne demek?',
      'Bir fiyatın ne kadar doğrulandığını ve güncel/güvenilir olma '
          'ihtimalini özetleyen bir orandır. Daha yüksek güven, fiyatın '
          'topluluk tarafından daha çok teyit edildiğini gösterir.',
    ),
    (
      'Yanlış fiyat görürsem ne yapmalıyım?',
      'Ürün detayında ilgili fiyatın yanındaki “Yanlış fiyat bildir” ile '
          'topluluğa bildirebilir ya da doğru fiyatı ekleyerek güncel '
          'tutabilirsin.',
    ),
    (
      'Fiyat alarmı nasıl çalışır?',
      'Bir ürüne hedef fiyat kurarsın; fiyat o seviyeye inince bildirim '
          'alırsın. Ücretsiz planda en fazla 3 aktif alarm kurabilirsin, '
          'Premium’da sınırsızdır. Bildirim tercihlerini Ayarlar > Bildirim '
          'tercihleri’nden yönetebilirsin.',
    ),
    (
      'Puan nasıl kazanılır, nasıl yükselirim?',
      'Fiyat ekleyerek, fotoğraf ekleyerek ve fiyat doğrulayarak puan '
          'kazanırsın. Puanın arttıkça seviye atlarsın (örn. Mahalle '
          'Gözcüsü → Radar Pilotu). Seviye, topluluğa katkının bir '
          'göstergesidir.',
    ),
    (
      'Güven skorum nasıl artar?',
      'Doğru fiyatlar ekleyip topluluk doğrulamalarına katıldıkça güven '
          'skorun yükselir. Yüksek güven skoru, oylarının daha çok '
          'ağırlık taşıması demektir.',
    ),
    (
      'Pro rozeti sıralamamı etkiler mi?',
      'Hayır. Pro rozeti sıralamanı yükseltmez; yalnızca Premium üyelik '
          'göstergesidir. Liderlik tablosu sadece gerçek katkılarına göre '
          'hesaplanır.',
    ),
    (
      'Premium ne sağlar?',
      'Reklamsız kullanım, sınırsız fiyat alarmı, 12 aya kadar fiyat '
          'geçmişi, akıllı sepet karşılaştırması ve Pro rozeti.',
    ),
    (
      'Satın alımı geri yükle ne işe yarar?',
      'Yeni bir cihazda veya uygulamayı yeniden kurduğunda mevcut Premium '
          'aboneliğini geri getirmek için kullanılır. Tekrar ücret alınmaz.',
    ),
    (
      'E-posta doğrulama neden gerekli?',
      'Sahte hesapları ve spam’i önleyip topluluk verisinin güvenilirliğini '
          'korumak için; fiyat ekleme, doğrulama ve puan kazanma gibi '
          'katkılar doğrulanmış hesap ister.',
    ),
    (
      'Misafir kullanıcı neler yapabilir?',
      'Fiyatları görüntüleyebilir ve sepet karşılaştırmasını sınırlı sayıda '
          'deneyebilirsin. Fiyat eklemek, alarm kurmak ve puan kazanmak için '
          'ücretsiz bir hesap açman gerekir.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _ProfileSubScaffold(
      overline: 'DESTEK',
      title: 'Yardım ve SSS',
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: frSurface(radius: FRRad.l),
            child: Text(
              'Bölgendeki gerçek market fiyatlarını gör, sepetini marketlere '
              'göre karşılaştır, fiyat düşünce haber al.',
              style: frText(12.5, FontWeight.w600, color: FR.ink2, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in _items) ...[
            _FaqTile(question: item.$1, answer: item.$2),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: frSurface(radius: FRRad.l),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // ExpansionTile'ın varsayılan ayırıcı çizgilerini kaldır.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
          iconColor: FR.gold,
          collapsedIconColor: FR.ink3,
          title: Text(question, style: frText(13.5, FontWeight.w800)),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(answer,
                  style: frText(12.5, FontWeight.w600,
                      color: FR.ink3, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

/// İletişim ve Destek — sorun, öneri, yanlış fiyat bildirimi ve destek
/// talepleri için. Uygulama içinde teknik debug bilgisi gösterilmez.
class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  // Geçici destek adresi — özel domain doğrulanana kadar gerçek Gmail kutusu.
  static const String _supportEmail = 'fiyatradar.app@gmail.com';

  Future<void> _sendMail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent('FiyatRadar destek talebi')}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      await Clipboard.setData(const ClipboardData(text: _supportEmail));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-posta uygulaması açılamadı. Adres panoya kopyalandı.'),
        ),
      );
    }
  }

  Future<void> _copyMail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Destek adresi panoya kopyalandı.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileSubScaffold(
      overline: 'DESTEK',
      title: 'İletişim ve Destek',
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: frSurface(radius: FRRad.l),
            child: Text(
              'Sorun, öneri, yanlış fiyat bildirimi veya destek taleplerin '
              'için bizimle iletişime geçebilirsin. Genellikle birkaç iş günü '
              'içinde yanıt veriyoruz.',
              style: frText(12.5, FontWeight.w600, color: FR.ink2, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          _HubRow(
            icon: Icons.mail_outline_rounded,
            title: 'E-posta gönder',
            subtitle: _supportEmail,
            onTap: () => _sendMail(context),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.copy_rounded,
            title: 'Destek adresini kopyala',
            subtitle: 'Panoya kopyala',
            onTap: () => _copyMail(context),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: frSurface(radius: FRRad.l),
            child: Text(
              'Yanlış veya güncel olmayan bir fiyat gördüysen, ürün detayındaki '
              '“Yanlış fiyat bildir” ile de hızlıca bildirebilirsin.',
              style: frText(11.5, FontWeight.w600, color: FR.ink3, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class ReleaseNotesScreen extends StatelessWidget {
  const ReleaseNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Newest at the top. Each entry tries to summarise what shipped in
    // user-facing language so the changelog reads like a customer release
    // note rather than an internal commit list.
    const notes = <({String version, String date, List<String> items})>[
      (
        version: 'v1.0.8',
        date: '30 Mayıs 2026',
        items: [
          'Bildirim Merkezi deneyimi yenilendi; her bildirim tipi artık kendi '
              'anlamına uygun yeni bir ikonla geliyor.',
          'Fiyat alarmı bildirimleri daha güvenilir hale getirildi.',
          'Aynı alarm için tekrar eden bildirimler engellendi; aynı olay artık '
              'tek bildirim olarak görünüyor.',
          'Fiyat katkısı ve alarm işlemleri artık Bildirim Merkezi’nde daha '
              'net görünüyor; kendi yaptığın işlemler için telefonuna gereksiz '
              'sistem bildirimi düşmüyor.',
          'Bildirimler için silme ve “tümünü temizle” desteği eklendi; '
              'bildirimi sola kaydırarak da silebilirsin.',
          'Ürün detayından fiyat eklerken ürün artık otomatik seçili geliyor; '
              'tekrar arama yapman gerekmiyor.',
          'Ayarlar ekranı bölümlere ayrılarak daha düzenli ve anlaşılır hale '
              'getirildi.',
          'Haftalık özet bildirimleri için yönetim altyapısı hazırlandı.',
          'Pro kullanıcılar için haftalık özet bildirimi tercihi Bildirim '
              'ayarlarına eklendi; dilediğin zaman açıp kapatabilirsin.',
          'İngilizce dil desteği genişletildi: Ayarlar, Bildirim tercihleri '
              've Bildirim Merkezi ekranları artık İngilizce de görüntülenebiliyor.',
          'Ürün ve fiyat doğrulama etiketleri daha anlaşılır hale getirildi.',
          'Fiyat güven bilgileri topluluk doğrulamasını daha net gösterecek '
              'şekilde düzenlendi.',
          'Onaylı fotoğrafı olan ürünlerde fotoğraf önerme kartı artık '
              'gizleniyor; onaylı görselin üzerinde küçük bir “Onaylı fotoğraf” '
              'rozeti gösteriliyor.',
        ],
      ),
      (
        version: 'v1.0.7',
        date: '27 Mayıs 2026',
        items: [
          'Yardım ve SSS ile İletişim ve Destek ekranları eklendi: nasıl '
              'çalışır, güven yüzdesi, puan ve alarm gibi konular tek yerde; '
              'sorun ve önerilerin için doğrudan bize ulaşabilirsin.',
          'Ana sayfada bölge boşken artık yol gösteren bir ekran var: tek '
              'dokunuşla fiyat ekleyebilir veya bölgeni değiştirebilirsin.',
          'Ana sayfaya “Sepetini karşılaştır” kısayolu geldi — aynı sepet '
              'hangi markette daha ucuz, saniyeler içinde gör.',
          'Ürün detayında “güven yüzdesi” artık tek dokunuşla açıklanıyor; '
              'yanlış fiyat bildirimi daha anlaşılır hale geldi.',
          'Fiyat ekledikten sonra “Katkın yayında” başarı ekranı ve '
              'kazandığın puan net şekilde gösteriliyor.',
          'Fiyat alarmı kurarken ücretsiz planda kalan hakkın görünüyor.',
          'Satın alma ve e-posta (doğrulama / şifre sıfırlama) mesajları '
              'Türkçeleştirildi; tekrar gönderme daha kontrollü.',
          'Premium güvenliği güçlendirildi: üyelik durumu yalnızca sunucu '
              'tarafında doğrulanıyor.',
          'Bölgesel katkı sıralamasında İlçe ve Şehir sekmelerindeki yüklenme '
              'sorunu giderildi.',
          'Performans, kararlılık ve metin iyileştirmeleri yapıldı.',
        ],
      ),
      (
        version: 'v1.0.6',
        date: '26 Mayıs 2026',
        items: [
          'Kategori görselleri zenginleşti: 14 yeni marka-bağımsız çizim '
              'eklendi (armut, kiraz, nar, havuç, brokoli, mısır, mantar, '
              'sucuk, salça, mısır gevreği, patlamış mısır, çöp poşeti, ıslak '
              'mendil, pil). Ayrıca ürünler artık adına göre en uygun görsele '
              'eşleşiyor; eşleşme yoksa aynı kategorideki ürünler tek bir '
              'görsele yığılmak yerine farklı çizimlere dağılıyor.',
          'Premium üyelik ekranı yenilendi: satın alma sonrası "fiyakalı" bir '
              'üyelik kartı (altın madalyon, plan ve yenileme bilgisi) ve '
              'açtığın ayrıcalıkları onay işaretleriyle gösteren "Pro '
              'Ayrıcalıkların" listesi geldi.',
          'Ürün detayında kaydırma takılması giderildi: birkaç fiyat '
              'eklenmiş ürünlerde yukarı kaydırırken liste sıçrayıp yukarı '
              'çıkmayı engelliyordu — bölgesel fiyat ve yorum akışları artık '
              'sabit kalıyor, kaydırma pürüzsüz.',
          'Rozetler artık konuşuyor: rozet listesinde bir rozete dokununca '
              '"nasıl kazanılır" detayı (durum, ödül puanı, açıklama) listenin '
              'içinde açılıyor. Daha önce açıklama en altta görünüp panel '
              'açılınca kayboluyordu.',
          'Profil ekranına görsel cila: kartlara yumuşak derinlik/gölge, '
              'seviye çipi altın gradiente çevrildi, ilerleme çubukları '
              'hizalandı — düzen aynı, his daha premium.',
        ],
      ),
      (
        version: 'v1.0.5',
        date: '25 Mayıs 2026',
        items: [
          'Satın alım geri yükleme artık gerçekten çalışıyor: paywall\'daki '
              '"Satın alımı geri yükle" butonuna basınca "Satın alımlar '
              'kontrol ediliyor…" görünüyor; aktif abonelik bulunursa '
              '"Premium üyeliğin geri yüklendi.", bulunamazsa "Geri '
              'yüklenecek aktif abonelik bulunamadı." mesajı çıkıyor. Eskiden '
              'buton sessizce hiçbir şey yapmıyordu.',
          'Zaten Pro üyeyken paywall artık satış ekranı yerine "Zaten '
              'Premium üyesin" durumunu gösteriyor: "Tüm Pro özelliklere '
              'erişimin aktif." açıklaması ve aboneliğini yeniden eşitlemek '
              'için "Satın alımı tekrar kontrol et" butonu var.',
          'Satın alma / abonelik ekranlarındaki tüm metinler Türkçeleştirildi '
              '("Restore" → "Satın alımı geri yükle" gibi).',
          'Bölgesel katkı sıralaması hatası giderildi: İlçe / Şehir sekmesine '
              'basınca liste anlık görünüp kayboluyordu, artık sabit kalıyor. '
              'Sıralama getirilemezse boş ekran yerine görünür "Sıralama '
              'yüklenemedi · Tekrar dene" kartı çıkıyor — sorun sessizce '
              'yutulmuyor.',
          'Lider tablosunda aktif Pro üyelerin rozeti kullanıcı adının yanında '
              'doğru görünüyor; yeni Pro olduysan kendi rozetin de anında '
              'yansıyor.',
          'Profildeki çift seviye isimlendirmesi tek sisteme indirildi: '
              'başlıktaki sabit "Elit Radar" etiketi kaldırıldı, üst çip artık '
              'gerçek seviyenle aynı ünvanı gösteriyor (örn. "Mahalle Gözcüsü '
              '· 241 PT") ve alttaki SEVİYE kartıyla birebir uyumlu.',
        ],
      ),
      (
        version: 'v1.0.4',
        date: '23 Mayıs 2026',
        items: [
          'Premium satın alımları artık sunucu tarafında güvenle '
              'doğrulanıyor. İptal veya iade edilen abonelikler cihazda “Pro” '
              'olarak kalmıyor.',
          'Fiyat geçmişi planına göre genişledi: Ücretsiz planda son 7 gün, '
              'Premium’da 12 aya kadar grafik ve trend.',
          'Ücretsiz planda aktif fiyat alarmı 3 ile sınırlandı; Premium’da '
              'sınırsız. Sınıra ulaşınca nedeni açıkça gösteriliyor.',
          'Liderlik tablosunda aktif Premium üyelerin Pro rozeti adının '
              'yanında görünüyor (sıralamayı etkilemez).',
          'Sepet karşılaştırması sadeleşip “Akıllı sepet” adını aldı; birden '
              'fazla markete bölerek tasarruf eden karışık-market önerisi '
              'Premium’a taşındı.',
        ],
      ),
      (
        version: 'v1.0.3',
        date: '21 Mayıs 2026',
        items: [
          'Reklam altyapısı yenilendi; kişiselleştirilmiş reklam onayı gereken '
              'bölgelerde açıkça soruluyor. Premium üyeler hiç reklam görmez.',
          'Premium ekranı baştan tasarlandı: net avantaj listesi, aylık/yıllık '
              'geçiş, yıllık planda “%50 tasarruf” ve “7 gün ücretsiz” vurgusu.',
          'Performans ve kararlılık iyileştirmeleri yapıldı.',
        ],
      ),
      (
        version: 'v1.0.2',
        date: '14 Mayıs 2026',
        items: [
          'Profilde “Kullanıcı adı 3 ayda bir değiştirilebilir” bilgisi '
              'eklendi; kalan süreyi açıkça gösteriyor.',
          'Topluluk yorumlarında yazarın Pro rozeti ve güven yüzdesi anında '
              'görünüyor; liste daha hızlı açılıyor.',
          'Fiyat ekleme akışına mahalle pazarı seçici eklendi; pazar günü '
              'bugünse marketin yanında “BUGÜN” rozeti çıkıyor.',
          'Performans ve kod kalitesi iyileştirmeleri yapıldı.',
        ],
      ),
      (
        version: 'v1.0.1',
        date: '14 Mayıs 2026',
        items: [
          'Güvenlik ayarları sadeleştirildi; hesabın yine güvenle korunuyor, '
              'e-posta doğrulama ve hesap silme akışları yerinde.',
          'Kullanıcı adları artık benzersiz: aynı takma adı başkası '
              'kullanıyorsa kayıt sırasında uyarılırsın.',
          'Tanıtım slaytları uygulamanın gerçek davranışını anlatacak şekilde '
              'güncellendi.',
          'Bölgesel fiyat hareketi bildirim tercihi tam olarak uygulanıyor; '
              'kapalıysa bildirim gönderilmiyor.',
          '“Hakkında” ekranına veri silme talebi ve abonelik/iade koşulları '
              'bağlantıları eklendi.',
          'Performans ve güvenlik iyileştirmeleri yapıldı.',
        ],
      ),
      (
        version: 'v1.0.0',
        date: '8 Mayıs 2026',
        items: [
          'Topluluk akışındaki “az önce” rozeti dar ekranlarda taşıyordu; '
              'düzeltildi.',
          'Profil fotoğrafı yükleme hızlandırıldı ve yavaş bağlantılarda '
              'otomatik yeniden deneniyor.',
          'Açılış ekranı sadeleşti; daha akıcı bir giriş deneyimi.',
          '“Fiyat ekle” akışı sadeleştirildi; daha hızlı ve anlaşılır.',
          'Performans, kararlılık ve yayın hazırlığı iyileştirmeleri yapıldı.',
        ],
      ),
      (
        version: 'v0.9.6',
        date: '2 Mayıs 2026',
        items: [
          'Splash logosu büyük ekranlarda taşıyordu — boyut artık ekran '
              'genişliğine göre sınırlandırılıyor.',
          'Açık tema artık varsayılan; ayarlardan tek dokunuşla koyu temaya '
              'geçilebiliyor, tercih cihazda saklanıyor.',
          'Online market (Migros Sanal, CarrefourSA Online vb.) fiyatları '
              'için il / ilçe zorunluluğu kaldırıldı — ülke geneli akış.',
          'Ürün detay ekranında raf fotoğrafı önizleme kalitesi yükseltildi.',
        ],
      ),
      (
        version: 'v0.9.5',
        date: '24 Nisan 2026',
        items: [
          'Yeni FR-radar logosu uygulamanın her köşesine işlendi: launcher '
              'ikonu, splash, paywall, admin başlığı.',
          'Adaptif Android ikonunun krem haresi kaldırıldı — koyu launcher '
              'temalarında daha temiz duruyor.',
          'Fiyat ekleme sırasında nadir görülen bir gönderim hatası giderildi.',
        ],
      ),
      (
        version: 'v0.9.4',
        date: '15 Nisan 2026',
        items: [
          'FiyatRadar Pro geldi: reklamsız kullanım, gelişmiş alarm ve '
              'sınırsız favori.',
          'Bölgesel lider tablosu yayında — il / ilçe bazında en çok katkı '
              'yapan kullanıcılar haftalık güncelleniyor.',
          'Takip listesi: ürün takibi, hedef fiyat alarmı ve bildirim.',
          'Bağlantı zayıfken boş ekran yerine yükleniyor görünümü gösteriliyor.',
          'Reklamlar eklendi; Premium üyelerde otomatik gizleniyor.',
        ],
      ),
      (
        version: 'v0.9.3',
        date: '7 Nisan 2026',
        items: [
          'Gamification: rozetler, +10 PT katkı puanı, seviye atlama, '
              'profilde puan ve rozet gösterimi.',
          'Admin moderasyon: ihtilaflı / şüpheli fiyat raporları için '
              'inceleme kuyruğu, onay-red akışları.',
          'Kararlılık iyileştirildi: uygulama hataları otomatik raporlanıp '
              'daha hızlı düzeltiliyor.',
          'Sepet yenilendi — gerçek zamanlı toplam fiyat ve market bazında '
              'karşılaştırma.',
        ],
      ),
      (
        version: 'v0.9.2',
        date: '28 Mart 2026',
        items: [
          'Bildirimler: bölgesel fiyat düşüşü ve takip ettiğin ürünlerdeki '
              'değişiklikler için anlık bildirim.',
          'Barkod tarayıcı: ürün eklerken barkod ile otomatik tanıma.',
          'Yorum sistemi: ürün altında topluluk yorumları, beğeni, raporlama.',
          'Hesap yönetimi: e-posta / şifre değiştir, hesabı sil, oturumları '
              'görüntüle.',
        ],
      ),
      (
        version: 'v0.9.1',
        date: '20 Mart 2026',
        items: [
          'Play Store hazırlığı için kapsamlı güvenlik iyileştirmeleri '
              'yapıldı.',
          'Onboarding ekranı: 3 sayfalık tanıtım, izin istekleri (konum, '
              'bildirim).',
          'Arayüz: tutarlı buton boyutları, alt menü için güvenli boşluklar '
              've klavye açıkken akıcı kaydırma.',
        ],
      ),
      (
        version: 'v0.8.5',
        date: '10 Mart 2026',
        items: [
          'Admin "Bekleyen" sekmesi düzeltildi — moderasyona düşen ürün / '
              'fiyat talepleri tek listede.',
          'Premium kullanıcı düzenleyici: admin manuel olarak Pro üyelik '
              'verebiliyor / iptal edebiliyor.',
          '"Fiyat ekle" akışı cilalandı: il/ilçe haritası, GPS ile otomatik '
              'doldurma, manuel değiştirme.',
        ],
      ),
      (
        version: 'v0.8.4',
        date: '1 Mart 2026',
        items: [
          'Anasayfa, ürün detay ve karşılaştırma ekranları FR tasarım diline '
              'uygun yeniden tasarlandı.',
          'Trend kartları: fiyatı düşenler / çıkanlar yatay carousel.',
          'Karşılaştır ekranı: aynı ürün için marketler arası tablo + '
              'tasarruf yüzdesi.',
        ],
      ),
      (
        version: 'v0.8.3',
        date: '20 Şubat 2026',
        items: [
          'Bölge seçici Türkiye il/ilçe listesiyle sınırlandı — yanlış bölge '
              'bildirimleri ortadan kalktı.',
          'Ana sayfa bölge akışı (şehir / mahalle) sağlamlaştırıldı.',
          'Yönetici market yönetimi yenilendi: zincir bazlı arama ve durum '
              'filtreleri.',
        ],
      ),
      (
        version: 'v0.8.2',
        date: '12 Şubat 2026',
        items: [
          'Lineer "Fiyat ekle" akışı: 4 net adım (ürün → fiyat → market → '
              'bölge), her adımın yanında ✓ rozet.',
          'Daha zengin fiyat kartları: doğrulama rozetleri, güven yüzdesi, '
              'tazelik chip\'i.',
          'Mağaza kayıt akışı: yer önerme sheet\'i, mahalle, GPS koordinatı, '
              'opsiyonel raf fotoğrafı.',
        ],
      ),
      (
        version: 'v0.8.1',
        date: '4 Şubat 2026',
        items: [
          'Bölgesel fiyat görünürlüğü: kullanıcılar yalnızca kendi şehir / '
              'ilçesinden gelen fiyatları görüyor (Pro\'da tüm Türkiye).',
          'Mağaza yönetimi akışı tamamlandı: admin pending → approved → '
              'rejected geçişleri.',
        ],
      ),
      (
        version: 'v0.8.0',
        date: '25 Ocak 2026',
        items: [
          'Bölgesel fiyat sistemi tasarlandı ve uygulandı: her fiyat girişi '
              'bir mağaza ve bölge ile ilişkilendiriliyor.',
          'Veri okuma performansı ve tutarlılığı iyileştirildi.',
        ],
      ),
      (
        version: 'v0.7.5',
        date: '18 Ocak 2026',
        items: [
          'Banner / blog yönetim ekranı admin panele eklendi.',
          'Anasayfa banner carousel canlı.',
          '"Hakkında" ekranına kullanıcı sözleşmesi ve gizlilik politikası '
              'bağlantıları eklendi.',
        ],
      ),
      (
        version: 'v0.7.0',
        date: '5 Ocak 2026',
        items: [
          'Temel iyileştirmeler: doğrulama sistemi, canlı tema değişimi ve '
              'alt menü için güvenli sayfa boşlukları.',
          'Bildirim ekranı yenilendi: tüm push geçmişi, okundu / okunmadı '
              'rozetleri, tek dokunuşla detaya git.',
          'Tema renkleri runtime\'da güncellenebiliyor — admin paletten '
              'değiştirdiği anda tüm açık ekranlar güncelleniyor.',
        ],
      ),
      (
        version: 'v0.6.0',
        date: '20 Aralık 2025',
        items: [
          'Tüm arayüz sıcak, premium bir görünümle yeniden düzenlendi.',
          'Tipografi tek bir tutarlı sistemden okunacak şekilde düzenlendi.',
          'Tutarlı, paylaşılan bir arayüz bileşen sistemi oluşturuldu.',
        ],
      ),
      (
        version: 'v0.5.0',
        date: '10 Aralık 2025',
        items: [
          'Login: Google Sign-In + e-posta/şifre + anonim auth.',
          'Profil: ad, kullanıcı adı, telefon, fotoğraf, bölge, dil tercihi.',
          'Yönetici araçları eklendi.',
          'Açılışta bağlantı sorununda kullanıcıya net, aksiyon alınabilir '
              'bir hata ekranı gösteriliyor.',
        ],
      ),
      (
        version: 'v0.4.0',
        date: '25 Kasım 2025',
        items: [
          'Ürün katalogu: ad, marka, kategori, birim, barkod, görseller, '
              'tag\'ler.',
          'Ürün detay sayfası: en düşük fiyat, fiyat geçmişi grafiği, '
              'topluluk doğrulama oranı.',
          'Favoriler ve takip listesi.',
        ],
      ),
      (
        version: 'v0.3.0',
        date: '12 Kasım 2025',
        items: [
          'İlk fiyat ekleme akışı: ürün, market, fiyat, opsiyonel not.',
          'Topluluk akışı: yeni eklenen fiyatları realtime listele.',
          'Anasayfa: kategori chip\'leri, "fiyatı düşenler" listesi.',
        ],
      ),
      (
        version: 'v0.2.0',
        date: '28 Ekim 2025',
        items: [
          'Uygulama altyapısı kuruldu.',
          'Ürün, fiyat ve mağaza veri yapısı oluşturuldu.',
          'Sunucu tarafı fiyat ve abonelik doğrulama altyapısı eklendi.',
        ],
      ),
      (
        version: 'v0.1.0',
        date: '15 Ekim 2025',
        items: [
          'Proje başlangıcı: ilk uygulama iskeleti ve marka kimliği.',
          'İlk taslak ekranlar (ana sayfa, profil, fiyat ekle).',
          'Tasarım dili: altın + koyu mürekkep paleti ve tutarlı köşe '
              'yuvarlamaları.',
        ],
      ),
    ];
    return _ProfileSubScaffold(
      overline: 'SÜRÜM NOTLARI',
      title: 'Güncelleme geçmişi',
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
        itemCount: notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final n = notes[i];
          final isLatest = i == 0;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isLatest ? FR.surfaceHi : FR.surface,
              borderRadius: FRRad.all(FRRad.l),
              border: Border.all(
                color: isLatest ? FR.gold.withOpacity(.55) : FR.hairline,
                width: isLatest ? 1.4 : 1.0,
              ),
              boxShadow: isLatest ? frGoldGlow(opacity: .14) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(n.version,
                        style: frDisplay(20, FontWeight.w700,
                            color: isLatest ? FR.gold : FR.ink)),
                    const SizedBox(width: 8),
                    if (isLatest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: FR.gold,
                          borderRadius: FRRad.all(999),
                        ),
                        child: Text('GÜNCEL',
                            style: frOverline(
                                color: FR.onGold, size: 8.5)),
                      ),
                  ],
                ),
                Text(n.date,
                    style: frText(12, FontWeight.w600, color: FR.ink3)),
                const SizedBox(height: 8),
                ...n.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Icon(Icons.circle, size: 6, color: FR.gold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: frText(12.5, FontWeight.w600,
                                color: FR.ink, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Favorites list ─────────────────────────────────────────────────────────

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final favs = state.products
        .where((p) => state.isFavorite(p.id))
        .toList();
    return _ProfileSubScaffold(
      overline: 'TAKİP · FAVORİLER',
      title: 'Favorilerim',
      child: favs.isEmpty
          ? _emptyBlock(
              'Henüz favori yok. Bir ürünü keşfet ve kalp simgesine dokun.')
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  20, 4, 20, frBottomScrollPadding(context)),
              itemCount: favs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ProductMiniRow(
                product: favs[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: favs[i]),
                  ),
                ),
                trailing: InkWell(
                  onTap: () => state.toggleFavorite(favs[i].id),
                  borderRadius: FRRad.all(999),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child:
                        Icon(Icons.favorite_rounded, color: FR.bad, size: 19),
                  ),
                ),
              ),
            ),
    );
  }
}

// ─── Alerts list ────────────────────────────────────────────────────────────

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final alerts = state.productAlerts.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _ProfileSubScaffold(
      overline: 'TAKİP · ALARMLAR',
      title: 'Fiyat alarmlarım',
      child: alerts.isEmpty
          ? _emptyBlock(
              'Henüz alarm yok. Ürün detayından hedef fiyat belirleyip alarm kur.')
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  20, 4, 20, frBottomScrollPadding(context)),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final a = alerts[i];
                final p = state.findById(a.productId);
                if (p == null) {
                  return _alertGhost(a.productId, a.targetPrice);
                }
                final priceNow = p.lowestPrice == null
                    ? '—'
                    : '₺${p.lowestPrice!.toStringAsFixed(2)}';
                String alertText;
                switch (a.mode) {
                  case ProductAlertMode.belowTarget:
                    alertText =
                        'Hedef: ₺${a.targetPrice.toStringAsFixed(2)} altına';
                    break;
                  case ProductAlertMode.priceDrop:
                    alertText = 'Fiyat düşünce';
                    break;
                  case ProductAlertMode.anyNewPrice:
                    alertText = 'Her yeni fiyatta';
                    break;
                }
                return _ProductMiniRow(
                  product: p,
                  subtitleOverride:
                      '$alertText · güncel: $priceNow',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: p),
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: FR.ink3),
                );
              },
            ),
    );
  }

  Widget _alertGhost(String id, double target) => Container(
        padding: const EdgeInsets.all(12),
        decoration: frSurface(radius: FRRad.l),
        child: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: FR.ink3, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Ürün bulunamadı · $id',
                  style: frText(12, FontWeight.w700, color: FR.ink3)),
            ),
            Text('₺${target.toStringAsFixed(2)}',
                style: frText(12, FontWeight.w800, color: FR.gold)),
          ],
        ),
      );
}

// ─── Contributions: my price entries ────────────────────────────────────────

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> {
  // Pagination: ilk 50 göster, "Daha fazla yükle" tıklamasıyla 50'şer
  // arttır. Kullanıcının 200+ katkısı varsa bile UI takılmasın.
  int _limit = 50;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return _ProfileSubScaffold(
      overline: 'KATKILARIM',
      title: 'Fiyat paylaşımlarım',
      // Yeni omurga: priceReports koleksiyonu üzerinden canlı stream.
      // Eski versiyonu legacy `priceHistory` array'ini tarıyordu — mirror
      // kalktığında veri kaybolurdu. Bu artık dayanıklı.
      child: StreamBuilder<List<MyPriceContribution>>(
        stream: state.watchMyContributions(limit: _limit),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                FRSpace.xl,
                FRSpace.xs,
                FRSpace.xl,
                FRSpace.xxl - FRSpace.xs,
              ),
              child: FRSkeletonList(
                count: 5,
                itemHeight: 76,
                radius: 16,
              ),
            );
          }
          final entries = snap.data ?? const <MyPriceContribution>[];
          if (entries.isEmpty) {
            return _emptyBlock('Henüz fiyat paylaşmadın. Radar sekmesinden ekle.');
          }
          // "Daha fazla yükle" iken son sayfa = entries.length == _limit ise
          // bir sonraki sayfada daha fazla olabilir. Stream limit'i her
          // setState ile yenilendiği için sonraki snapshot'ta yeni veriler
          // görünür.
          final canLoadMore = entries.length >= _limit;
          // itemCount: entries + (varsa) load-more buton satırı
          final itemCount = entries.length + (canLoadMore ? 1 : 0);
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
                20, 4, 20, frBottomScrollPadding(context)),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              if (i >= entries.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: FRCta(
                    label: 'Daha fazla yükle',
                    icon: Icons.expand_more_rounded,
                    filled: false,
                    onTap: () => setState(() => _limit += 50),
                  ),
                );
              }
              final c = entries[i];
              final product = state.findById(c.productId);
              return InkWell(
                onTap: product == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: product),
                          ),
                        ),
                borderRadius: FRRad.all(FRRad.l),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: frSurface(radius: FRRad.l),
                  child: Row(
                    children: [
                      Text(product?.emoji ?? '🧾',
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${c.productName.isEmpty ? (product?.name ?? "Ürün") : c.productName} · ${c.chainName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: frText(13, FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${c.districtName} / ${c.cityName} · ${priceReportSourceTypeLabelTr(c.sourceType)}'
                              '${c.photoUrl == null ? "" : " · 📷"}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: frText(11, FontWeight.w700,
                                  color: FR.ink3),
                            ),
                            if (c.createdAt != null) ...[
                              const SizedBox(height: 4),
                              FRFreshChip(date: c.createdAt!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FRPriceText(c.price, size: 15),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Settings hub ───────────────────────────────────────────────────────────

class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEn = AppStateScope.of(context).localeCode == 'en';
    return _ProfileSubScaffold(
      overline: s.t('settings.overline'),
      title: s.t('settings.title'),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
        children: [
          // ── Hesap ──────────────────────────────────────────────────────
          _HubSectionHeader(label: s.t('settings.section.account')),
          _HubRow(
            icon: Icons.person_outline_rounded,
            title: s.t('settings.profileInfo'),
            subtitle: s.t('settings.profileInfo.sub'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileInfoScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.account_circle_outlined,
            title: s.t('settings.account'),
            subtitle: s.t('settings.account.sub'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.local_offer_outlined,
            title: s.t('settings.contributions'),
            subtitle: s.t('settings.contributions.sub'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ContributionsScreen())),
          ),

          // ── Bildirimler ────────────────────────────────────────────────
          _HubSectionHeader(label: s.t('settings.section.notifications')),
          _HubRow(
            icon: Icons.notifications_none_rounded,
            title: s.t('settings.notificationPrefs'),
            subtitle: s.t('settings.notificationPrefs.sub'),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationPrefsScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.notifications_active_outlined,
            title: s.t('settings.myAlerts'),
            subtitle: s.t('settings.myAlerts.sub'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AlertsScreen())),
          ),

          // ── Uygulama ───────────────────────────────────────────────────
          _HubSectionHeader(label: s.t('settings.section.app')),
          _HubRow(
            icon: Icons.language_rounded,
            title: s.t('settings.languageRow'),
            subtitle: isEn ? 'English' : 'Türkçe',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LanguageSettingsScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.history_rounded,
            title: s.t('settings.releaseNotes'),
            subtitle: s.t('settings.releaseNotes.sub'),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReleaseNotesScreen())),
          ),

          // ── Yardım ve yasal ────────────────────────────────────────────
          _HubSectionHeader(label: s.t('settings.section.helpLegal')),
          _HubRow(
            icon: Icons.help_outline_rounded,
            title: s.t('settings.helpFaq'),
            subtitle: s.t('settings.helpFaq.sub'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HelpFaqScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.support_agent_rounded,
            title: s.t('settings.contactSupport'),
            subtitle: s.t('settings.contactSupport.sub'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ContactSupportScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.info_outline_rounded,
            title: s.t('settings.about'),
            subtitle: s.t('settings.about.sub'),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),

          // ── Keşfe dön (ikincil aksiyon) ────────────────────────────────
          const SizedBox(height: 22),
          _SecondaryHubAction(
            icon: Icons.grid_view_rounded,
            label: s.t('settings.backToExplore'),
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (_) => const MainScreen(initialIndex: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Language picker ────────────────────────────────────────────────────────

/// Dil seçim ekranı. Türkçe / İngilizce arasında geçiş — değişiklik
/// SharedPreferences'a yazılır ve `AppState.setLocale` üzerinden
/// MaterialApp anında rebuild olur.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final current = state.localeCode;
    final isEn = current == 'en';
    return _ProfileSubScaffold(
      overline: 'GENEL',
      title: isEn ? 'Language' : 'Dil',
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: frSurface(radius: FRRad.l),
            child: Text(
              isEn
                  ? 'Choose the app interface language.'
                  : 'Uygulama arayüz dilini seç.',
              style: frText(12.5, FontWeight.w600, color: FR.ink3, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          _LanguageRow(
            label: 'Türkçe',
            sub: 'Turkish',
            selected: current == 'tr',
            onTap: () => state.setLocale('tr'),
          ),
          const SizedBox(height: 10),
          _LanguageRow(
            label: 'English',
            sub: 'İngilizce',
            selected: current == 'en',
            onTap: () => state.setLocale('en'),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(
            color: selected ? FR.goldDeep : FR.hairline,
            width: selected ? 1.3 : 1,
          ),
          boxShadow: selected ? frGoldGlow(opacity: .15) : null,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? FR.gold : FR.ink3,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: frText(14, FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                ],
              ),
            ),
            if (selected)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FR.gold.withOpacity(.16),
                  borderRadius: FRRad.all(999),
                  border: Border.all(color: FR.gold.withOpacity(.35)),
                ),
                child: Text('AKTİF',
                    style:
                        frText(10, FontWeight.w800, color: FR.gold, letter: 1)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Account (email verify + delete) ────────────────────────────────────────

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _verifyBusy = false;
  bool _refreshBusy = false;
  bool _deleteBusy = false;
  String? _verifyMessage;
  String? _deleteError;

  Future<void> _sendVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    // Cooldown + Türkçe dil zorlaması AppState.sendVerificationEmail içinde;
    // doğrudan user.sendEmailVerification() çağırıp spam'i delmeyelim.
    final state = AppStateScope.read(context);
    setState(() {
      _verifyBusy = true;
      _verifyMessage = null;
    });
    try {
      await state.sendVerificationEmail();
      if (!mounted) return;
      setState(() => _verifyMessage =
          'Doğrulama e-postası gönderildi. Lütfen gelen kutunu ve spam '
          'klasörünü kontrol et.');
    } on StateError catch (e) {
      // Cooldown veya uygun olmayan durum — net Türkçe mesaj.
      if (!mounted) return;
      setState(() => _verifyMessage = e.message);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _verifyMessage = e.code == 'too-many-requests'
          ? 'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar dene.'
          : 'E-posta gönderilemedi. Lütfen daha sonra tekrar dene.');
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _verifyMessage = 'E-posta gönderilemedi. Lütfen daha sonra tekrar dene.');
    } finally {
      if (mounted) setState(() => _verifyBusy = false);
    }
  }

  Future<void> _refreshStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _refreshBusy = true);
    try {
      await user.reload();
    } catch (_) {}
    if (mounted) setState(() => _refreshBusy = false);
  }

  Future<void> _deleteAccount() async {
    final ok = await _confirmDelete();
    if (ok != true) return;
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _deleteBusy = true;
      _deleteError = null;
    });
    final state = AppStateScope.read(context);
    final uid = user.uid;
    final handle = state.username;
    try {
      // Best-effort: drop FCM token + the user doc before deleting auth so
      // we don't leave a tombstone with the user's profile data behind.
      try {
        await MessagingService.instance.clearTokenForCurrentUser();
      } catch (_) {}
      try {
        await FirebaseService.instance
            .releaseUsername(uid: uid, handle: handle);
      } catch (_) {}
      try {
        await FirebaseService.instance.userDoc(uid).delete();
      } catch (_) {}
      await user.delete();
      // Clear state and rebuild auth gate.
      await state.refreshFromAuthSession(preserveGuestAcknowledged: false);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _deleteError = e.code == 'requires-recent-login'
          ? 'Güvenlik için tekrar giriş yapman gerekiyor.'
          : (e.message ?? e.code));
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleteError = '$e');
    } finally {
      if (mounted) setState(() => _deleteBusy = false);
    }
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FR.surface,
        title: Text('Hesabı sil', style: frDisplay(20, FontWeight.w800)),
        content: Text(
          'Hesabını sildiğinde profil bilgilerin kalıcı olarak silinir. '
          'Topluluğa katkı olarak eklediğin bazı fiyat kayıtları, herkesin '
          'yararına anonimleştirilmiş şekilde korunabilir. Bu işlem geri '
          'alınamaz.',
          style: frText(13, FontWeight.w600, color: FR.ink2, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Vazgeç',
                style: frText(13, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil',
                style: frText(13, FontWeight.w800, color: FR.bad)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAnonymous = user?.isAnonymous ?? true;
    final email = user?.email ?? '';
    final isVerified = user?.emailVerified ?? false;

    return _ProfileSubScaffold(
      overline: 'HESAP YÖNETİMİ',
      title: 'Hesap',
      child: ListView(
        padding:
            EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
        children: [
          if (isAnonymous)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: frSurface(radius: FRRad.l),
              child: Text(
                'Misafir hesabıyla giriş yapıldı. Tam hesap özellikleri için '
                'kayıtlı bir e-posta ile giriş yap.',
                style: frText(12.5, FontWeight.w600, color: FR.ink3,
                    height: 1.5),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: frSurface(radius: FRRad.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('E-POSTA',
                      style: frOverline(color: FR.ink3)),
                  const SizedBox(height: 6),
                  Text(email.isEmpty ? '—' : email,
                      style: frText(14, FontWeight.w800)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        isVerified
                            ? Icons.verified_rounded
                            : Icons.error_outline_rounded,
                        size: 16,
                        color: isVerified ? FR.gold : FR.bad,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isVerified ? 'Doğrulandı' : 'Henüz doğrulanmadı',
                        style: frText(12, FontWeight.w800,
                            color: isVerified ? FR.gold : FR.bad),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!isVerified) ...[
              FRCta(
                label: _verifyBusy
                    ? 'Gönderiliyor…'
                    : 'Doğrulama e-postası gönder',
                icon: Icons.mark_email_read_rounded,
                onTap: _verifyBusy ? null : _sendVerification,
              ),
              const SizedBox(height: 8),
              FRCta(
                label: _refreshBusy ? 'Kontrol ediliyor…' : 'Durumu yenile',
                icon: Icons.refresh_rounded,
                filled: false,
                onTap: _refreshBusy ? null : _refreshStatus,
              ),
              if (_verifyMessage != null) ...[
                const SizedBox(height: 8),
                Text(_verifyMessage!,
                    style: frText(12, FontWeight.w700, color: FR.ink2)),
              ],
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FR.bad.withOpacity(.08),
                borderRadius: FRRad.all(FRRad.l),
                border: Border.all(color: FR.bad.withOpacity(.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TEHLİKELİ BÖLGE',
                      style: frOverline(color: FR.bad)),
                  const SizedBox(height: 6),
                  Text(
                    'Hesabını silmek profilini, favorilerini ve kazandığın '
                    'puanları kalıcı olarak kaldırır. Topluluğa eklediğin bazı '
                    'fiyat kayıtları anonimleştirilmiş şekilde korunabilir.',
                    style: frText(12.5, FontWeight.w600,
                        color: FR.ink2, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  FRCta(
                    label: _deleteBusy ? 'Siliniyor…' : 'Hesabımı sil',
                    icon: Icons.delete_forever_rounded,
                    filled: false,
                    onTap: _deleteBusy ? null : _deleteAccount,
                  ),
                  if (_deleteError != null) ...[
                    const SizedBox(height: 8),
                    Text(_deleteError!,
                        style:
                            frText(12, FontWeight.w800, color: FR.bad)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared bits ────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: frSurface(radius: FRRad.l),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FR.surfaceHi,
              borderRadius: FRRad.all(12),
              border: Border.all(color: FR.hairline),
            ),
            child: Icon(icon, color: FR.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: frText(13.5, FontWeight.w800)),
                Text(subtitle,
                    style: frText(11.5, FontWeight.w600, color: FR.ink3)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: FR.bg,
            activeTrackColor: FR.gold,
            inactiveThumbColor: FR.ink2,
            inactiveTrackColor: FR.surfaceHi,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Ayarlar listesindeki grup başlığı. Büyük redesign değil; sade overline
/// etiketiyle uzun listeyi anlamlı bölümlere ayırır.
class _HubSectionHeader extends StatelessWidget {
  const _HubSectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(2, FRSpace.xl, 0, 10),
      child: Text(label, style: frOverline()),
    );
  }
}

/// "Keşfe dön" gibi ikincil aksiyon — kart yerine daha sade, düşük vurgulu
/// bir satır olarak en altta durur.
class _SecondaryHubAction extends StatelessWidget {
  const _SecondaryHubAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: FR.surfaceLo,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.hairline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: FR.ink2, size: 18),
            const SizedBox(width: 8),
            Text(label, style: frText(13, FontWeight.w800, color: FR.ink2)),
          ],
        ),
      ),
    );
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: frSurface(radius: FRRad.l),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: FR.surfaceHi,
                borderRadius: FRRad.all(12),
                border: Border.all(color: FR.hairline),
              ),
              child: Icon(icon, color: FR.gold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: frText(13.5, FontWeight.w800)),
                  Text(subtitle,
                      style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: FR.ink3),
          ],
        ),
      ),
    );
  }
}

class _ProductMiniRow extends StatelessWidget {
  const _ProductMiniRow({
    required this.product,
    required this.onTap,
    this.trailing,
    this.subtitleOverride,
  });
  final Product product;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? subtitleOverride;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: frSurface(radius: FRRad.l),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FR.surfaceHi,
                borderRadius: FRRad.all(12),
                border: Border.all(color: FR.hairline),
              ),
              alignment: Alignment.center,
              child: Text(product.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: frText(13.5, FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    subtitleOverride ??
                        '${product.brand} · ${product.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frText(11.5, FontWeight.w600, color: FR.ink3),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

Widget _emptyBlock(String text) => Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: frText(13, FontWeight.w600, color: FR.ink3, height: 1.45)),
      ),
    );
