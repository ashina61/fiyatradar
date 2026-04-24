import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../services/firebase_service.dart';
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
    this.italicTail,
    required this.child,
  });
  final String overline;
  final String title;
  final String? italicTail;
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
                italicTail: italicTail,
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
      if (_pendingProfileImage != null && state.user != null) {
        final res = await FirebaseService.instance.uploadUserProfileImage(
          uid: state.user!.uid,
          bytes: _pendingProfileImage!,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil bilgileri güncellendi.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                      ? Image.network(state.profileImageUrl!, fit: BoxFit.cover)
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

class SecurityPrefsScreen extends StatelessWidget {
  const SecurityPrefsScreen({super.key});

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
            onChanged: (v) =>
                state.updateSecuritySettings(twoFactorEnabled: v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.fingerprint_rounded,
            title: 'Biyometri',
            subtitle: 'Parmak izi / Face ID ile hızlı giriş',
            value: state.biometricEnabled,
            onChanged: (v) =>
                state.updateSecuritySettings(biometricEnabled: v),
          ),
        ],
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
  final ValueChanged<bool> onChanged;

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
