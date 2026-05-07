import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product.dart';
import '../services/firebase_service.dart';
import '../services/messaging_service.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
import 'main_screen.dart';
import 'product_detail_screen.dart';

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
        final res = await FirebaseService.instance.uploadUserProfileImage(
          uid: user.uid,
          bytes: pending,
        );
        imageUrl = res.url;
        imagePath = res.path;
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
      setState(() => _pendingProfileImage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pending == null
                ? 'Profil bilgileri güncellendi.'
                : 'Profil fotoğrafı güncellendi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_describeProfileError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _describeProfileError(Object e) {
    if (e is FirebaseException && e.plugin == 'firebase_storage') {
      switch (e.code) {
        case 'unauthenticated':
          return 'Profil güncellenemedi: tekrar giriş yapman gerekiyor.';
        case 'unauthorized':
          return 'Profil güncellenemedi: bu fotoğrafı yüklemeye yetkin yok.';
        case 'canceled':
          return 'Yükleme iptal edildi.';
        case 'retry-limit-exceeded':
        case 'unknown':
          return 'Profil fotoğrafı yüklenemedi. İnternet bağlantını kontrol edip tekrar dene.';
      }
    }
    return 'Profil güncellenemedi: $e';
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 88,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() => _pendingProfileImage = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return _ProfileSubScaffold(
      overline: 'KİMLİK',
      title: 'Profil bilgileri',
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
        children: [
          _avatarEditor(state),
          const SizedBox(height: 14),
          _field('Ad Soyad', _nameCtrl, Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _field('Kullanıcı adı', _userCtrl, Icons.alternate_email_rounded),
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
        padding: const EdgeInsets.all(14),
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
                  ? Image.memory(_pendingProfileImage!, fit: BoxFit.cover)
                  : (state.profileImageUrl != null
                      ? Image.network(
                          key: ValueKey(state.profileImageUrl),
                          state.profileImageUrl!,
                          fit: BoxFit.cover,
                          cacheWidth: 192,
                          filterQuality: FilterQuality.medium,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: FR.gold,
                                        ),
                                      ),
                                    ),
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              state.displayName.isEmpty
                                  ? 'F'
                                  : state.displayName[0].toUpperCase(),
                              style: frDisplay(24, FontWeight.w800,
                                  color: FR.gold),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            state.displayName.isEmpty
                                ? 'F'
                                : state.displayName[0].toUpperCase(),
                            style: frDisplay(24, FontWeight.w800, color: FR.gold),
                          ),
                        )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profil fotoğrafı', style: frText(13, FontWeight.w800)),
                  Text(
                    hasPending ? 'Kaydet ile yüklenir' : 'Galeri seç',
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
    return _ProfileSubScaffold(
      overline: 'RADAR SİNYALLERİ',
      title: 'Bildirim tercihleri',
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
        children: [
          _ToggleRow(
            icon: Icons.notifications_active_rounded,
            title: 'Push bildirimler',
            subtitle: 'Uygulamaya canlı sinyal gelsin',
            value: state.pushNotificationsEnabled,
            onChanged: (v) =>
                state.updateNotificationSettings(pushEnabled: v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.price_change_rounded,
            title: 'Fiyat alarmları',
            subtitle: 'Takip ettiğin ürün hedef fiyatta olduğunda',
            value: state.priceAlertsEnabled,
            onChanged: (v) =>
                state.updateNotificationSettings(priceAlertsEnabled: v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.summarize_rounded,
            title: 'Haftalık özet',
            subtitle: 'Pazartesi sabahı fiyat özeti',
            value: state.weeklySummaryEnabled,
            onChanged: (v) =>
                state.updateNotificationSettings(weeklySummaryEnabled: v),
          ),
        ],
      ),
    );
  }
}

// ─── Security ───────────────────────────────────────────────────────────────

class SecurityPrefsScreen extends StatefulWidget {
  const SecurityPrefsScreen({super.key});

  @override
  State<SecurityPrefsScreen> createState() => _SecurityPrefsScreenState();
}

class _SecurityPrefsScreenState extends State<SecurityPrefsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _securityBusy = false;

  Future<void> _toggleBiometric(AppState state, bool enabled) async {
    if (_securityBusy) return;
    setState(() => _securityBusy = true);
    if (!enabled) {
      await state.updateSecuritySettings(biometricEnabled: false);
      if (mounted) setState(() => _securityBusy = false);
      return;
    }
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu cihaz biyometriyi desteklemiyor.')),
        );
        return;
      }
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      final hasBiometric = canCheck && available.isNotEmpty;
      final ok = await _localAuth.authenticate(
        localizedReason: 'Biyometrik güvenliği açmak için doğrula',
        options: AuthenticationOptions(
          biometricOnly: hasBiometric,
          stickyAuth: false,
        ),
      );
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biyometrik doğrulama iptal edildi.')),
        );
        return;
      }
      state.markSecuritySessionUnlocked(true);
      await state.updateSecuritySettings(biometricEnabled: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biyometrik doğrulama başarısız: $e')),
      );
    } finally {
      if (mounted) setState(() => _securityBusy = false);
    }
  }

  Future<void> _toggleTwoFactor(AppState state, bool enabled) async {
    if (_securityBusy) return;
    setState(() => _securityBusy = true);
    try {
      if (!enabled) {
        await state.updateSecuritySettings(
          twoFactorEnabled: false,
          clearTwoFactorPin: true,
        );
        return;
      }
      final pin = await _askTwoFactorPin();
      if (pin == null) return;
      state.markSecuritySessionUnlocked(true);
      await state.updateSecuritySettings(
        twoFactorEnabled: true,
        twoFactorPin: pin,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İki aşamalı kimlik etkinleştirildi.')),
      );
    } finally {
      if (mounted) setState(() => _securityBusy = false);
    }
  }

  Future<String?> _askTwoFactorPin() async {
    final pin = TextEditingController();
    final pinAgain = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FR.surface,
        title: Text('2FA kodu oluştur', style: frDisplay(20, FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pin,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: '4-6 haneli kod',
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pinAgain,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Kodu tekrar gir',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: frText(12, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () {
              final a = pin.text.trim();
              final b = pinAgain.text.trim();
              if (a.length < 4 || a.length > 6 || a != b) {
                Navigator.pop(ctx, '');
                return;
              }
              Navigator.pop(ctx, a);
            },
            child: Text('Kaydet', style: frText(12, FontWeight.w800, color: FR.gold)),
          ),
        ],
      ),
    );
    pin.dispose();
    pinAgain.dispose();
    if (result == '') {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kod eşleşmiyor veya geçersiz.')),
      );
      return null;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return _ProfileSubScaffold(
      overline: 'HESAP GÜVENLİĞİ',
      title: 'Güvenlik',
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
        children: [
          _ToggleRow(
            icon: Icons.lock_reset_rounded,
            title: 'İki aşamalı kimlik (2FA)',
            subtitle: 'Girişte doğrulama kodu iste',
            value: state.twoFactorEnabled,
            onChanged: _securityBusy ? null : (v) => _toggleTwoFactor(state, v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.fingerprint_rounded,
            title: 'Biyometri',
            subtitle: 'Parmak izi / Face ID ile hızlı giriş',
            value: state.biometricEnabled,
            onChanged: _securityBusy ? null : (v) => _toggleBiometric(state, v),
          ),
        ],
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
                Text('FiyatRadar', style: frDisplay(20, FontWeight.w700)),
                const SizedBox(height: 6),
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
            subtitle: 'fiyatradar.netlify.app/sozlesme',
            onTap: () =>
                _openExternalLink(context, 'https://fiyatradar.netlify.app/sozlesme'),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik sözleşmesi',
            subtitle: 'fiyatradar.netlify.app/gizlilik',
            onTap: () =>
                _openExternalLink(context, 'https://fiyatradar.netlify.app/gizlilik'),
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
    const notes = <({String version, String date, List<String> items})>[
      (
        version: 'v1.2.0',
        date: '25 Nisan 2026',
        items: [
          'Ayarlarda Marketler bölümü canlı market listesine bağlandı.',
          'Hakkında ekranına kullanıcı sözleşmesi ve gizlilik sözleşmesi bağlantıları eklendi.',
          'Güvenlik ekranında biyometri / 2FA geçişleri daha stabil hale getirildi.',
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
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: frSurface(radius: FRRad.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.version, style: frDisplay(20, FontWeight.w700)),
                Text(n.date, style: frText(12, FontWeight.w600, color: FR.ink3)),
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
                            style: frText(12.5, FontWeight.w600, color: FR.ink),
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
                return _ProductMiniRow(
                  product: p,
                  subtitleOverride:
                      'Hedef: ₺${a.targetPrice.toStringAsFixed(2)} · güncel: ${p.lowestPrice == null ? '—' : '₺${p.lowestPrice!.toStringAsFixed(2)}'}',
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

class ContributionsScreen extends StatelessWidget {
  const ContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final uid = state.user?.uid ?? '';
    final entries = <(Product, PriceEntry)>[];
    for (final p in state.products) {
      for (final e in p.priceHistory) {
        if (e.reportedByUid == uid && uid.isNotEmpty) {
          entries.add((p, e));
        }
      }
    }
    entries.sort((a, b) => b.$2.date.compareTo(a.$2.date));

    return _ProfileSubScaffold(
      overline: 'KATKILARIM',
      title: 'Fiyat paylaşımlarım',
      child: entries.isEmpty
          ? _emptyBlock('Henüz fiyat paylaşmadın. Radar sekmesinden ekle.')
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  20, 4, 20, frBottomScrollPadding(context)),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = entries[i].$1;
                final e = entries[i].$2;
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: p),
                    ),
                  ),
                  borderRadius: FRRad.all(FRRad.l),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: frSurface(radius: FRRad.l),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${p.name} · ${e.store}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: frText(13, FontWeight.w800)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  FRFreshChip(date: e.date),
                                  const SizedBox(width: 6),
                                  FRVerifyBadge.status(
                                    status: statusToString(e.status),
                                    trustPercent: e.trustPercent,
                                    dense: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FRPriceText(e.price, size: 15),
                      ],
                    ),
                  ),
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
    return _ProfileSubScaffold(
      overline: 'GENEL',
      title: 'Ayarlar',
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
        children: [
          _HubRow(
            icon: Icons.person_outline_rounded,
            title: 'Profil bilgileri',
            subtitle: 'Ad, kullanıcı adı, telefon',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileInfoScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.shield_outlined,
            title: 'Güvenlik',
            subtitle: '2FA, biyometri',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SecurityPrefsScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.account_circle_outlined,
            title: 'Hesap',
            subtitle: 'E-posta doğrulama, hesap silme',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.notifications_none_rounded,
            title: 'Bildirim tercihleri',
            subtitle: 'Push, alarm, özet',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationPrefsScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.history_rounded,
            title: 'Güncelleme geçmişi',
            subtitle: 'Yeni özellik ve düzeltmeler',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReleaseNotesScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.info_outline_rounded,
            title: 'Hakkında',
            subtitle: 'Sürüm ve yasal metinler',
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.local_offer_outlined,
            title: 'Katkılarım',
            subtitle: 'Paylaştığın fiyatlar',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ContributionsScreen())),
          ),
          const SizedBox(height: 10),
          _HubRow(
            icon: Icons.grid_view_rounded,
            title: 'Keşfe dön',
            subtitle: 'Radarı incele',
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
    setState(() {
      _verifyBusy = true;
      _verifyMessage = null;
    });
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      setState(() => _verifyMessage =
          'Doğrulama bağlantısı ${user.email ?? "e-postana"} gönderildi.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _verifyMessage =
          'Gönderilemedi: ${e.message ?? e.code}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifyMessage = 'Gönderilemedi: $e');
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _deleteBusy = true;
      _deleteError = null;
    });
    final state = AppStateScope.read(context);
    final uid = user.uid;
    try {
      // Best-effort: drop FCM token + the user doc before deleting auth so
      // we don't leave a tombstone with the user's profile data behind.
      try {
        await MessagingService.instance.clearTokenForCurrentUser();
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
          'Bu işlem geri alınamaz.',
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
                    'puanları kalıcı olarak kaldırır.',
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
