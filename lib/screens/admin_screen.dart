import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/firebase_service.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
import 'admin/admin_crud_screens.dart';
import 'admin/admin_price_groups_screen.dart';
import 'admin/admin_price_reports_screen.dart';
import 'admin/admin_shared_widgets.dart';
import 'admin/admin_store_management_screen.dart';
import 'admin/admin_user_edit_screen.dart';
import 'admin/banner_form_screen.dart';
import 'admin/product_form_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int tab = 0;
  // The flat 8-chip layout buried tools off-screen and an even 4-group
  // grouping made every chip look equally important — admins lost track
  // of where to start. We now elevate the four most-used tools (Panel,
  // Ürünler, Fiyatlar, Moderasyon) as full-width primary tiles and tuck
  // the secondary tools (Banner, Talepler, Doğrulama, Ayarlar) into a
  // single "Diğer araçlar" chip row underneath.
  static const _primaryTabs = <_AdminTabSpec>[
    _AdminTabSpec(0, 'Panel', Icons.space_dashboard_rounded,
        subtitle: 'Canlı özet'),
    _AdminTabSpec(1, 'Ürünler', Icons.inventory_2_rounded,
        subtitle: 'Katalog yönetimi'),
    _AdminTabSpec(4, 'Fiyatlar', Icons.price_change_rounded,
        subtitle: 'Fiyat moderasyonu'),
    _AdminTabSpec(6, 'Moderasyon', Icons.gavel_rounded,
        subtitle: 'Topluluk kararları'),
  ];

  static const _secondaryTabs = <_AdminTabSpec>[
    _AdminTabSpec(2, 'Banner', Icons.campaign_rounded),
    _AdminTabSpec(3, 'Talepler', Icons.inbox_rounded),
    _AdminTabSpec(5, 'Doğrulama', Icons.verified_rounded),
    _AdminTabSpec(7, 'Ayarlar', Icons.settings_rounded),
  ];

  String get _activeLabel {
    for (final t in _primaryTabs) {
      if (t.index == tab) return t.label;
    }
    for (final t in _secondaryTabs) {
      if (t.index == tab) return t.label;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    if (!state.isAdmin) {
      return const _AdminUnauthorizedScreen();
    }
    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
              child: Row(
                children: [
                  FRIconChip(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                    decoration: BoxDecoration(
                      color: FR.gold.withOpacity(.14),
                      borderRadius: FRRad.all(999),
                      border: Border.all(color: FR.goldDeep.withOpacity(.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FRLiveDot(),
                        const SizedBox(width: 6),
                        Text('KONTROL CANLI',
                            style: frOverline(color: FR.gold, size: 9.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
              child: FRPageHeader(
                overline: 'FİYATRADAR · ${_activeLabel.toUpperCase()}',
                title: 'Admin',
                italicTail: ' konsolu',
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _AdminTabBoard(
                primary: _primaryTabs,
                secondary: _secondaryTabs,
                activeIndex: tab,
                onSelect: (i) => setState(() => tab = i),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                children: [_buildTab(state)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(AppState state) {
    switch (tab) {
      case 0:
        return _Panel(state: state);
      case 1:
        return _ProductsTab(state: state);
      case 2:
        return _BannersTab(state: state);
      case 3:
        return _RequestsTab(state: state);
      case 4:
        return _PricesTab(state: state);
      case 5:
        return _VerificationTab(state: state);
      case 6:
        return _ModerationTab(state: state);
      default:
        return _SettingsTab(state: state);
    }
  }
}

class _AdminUnauthorizedScreen extends StatelessWidget {
  const _AdminUnauthorizedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            FRSpace.xl,
            FRSpace.m,
            FRSpace.xl,
            FRSpace.xxl - FRSpace.xs,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  FRIconChip(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      FRSpace.xl,
                      FRSpace.xl,
                      FRSpace.xl,
                      FRSpace.xl,
                    ),
                    decoration: frSurface(radius: FRRad.l),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 32, color: FR.bad),
                        const SizedBox(height: 10),
                        Text('Yetkin yok', style: frDisplay(24, FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          'Bu alan yalnızca admin kullanıcılar için erişilebilir.',
                          textAlign: TextAlign.center,
                          style: frText(12.5, FontWeight.w600, color: FR.ink3, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTabSpec {
  const _AdminTabSpec(this.index, this.label, this.icon, {this.subtitle});
  final int index;
  final String label;
  final IconData icon;
  final String? subtitle;
}

/// Calm command-center navigation: one active-module hero, then grouped
/// chips. This keeps every tool reachable without turning the first viewport
/// into an admin control cemetery.
class _AdminTabBoard extends StatelessWidget {
  const _AdminTabBoard({
    required this.primary,
    required this.secondary,
    required this.activeIndex,
    required this.onSelect,
  });
  final List<_AdminTabSpec> primary;
  final List<_AdminTabSpec> secondary;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final tools = [...primary, ...secondary];
    final active = tools.firstWhere(
      (t) => t.index == activeIndex,
      orElse: () => primary.first,
    );
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        FRSpace.l - 2,
        FRSpace.l - 2,
        FRSpace.l - 2,
        FRSpace.l - 2,
      ),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.xl),
        border: Border.all(color: FR.hairline),
        boxShadow: frShadow(opacity: .08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(
              FRSpace.l - 2,
              FRSpace.l - 2,
              FRSpace.l - 2,
              FRSpace.l - 2,
            ),
            decoration: BoxDecoration(
              color: FRPalette.dark.bgElev,
              borderRadius: FRRad.all(FRRad.l),
              border: Border.all(color: FR.goldDeep.withOpacity(.38)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: FR.gold.withOpacity(.16),
                    borderRadius: FRRad.all(14),
                    border: Border.all(color: FR.goldDeep.withOpacity(.45)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(active.icon, color: FR.goldHi, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AKTİF MODÜL',
                          style: frOverline(color: FR.goldHi, size: 9.5)),
                      const SizedBox(height: 3),
                      Text(active.label,
                          style: frDisplay(19, FontWeight.w800,
                              color: FRPalette.dark.ink)),
                      if (active.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(active.subtitle!,
                            style: frText(11.5, FontWeight.w700,
                                color: FRPalette.dark.ink2)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('ANA AKIŞ', style: frOverline(color: FR.ink3, size: 9.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in primary)
                _AdminTabChip(
                  spec: t,
                  active: t.index == activeIndex,
                  onTap: () => onSelect(t.index),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('DESTEK ARAÇLARI', style: frOverline(color: FR.ink3, size: 9.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in secondary)
                _AdminTabChip(
                  spec: t,
                  active: t.index == activeIndex,
                  onTap: () => onSelect(t.index),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminTabChip extends StatelessWidget {
  const _AdminTabChip({
    required this.spec,
    required this.active,
    required this.onTap,
  });
  final _AdminTabSpec spec;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? FR.gold : FR.surface,
          borderRadius: FRRad.all(999),
          border: Border.all(color: active ? FR.gold : FR.hairline),
          boxShadow: active ? frGoldGlow(opacity: .18) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spec.icon,
                size: 14, color: active ? FR.onGold : FR.ink2),
            const SizedBox(width: 6),
            Text(
              spec.label,
              style: frText(12, FontWeight.w800,
                  color: active ? FR.onGold : FR.ink2, letter: .2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Panel (runtime aggregates) ─────────────────────────────────────────────

class _Panel extends StatelessWidget {
  const _Panel({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final products = state.products;
    final fresh = state.freshContributionCountLast24h;
    final pending = state.adminPendingEntries.length;
    final disputed = state.adminDisputedEntries.length;
    final verified = state.aggregateVerifiedCount;
    final trust = state.catalogTrustPercent;

    final recent = state.adminRecentEntries.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: '$fresh',
                    label: 'SON 24S KATKI',
                    delta: fresh > 0 ? 'canlı' : 'beklemede',
                    deltaGood: fresh > 0)),
            const SizedBox(width: 10),
            Expanded(
                child: _StatCard(
                    value: '$pending',
                    label: 'İNCELEMEDE',
                    delta: pending > 0 ? 'topluluğa açık' : 'temiz',
                    deltaGood: pending == 0)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: '$verified',
                    label: 'DOĞRULANMIŞ FİYAT',
                    delta: '${products.length} ürün',
                    deltaGood: true)),
            const SizedBox(width: 10),
            Expanded(
                child: _StatCard(
                    value: trust == 0 ? '—' : '%$trust',
                    label: 'KATALOG GÜVENİ',
                    delta: disputed > 0 ? '$disputed ihtilaf' : 'stabil',
                    deltaGood: disputed == 0)),
          ],
        ),
        const SizedBox(height: 18),
        const FRSectionHead(eyebrow: 'CANLI', title: 'Son katkılar'),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          adminEmpty('Topluluktan henüz katkı gelmedi.')
        else
          adminRowList([
            for (final r in recent)
              _EntryRow(product: r.$1, entry: r.$2),
          ]),
      ],
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final products = state.products;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FRCta(
          label: 'Yeni ürün ekle',
          icon: Icons.add_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductFormScreen(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (products.isEmpty)
          adminEmpty('Henüz ürün yok.')
        else
          adminRowList([
            for (final p in products)
              _ProductAdminRow(product: p),
          ]),
      ],
    );
  }
}

class _ProductAdminRow extends StatelessWidget {
  const _ProductAdminRow({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductFormScreen(existing: product),
        ),
      ),
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
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
                  Text(
                    '${product.brand} · ${product.unit} · ${product.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frText(11, FontWeight.w600, color: FR.ink3),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${product.validEntries.length} fiyat · %${product.aggregateTrustPercent} güven',
                    style: frText(10.5, FontWeight.w800, color: FR.gold),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, color: FR.ink3, size: 17),
          ],
        ),
      ),
    );
  }
}

// ─── Banner management ──────────────────────────────────────────────────────

class _BannersTab extends StatelessWidget {
  const _BannersTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseService.instance.banners.snapshots();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FRCta(
          label: 'Yeni banner ekle',
          icon: Icons.add_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BannerFormScreen()),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
          decoration: BoxDecoration(
            color: FR.gold.withOpacity(.08),
            borderRadius: FRRad.all(FRRad.m),
            border: Border.all(color: FR.gold.withOpacity(.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  color: FR.gold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Banner içerik sayfası veya direkt yönlendirme olarak çalışır. Yönlendirme örnekleri: cheapest, newest, favorites, category:İçecek',
                  style: frText(11, FontWeight.w600, color: FR.ink2, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (_, snap) {
            if (snap.hasError) return adminEmpty('Banner verisi yüklenemedi.');
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? const [];
            if (docs.isEmpty) return adminEmpty('Henüz banner yok.');
            final banners = docs.map(AppBanner.fromDoc).toList()
              ..sort((a, b) => a.order.compareTo(b.order));
            return adminRowList([
              for (final b in banners)
                _BannerAdminRow(banner: b),
            ]);
          },
        ),
      ],
    );
  }
}

class _BannerAdminRow extends StatelessWidget {
  const _BannerAdminRow({required this.banner});
  final AppBanner banner;

  String _routeSummary() {
    if (banner.actionType == 'route') {
      return banner.actionTarget.isEmpty
          ? 'Yönlendirme · hedef yok'
          : 'Yönlendirme · ${banner.actionTarget}';
    }
    return banner.contentBlocks.isEmpty
        ? 'İçerik sayfası · boş'
        : 'İçerik sayfası · ${banner.contentBlocks.length} blok';
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FR.surface,
        title: Text('Banner\'ı sil', style: frDisplay(20, FontWeight.w700)),
        content: Text(
          'Bu banner kalıcı olarak silinecek.',
          style: frText(13, FontWeight.w600, color: FR.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal',
                style: frText(13, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: frText(13, FontWeight.w800, color: FR.bad)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (banner.imagePath != null && banner.imagePath!.isNotEmpty) {
      await FirebaseService.instance.deleteStorageFile(banner.imagePath!);
    }
    await FirebaseService.instance.banners.doc(banner.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BannerFormScreen(existing: banner),
        ),
      ),
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: FR.surfaceHi,
                borderRadius: FRRad.all(14),
                border: Border.all(color: FR.hairline),
              ),
              child: banner.hasImage
                  ? Image.network(
                      banner.imageUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: 220,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.campaign_rounded, color: FR.gold),
                    )
                  : Icon(Icons.campaign_rounded, color: FR.gold, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(banner.title.replaceAll('\n', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: frText(13.5, FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(banner.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                  const SizedBox(height: 3),
                  Text(_routeSummary(),
                      style: frText(10.5, FontWeight.w800, color: FR.gold)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _delete(context),
              icon: Icon(Icons.delete_outline_rounded,
                  color: FR.bad, size: 18),
              padding: EdgeInsets.zero, // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pending =
        state.productRequests.where((r) => r.isPending).toList();
    final decided =
        state.productRequests.where((r) => !r.isPending).take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FRSectionHead(eyebrow: 'BEKLEYEN', title: 'Onay bekleyen talepler'),
        const SizedBox(height: 10),
        if (pending.isEmpty)
          adminEmpty('Bekleyen talep yok.')
        else
          adminRowList([
            for (final r in pending)
              _RequestRow(request: r, state: state),
          ]),
        const SizedBox(height: 18),
        const FRSectionHead(
          eyebrow: 'GEÇMİŞ',
          title: 'Onaylanmış / reddedilmiş talepler',
        ),
        const SizedBox(height: 10),
        if (decided.isEmpty)
          adminEmpty('Henüz karar verilmiş talep yok.')
        else
          adminRowList([
            for (final r in decided)
              _RequestRow(request: r, state: state, readOnly: true),
          ]),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.state,
    this.readOnly = false,
  });
  final ProductRequest request;
  final AppState state;
  final bool readOnly;

  Color get _statusColor {
    switch (request.status) {
      case 'approved':
        return FR.good;
      case 'rejected':
        return FR.bad;
      default:
        return FR.warn;
    }
  }

  String get _statusLabel {
    switch (request.status) {
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Bekliyor';
    }
  }

  Future<void> _approve(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await state.adminApproveRequest(req: request);
      messenger.showSnackBar(
        SnackBar(content: Text('${request.name} kataloğa eklendi.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Talep onaylanamadı.')),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FR.surface,
        title: Text('Talebi reddet', style: frDisplay(20, FontWeight.w700)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Gerekçe (opsiyonel)'),
          style: frText(13, FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: frText(13, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonCtrl.text.trim()),
            child: Text('Reddet', style: frText(13, FontWeight.w800, color: FR.bad)),
          ),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await state.adminRejectRequest(req: request, reason: reason);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.name} reddedildi.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Talep reddedilemedi.')),
      );
    }
  }

  Future<void> _convert(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen.fromRequest(request: request),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FR.surfaceHi,
                  borderRadius: FRRad.all(12),
                  border: Border.all(color: FR.hairline),
                ),
                alignment: Alignment.center,
                child: Text(request.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: frText(13, FontWeight.w800)),
                    Text(
                      '${request.brand} · ${request.unit} · ${request.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: frText(11, FontWeight.w600, color: FR.ink3),
                    ),
                    const SizedBox(height: 2),
                    Text('Talep eden: ${request.requestedByName}',
                        style: frText(10.5, FontWeight.w700, color: FR.ink3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(.14),
                  borderRadius: FRRad.all(999),
                  border: Border.all(color: _statusColor.withOpacity(.35)),
                ),
                child: Text(_statusLabel,
                    style: frText(10, FontWeight.w800, color: _statusColor)),
              ),
            ],
          ),
          if (request.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(request.note,
                style: frText(11.5, FontWeight.w600, color: FR.ink2)),
          ],
          if (!readOnly) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _approve(context),
                    borderRadius: FRRad.all(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FR.good.withOpacity(.14),
                        borderRadius: FRRad.all(999),
                        border: Border.all(color: FR.good.withOpacity(.4)),
                      ),
                      child: Text('Onayla',
                          style: frText(12, FontWeight.w800, color: FR.good)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _convert(context),
                    borderRadius: FRRad.all(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FR.gold.withOpacity(.14),
                        borderRadius: FRRad.all(999),
                        border: Border.all(color: FR.gold.withOpacity(.4)),
                      ),
                      child: Text('Düzenleyip ekle',
                          style: frText(12, FontWeight.w800, color: FR.gold)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _reject(context),
                    borderRadius: FRRad.all(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FR.bad.withOpacity(.14),
                        borderRadius: FRRad.all(999),
                        border: Border.all(color: FR.bad.withOpacity(.4)),
                      ),
                      child: Text('Reddet',
                          style: frText(12, FontWeight.w800, color: FR.bad)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (readOnly && request.rejectionReason != null) ...[
            const SizedBox(height: 6),
            Text('Gerekçe: ${request.rejectionReason}',
                style: frText(11, FontWeight.w600, color: FR.ink3)),
          ],
        ],
      ),
    );
  }
}

/// Admin-only full-screen form for creating or editing a product.
/// `existing` → edit; `fromRequest` → prefill from a pending request and
/// mark that request as approved after save.
class _PricesTab extends StatelessWidget {
  const _PricesTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final recent = state.adminRecentEntries.take(20).toList();
    if (recent.isEmpty) return adminEmpty('Fiyat akışı boş.');
    return adminRowList([
      for (final r in recent) _EntryRow(product: r.$1, entry: r.$2),
    ]);
  }
}

class _VerificationTab extends StatefulWidget {
  const _VerificationTab({required this.state});
  final AppState state;

  @override
  State<_VerificationTab> createState() => _VerificationTabState();
}

class _VerificationTabState extends State<_VerificationTab> {
  int _section = 0;
  static const _sections = [
    ('Bekleyen', Icons.schedule_rounded),
    ('İhtilaflı', Icons.help_outline_rounded),
    ('Doğrulanmış', Icons.verified_rounded),
    ('Reddedilen', Icons.block_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final pending = state.adminPendingEntries.take(40).toList();
    final disputed = state.adminDisputedEntries.take(40).toList();

    final verified = <(Product, PriceEntry)>[];
    final rejected = <(Product, PriceEntry)>[];
    for (final p in state.products) {
      for (final e in p.priceHistory) {
        if (e.status == PriceStatus.communityVerified) {
          verified.add((p, e));
        } else if (e.status == PriceStatus.rejected) {
          rejected.add((p, e));
        }
      }
    }
    verified.sort((a, b) => b.$2.date.compareTo(a.$2.date));
    rejected.sort((a, b) => b.$2.date.compareTo(a.$2.date));

    final counts = [
      pending.length,
      disputed.length,
      verified.length,
      rejected.length,
    ];

    final activeList = switch (_section) {
      0 => pending,
      1 => disputed,
      2 => verified.take(40).toList(),
      _ => rejected.take(40).toList(),
    };
    final emptyLabel = switch (_section) {
      0 => 'Bekleyen fiyat yok.',
      1 => 'İhtilaflı fiyat yok.',
      2 => 'Henüz doğrulanmış fiyat yok.',
      _ => 'Reddedilmiş fiyat yok.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _sections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _VerificationSectionChip(
              label: _sections[i].$1,
              icon: _sections[i].$2,
              count: counts[i],
              active: i == _section,
              onTap: () => setState(() => _section = i),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (activeList.isEmpty)
          adminEmpty(emptyLabel)
        else
          adminRowList([
            for (final r in activeList)
              _AdminEntryActionRow(product: r.$1, entry: r.$2, state: state),
          ]),
      ],
    );
  }
}

class _VerificationSectionChip extends StatelessWidget {
  const _VerificationSectionChip({
    required this.label,
    required this.icon,
    required this.count,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = FRRad.all(999);
    return Material(
      color: active ? FR.gold : FR.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: active ? FR.gold : FR.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: active ? FR.bg : FR.ink2),
              const SizedBox(width: 6),
              Text(label,
                  style: frText(12, FontWeight.w800,
                      color: active ? FR.bg : FR.ink2, letter: .2)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 6, 2),
                decoration: BoxDecoration(
                  color: active
                      ? FR.bg.withOpacity(.18)
                      : FR.bgElev,
                  borderRadius: FRRad.all(8),
                ),
                child: Text('$count',
                    style: frText(10, FontWeight.w800,
                        color: active ? FR.bg : FR.ink3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminEntryActionRow extends StatelessWidget {
  const _AdminEntryActionRow({
    required this.product,
    required this.entry,
    required this.state,
  });
  final Product product;
  final PriceEntry entry;
  final AppState state;

  Future<void> _setStatus(BuildContext context, PriceStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await state.adminSetPriceEntryStatus(
        productId: product.id,
        entryId: entry.id,
        status: status,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Durum güncellendi: ${_statusLabel(status)}')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Durum güncellenemedi.')),
      );
    }
  }

  String _statusLabel(PriceStatus s) {
    switch (s) {
      case PriceStatus.communityVerified:
        return 'Katalog onaylı';
      case PriceStatus.disputed:
        return 'İhtilaflı';
      case PriceStatus.rejected:
        return 'Reddedildi';
      case PriceStatus.pending:
        return 'Beklemede';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = entry.status == PriceStatus.communityVerified;
    final isRejected = entry.status == PriceStatus.rejected;
    return Container(
      padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FR.surfaceHi,
                  borderRadius: FRRad.all(12),
                  border: Border.all(color: FR.hairline),
                ),
                alignment: Alignment.center,
                child: Text(product.emoji, style: const TextStyle(fontSize: 19)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${product.name} · ${entry.store}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: frText(13, FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.reportedBy} · ${entry.price.toStringAsFixed(2)} ₺ · '
                      '↑${entry.upvotes} ↓${entry.downvotes}',
                      style: frText(11, FontWeight.w600, color: FR.ink3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FRVerifyBadge.status(
                status: statusToString(entry.status),
                trustPercent: entry.trustPercent,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  label: isVerified ? 'Onaylı' : 'Katalog onayla',
                  color: FR.good,
                  dimmed: isVerified,
                  onTap: isVerified
                      ? null
                      : () => _setStatus(context, PriceStatus.communityVerified),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionPill(
                  label: 'Beklemeye al',
                  color: FR.warn,
                  dimmed: false,
                  onTap: () => _setStatus(context, PriceStatus.pending),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionPill(
                  label: isRejected ? 'Reddedildi' : 'Reddet',
                  color: FR.bad,
                  dimmed: isRejected,
                  onTap: isRejected
                      ? null
                      : () => _setStatus(context, PriceStatus.rejected),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.color,
    required this.onTap,
    required this.dimmed,
  });
  final String label;
  final Color color;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = FRRad.all(999);
    return Material(
      color: color.withOpacity(dimmed ? .06 : .14),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 9, 0, 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: color.withOpacity(dimmed ? .2 : .4)),
          ),
          child: Text(
            label,
            style: frText(11.5, FontWeight.w800,
                color: color.withOpacity(dimmed ? .55 : 1)),
          ),
        ),
      ),
    );
  }
}

class _ModerationTab extends StatelessWidget {
  const _ModerationTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final rejected = state.adminRejectedEntries.take(20).toList();
    if (rejected.isEmpty) return adminEmpty('Reddedilmiş fiyat yok.');
    return adminRowList([
      for (final r in rejected) _EntryRow(product: r.$1, entry: r.$2),
    ]);
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return adminRowList([
      const _GenericRow(
        title: 'Minimum oy sayısı',
        subtitle:
            '${VerificationRules.minVotesForStatus} oy sonrası durum değişir',
        icon: Icons.verified_rounded,
        withActions: false,
      ),
      const _GenericRow(
        title: 'Doğrulama eşiği',
        subtitle:
            'Güven ağırlıklı skor ≥ ${VerificationRules.verifyScore} → doğrulandı',
        icon: Icons.tune_rounded,
        withActions: false,
      ),
      const _GenericRow(
        title: 'Red eşiği',
        subtitle:
            'Güven ağırlıklı skor ≤ ${VerificationRules.rejectScore} → reddedildi',
        icon: Icons.block_rounded,
        withActions: false,
      ),
      _GenericRow(
        title: 'Senin trust ağırlığın',
        subtitle:
            '%${state.trustScorePercent} güven · oyun ${state.voteWeight.toStringAsFixed(2)}x ağırlıkta',
        icon: Icons.shield_moon_outlined,
        withActions: false,
      ),
      _GenericRow(
        title: 'Mağaza Yönetimi',
        subtitle: 'Zincirler · mağazalar · pending · eski kayıtlar',
        icon: Icons.domain_add_rounded,
        withActions: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminStoreManagementScreen()),
        ),
      ),
      _GenericRow(
        title: 'Kategori yönetimi',
        subtitle: 'Ekle · düzenle · sil',
        icon: Icons.category_outlined,
        withActions: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminCategoryCrudScreen()),
        ),
      ),
      _GenericRow(
        title: 'Kullanıcı düzenleme',
        subtitle: 'Ad · kullanıcı adı · admin rolü',
        icon: Icons.people_outline_rounded,
        withActions: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminUserEditScreen()),
        ),
      ),
      _GenericRow(
        title: 'Bölgesel fiyat grupları',
        subtitle: 'priceGroups · sayaç sıfırla · şüpheli grup işaretle',
        icon: Icons.hub_outlined,
        withActions: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminPriceGroupsScreen()),
        ),
      ),
      _GenericRow(
        title: 'Bekleyen marketler',
        subtitle: 'Topluluk önerilen yerleri onayla / reddet',
        icon: Icons.storefront_outlined,
        withActions: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AdminStorePlacesPendingScreen()),
        ),
      ),
      _GenericRow(
        title: 'Fiyat raporları',
        subtitle: 'Gelen raporları incele',
        icon: Icons.flag_outlined,
        withActions: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminPriceReportsScreen()),
        ),
      ),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.delta,
    required this.deltaGood,
  });
  final String value;
  final String label;
  final String delta;
  final bool deltaGood;

  @override
  Widget build(BuildContext context) {
    final deltaColor = deltaGood ? FR.good : FR.warn;
    return Container(
      padding: const EdgeInsets.all(14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.goldDeep.withOpacity(.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: frOverline(color: FR.ink3, size: 9.5)),
          const SizedBox(height: 10),
          Text(value, style: frDisplay(28, FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
            decoration: BoxDecoration(
              color: deltaColor.withOpacity(.14),
              borderRadius: FRRad.all(999),
              border: Border.all(color: deltaColor.withOpacity(.35)),
            ),
            child: Text(delta,
                style: frText(10.5, FontWeight.w800, color: deltaColor)),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.product, required this.entry});
  final Product product;
  final PriceEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FR.surfaceHi,
              borderRadius: FRRad.all(12),
              border: Border.all(color: FR.hairline),
            ),
            alignment: Alignment.center,
            child: Text(product.emoji, style: const TextStyle(fontSize: 19)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${product.name} · ${entry.store}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frText(13, FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${entry.reportedBy} · ${entry.price.toStringAsFixed(2)} ₺ · '
                  '↑${entry.upvotes} ↓${entry.downvotes}',
                  style: frText(11, FontWeight.w600, color: FR.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FRVerifyBadge.status(
            status: statusToString(entry.status),
            trustPercent: entry.trustPercent,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _GenericRow extends StatelessWidget {
  const _GenericRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.withActions,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool withActions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.hairline),
        ),
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
              child: Icon(icon, size: 17, color: FR.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: frText(13, FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: frText(11, FontWeight.w600, color: FR.ink3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (withActions)
              Icon(Icons.chevron_right_rounded, color: FR.ink3),
          ],
        ),
      ),
    );
  }
}


