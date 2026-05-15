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

/// Admin console — beş mantıksal modül halinde gruplanmış kontrol paneli.
///
/// Modüller:
///   • PANEL   → canlı KPI'lar ve son aktivite
///   • KATALOG → ürünler, talepler ve kategori yönetimi
///   • FİYAT   → moderasyon (bekleyen / ihtilaflı / doğrulanmış / reddedilen),
///                fiyat raporları, bölgesel gruplar
///   • MAĞAZA  → zincir & şube özetleri, bekleyen onaylar ve derin yönetim
///   • SİSTEM  → banner yönetimi, kullanıcı düzenleme, doğrulama eşikleri
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;

  static const _modules = <_AdminModule>[
    _AdminModule(
      index: 0,
      label: 'Panel',
      icon: Icons.space_dashboard_rounded,
      subtitle: 'Canlı özet',
    ),
    _AdminModule(
      index: 1,
      label: 'Katalog',
      icon: Icons.inventory_2_rounded,
      subtitle: 'Ürünler · talepler',
    ),
    _AdminModule(
      index: 2,
      label: 'Fiyat',
      icon: Icons.price_change_rounded,
      subtitle: 'Moderasyon · raporlar',
    ),
    _AdminModule(
      index: 3,
      label: 'Mağaza',
      icon: Icons.storefront_rounded,
      subtitle: 'Zincirler · şubeler',
    ),
    _AdminModule(
      index: 4,
      label: 'Sistem',
      icon: Icons.tune_rounded,
      subtitle: 'Banner · ayar',
    ),
  ];

  _AdminModule get _active =>
      _modules.firstWhere((m) => m.index == _tab, orElse: () => _modules.first);

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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  FRIconChip(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FRPageHeader(
                overline: 'FİYATRADAR · ${_active.label.toUpperCase()}',
                title: 'Admin',
                italicTail: ' konsolu',
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _AdminModuleBar(
                modules: _modules,
                active: _tab,
                onSelect: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [_buildTab(state)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(AppState state) {
    switch (_tab) {
      case 0:
        return _PanelTab(state: state, onJump: (i) => setState(() => _tab = i));
      case 1:
        return _CatalogTab(state: state);
      case 2:
        return _PriceFlowTab(state: state);
      case 3:
        return const _StoreNetworkTab();
      default:
        return _SystemTab(state: state);
    }
  }
}

// ─── Unauthorized fallback ──────────────────────────────────────────────────

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
                          style: frText(12.5, FontWeight.w600,
                              color: FR.ink3, height: 1.45),
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

// ─── Module bar (segmented top navigation) ─────────────────────────────────

class _AdminModule {
  const _AdminModule({
    required this.index,
    required this.label,
    required this.icon,
    required this.subtitle,
  });
  final int index;
  final String label;
  final IconData icon;
  final String subtitle;
}

class _AdminModuleBar extends StatelessWidget {
  const _AdminModuleBar({
    required this.modules,
    required this.active,
    required this.onSelect,
  });
  final List<_AdminModule> modules;
  final int active;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.xl),
        border: Border.all(color: FR.hairline),
      ),
      child: Row(
        children: [
          for (final m in modules)
            Expanded(
              child: _AdminModuleTile(
                module: m,
                active: m.index == active,
                onTap: () => onSelect(m.index),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminModuleTile extends StatelessWidget {
  const _AdminModuleTile({
    required this.module,
    required this.active,
    required this.onTap,
  });
  final _AdminModule module;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: active ? FR.gold : Colors.transparent,
          borderRadius: FRRad.all(FRRad.l),
          boxShadow: active ? frGoldGlow(opacity: .18) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              module.icon,
              size: 18,
              color: active ? FR.onGold : FR.ink2,
            ),
            const SizedBox(height: 4),
            Text(
              module.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: frText(
                11.5,
                FontWeight.w800,
                color: active ? FR.onGold : FR.ink2,
                letter: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Panel (live aggregates) ────────────────────────────────────────────────

class _PanelTab extends StatelessWidget {
  const _PanelTab({required this.state, required this.onJump});
  final AppState state;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final products = state.products;
    final fresh = state.freshContributionCountLast24h;
    final pending = state.adminPendingEntries.length;
    final disputed = state.adminDisputedEntries.length;
    final verified = state.aggregateVerifiedCount;
    final trust = state.catalogTrustPercent;
    final pendingRequests =
        state.productRequests.where((r) => r.isPending).length;

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
                deltaGood: fresh > 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                value: '$pending',
                label: 'İNCELEMEDE',
                delta: pending > 0 ? 'topluluğa açık' : 'temiz',
                deltaGood: pending == 0,
              ),
            ),
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
                deltaGood: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                value: trust == 0 ? '—' : '%$trust',
                label: 'KATALOG GÜVENİ',
                delta: disputed > 0 ? '$disputed ihtilaf' : 'stabil',
                deltaGood: disputed == 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const FRSectionHead(eyebrow: 'KISAYOL', title: 'Hızlı aksiyon'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickJump(
                icon: Icons.fact_check_outlined,
                label: 'Talepler',
                badge: pendingRequests,
                onTap: () => onJump(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickJump(
                icon: Icons.verified_rounded,
                label: 'Moderasyon',
                badge: pending + disputed,
                onTap: () => onJump(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickJump(
                icon: Icons.storefront_rounded,
                label: 'Mağaza',
                badge: 0,
                onTap: () => onJump(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const FRSectionHead(eyebrow: 'CANLI', title: 'Son katkılar'),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          adminEmpty('Topluluktan henüz katkı gelmedi.')
        else
          adminRowList([
            for (final r in recent) _EntryRow(product: r.$1, entry: r.$2),
          ]),
      ],
    );
  }
}

class _QuickJump extends StatelessWidget {
  const _QuickJump({
    required this.icon,
    required this.label,
    required this.badge,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.hairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: FR.gold),
                if (badge > 0)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: FR.bad,
                        borderRadius: FRRad.all(999),
                        border: Border.all(color: FR.surface, width: 1.5),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: frText(9, FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: frText(11.5, FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

// ─── Catalog (products + requests + categories) ─────────────────────────────

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final products = state.products;
    final pendingRequests =
        state.productRequests.where((r) => r.isPending).toList();
    final decidedRequests =
        state.productRequests.where((r) => !r.isPending).take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FRCta(
          label: 'Yeni ürün ekle',
          icon: Icons.add_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          ),
        ),
        const SizedBox(height: 14),
        _GenericRow(
          title: 'Kategori yönetimi',
          subtitle: 'Kategorileri ekle · düzenle · sil',
          icon: Icons.category_outlined,
          withActions: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCategoryCrudScreen()),
          ),
        ),
        const SizedBox(height: 22),
        FRSectionHead(
          eyebrow: 'KATALOG',
          title: 'Ürünler · ${products.length}',
        ),
        const SizedBox(height: 10),
        if (products.isEmpty)
          adminEmpty('Henüz ürün yok.')
        else
          adminRowList([
            for (final p in products.take(40)) _ProductAdminRow(product: p),
          ]),
        if (products.length > 40) ...[
          const SizedBox(height: 10),
          Center(
            child: Text(
              'İlk 40 ürün gösteriliyor · arama için ürünü Keşfet sekmesinden aç',
              style: frText(11, FontWeight.w700, color: FR.ink3),
            ),
          ),
        ],
        const SizedBox(height: 22),
        FRSectionHead(
          eyebrow: 'BEKLEYEN',
          title: 'Onay bekleyen talepler · ${pendingRequests.length}',
        ),
        const SizedBox(height: 10),
        if (pendingRequests.isEmpty)
          adminEmpty('Bekleyen talep yok.')
        else
          adminRowList([
            for (final r in pendingRequests)
              _RequestRow(request: r, state: state),
          ]),
        if (decidedRequests.isNotEmpty) ...[
          const SizedBox(height: 22),
          const FRSectionHead(
            eyebrow: 'GEÇMİŞ',
            title: 'Son kararlar',
          ),
          const SizedBox(height: 10),
          adminRowList([
            for (final r in decidedRequests)
              _RequestRow(request: r, state: state, readOnly: true),
          ]),
        ],
      ],
    );
  }
}

class _ProductAdminRow extends StatelessWidget {
  const _ProductAdminRow({required this.product});
  final Product product;

  Future<void> _confirmDelete(BuildContext context) async {
    final state = AppStateScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showAdminConfirmDeleteDialog(
      context,
      title: 'Ürünü sil',
      message:
          '${product.name} kalıcı olarak silinecek. Bu işlem geri alınamaz.',
    );
    if (!ok) return;
    try {
      if ((product.imagePath ?? '').isNotEmpty) {
        await FirebaseService.instance.deleteStorageFile(product.imagePath!);
      }
      await state.adminDeleteProduct(product.id);
      messenger.showSnackBar(
        SnackBar(content: Text('${product.name} silindi.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Silinemedi: $e')),
      );
    }
  }

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
        padding: const EdgeInsets.all(12),
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
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Ürünü sil',
              onPressed: () => _confirmDelete(context),
              splashRadius: 18,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              icon: Icon(Icons.delete_outline_rounded,
                  color: FR.bad, size: 19),
            ),
          ],
        ),
      ),
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
            child: Text('İptal',
                style: frText(13, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonCtrl.text.trim()),
            child: Text('Reddet',
                style: frText(13, FontWeight.w800, color: FR.bad)),
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
      padding: const EdgeInsets.all(12),
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
                        style:
                            frText(10.5, FontWeight.w700, color: FR.ink3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(.14),
                  borderRadius: FRRad.all(999),
                  border: Border.all(color: _statusColor.withOpacity(.35)),
                ),
                child: Text(_statusLabel,
                    style:
                        frText(10, FontWeight.w800, color: _statusColor)),
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
                  child: _MiniPill(
                    label: 'Onayla',
                    color: FR.good,
                    onTap: () => _approve(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniPill(
                    label: 'Düzenle',
                    color: FR.gold,
                    onTap: () => _convert(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniPill(
                    label: 'Reddet',
                    color: FR.bad,
                    onTap: () => _reject(context),
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

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(.14),
          borderRadius: FRRad.all(999),
          border: Border.all(color: color.withOpacity(.4)),
        ),
        child: Text(label,
            style: frText(12, FontWeight.w800, color: color)),
      ),
    );
  }
}

// ─── Price flow (verification + reports + price groups) ────────────────────

class _PriceFlowTab extends StatefulWidget {
  const _PriceFlowTab({required this.state});
  final AppState state;

  @override
  State<_PriceFlowTab> createState() => _PriceFlowTabState();
}

class _PriceFlowTabState extends State<_PriceFlowTab> {
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
        const SizedBox(height: 22),
        const FRSectionHead(
          eyebrow: 'RAPORLAR',
          title: 'Topluluk uyarıları',
        ),
        const SizedBox(height: 10),
        _GenericRow(
          title: 'Fiyat raporları',
          subtitle: 'Bayrak kalkan girdileri incele',
          icon: Icons.flag_outlined,
          withActions: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminPriceReportsScreen()),
          ),
        ),
        const SizedBox(height: 10),
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
              Icon(icon, size: 14, color: active ? FR.onGold : FR.ink2),
              const SizedBox(width: 6),
              Text(label,
                  style: frText(12, FontWeight.w800,
                      color: active ? FR.onGold : FR.ink2, letter: .2)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 6, 2),
                decoration: BoxDecoration(
                  color: active
                      ? FR.onGold.withOpacity(.18)
                      : FR.bgElev,
                  borderRadius: FRRad.all(8),
                ),
                child: Text('$count',
                    style: frText(10, FontWeight.w800,
                        color: active ? FR.onGold : FR.ink3)),
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
      padding: const EdgeInsets.all(12),
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

// ─── Store network (inline live view + deep management entry) ──────────────

class _StoreNetworkTab extends StatelessWidget {
  const _StoreNetworkTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live counts (chains + places by channel + pending)
        const _StoreNetworkOverview(),
        const SizedBox(height: 14),
        // Quick actions
        Row(
          children: [
            Expanded(
              child: FRCta(
                label: 'Zincir',
                icon: Icons.add_business_rounded,
                filled: false,
                height: 44,
                onTap: () => _openManagement(context,
                    initialTab: 0, openCreate: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FRCta(
                label: 'Şube',
                icon: Icons.add_location_alt_rounded,
                filled: false,
                height: 44,
                onTap: () => _openManagement(context,
                    initialTab: 1, openCreate: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FRCta(
                label: 'Online',
                icon: Icons.language_rounded,
                filled: false,
                height: 44,
                onTap: () => _openManagement(context,
                    initialTab: 2, openCreate: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FRCta(
          label: 'Mahalle pazarı ekle',
          icon: Icons.local_grocery_store_rounded,
          filled: false,
          height: 44,
          onTap: () => _openManagement(context,
              initialTab: 3, openCreate: true),
        ),
        const SizedBox(height: 14),
        FRCta(
          label: 'Tüm mağaza yönetimini aç',
          icon: Icons.storefront_rounded,
          onTap: () => _openManagement(context),
        ),
        const SizedBox(height: 22),
        // Pending approvals — inline, no separate screen needed for quick triage
        const _PendingPlacesInlineSection(),
        const SizedBox(height: 22),
        // Recently active places
        const _RecentPlacesInlineSection(),
      ],
    );
  }

  void _openManagement(
    BuildContext context, {
    int initialTab = 0,
    bool openCreate = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminStoreManagementScreen(
          initialTab: initialTab,
          openCreateOnLaunch: openCreate,
        ),
      ),
    );
  }
}

class _StoreNetworkOverview extends StatelessWidget {
  const _StoreNetworkOverview();

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService.instance;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.storeChains.limit(200).snapshots(),
      builder: (_, chainsSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: svc.storePlaces.limit(500).snapshots(),
          builder: (_, placesSnap) {
            final chains = chainsSnap.data?.docs ?? const [];
            final places = placesSnap.data?.docs ?? const [];

            int activeChains = 0;
            for (final d in chains) {
              if ((d.data()['isActive'] as bool?) ?? true) activeChains++;
            }

            int physical = 0;
            int online = 0;
            int bazaar = 0;
            int pending = 0;
            for (final d in places) {
              final m = d.data();
              final isActive = (m['isActive'] as bool?) ?? true;
              if (!isActive) continue;
              final status = (m['status'] ?? '').toString();
              if (status == 'pending') pending++;
              final type = (m['type'] ?? '').toString();
              final source = (m['sourceType'] ?? m['channel'] ?? '').toString();
              if (type == 'bazaar') {
                bazaar++;
              } else if (source == 'online' || type == 'online_market') {
                online++;
              } else {
                physical++;
              }
            }

            final loading = chainsSnap.connectionState == ConnectionState.waiting ||
                placesSnap.connectionState == ConnectionState.waiting;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FRPalette.dark.bgElev,
                borderRadius: FRRad.all(FRRad.xl),
                border: Border.all(color: FR.goldDeep.withOpacity(.35)),
                boxShadow: frShadow(opacity: .10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storefront_rounded,
                          color: FR.goldHi, size: 18),
                      const SizedBox(width: 8),
                      Text('MAĞAZA AĞI',
                          style: frOverline(color: FR.goldHi, size: 9.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zincir, şube ve online kaynaklarını tek noktadan yönet.',
                    style: frText(12, FontWeight.w700,
                        color: FRPalette.dark.ink2, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _NetworkStat(
                          label: 'ZİNCİR',
                          value: loading ? '—' : '$activeChains',
                          icon: Icons.account_tree_rounded,
                          accent: FR.goldHi,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NetworkStat(
                          label: 'FİZİKSEL',
                          value: loading ? '—' : '$physical',
                          icon: Icons.storefront_rounded,
                          accent: FRPalette.dark.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _NetworkStat(
                          label: 'ONLINE',
                          value: loading ? '—' : '$online',
                          icon: Icons.language_rounded,
                          accent: FRPalette.dark.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NetworkStat(
                          label: 'PAZAR',
                          value: loading ? '—' : '$bazaar',
                          icon: Icons.local_grocery_store_rounded,
                          accent: FRPalette.dark.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _NetworkStat(
                          label: 'BEKLEYEN',
                          value: loading ? '—' : '$pending',
                          icon: Icons.schedule_rounded,
                          accent: pending > 0
                              ? FR.warn
                              : FRPalette.dark.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _NetworkStat extends StatelessWidget {
  const _NetworkStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: FRPalette.dark.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.goldDeep.withOpacity(.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: frOverline(color: FRPalette.dark.ink2, size: 9)),
                const SizedBox(height: 4),
                Text(value,
                    style: frDisplay(20, FontWeight.w700,
                        color: FRPalette.dark.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingPlacesInlineSection extends StatelessWidget {
  const _PendingPlacesInlineSection();

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: state.watchAdminPendingStorePlaces(limit: 12),
      builder: (_, snap) {
        final items = snap.data ?? const <Map<String, dynamic>>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FRSectionHead(
              eyebrow: 'BEKLEYEN ONAY',
              title: items.isEmpty
                  ? 'Bekleyen market yok'
                  : '${items.length} mağaza önerisi',
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              adminEmpty('Topluluktan bekleyen mağaza önerisi yok.')
            else
              adminRowList([
                for (final m in items.take(5))
                  _InlinePendingPlaceRow(data: m, state: state),
              ]),
            if (items.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AdminStoreManagementScreen(initialTab: 4),
                    ),
                  ),
                  child: Text(
                    'Hepsini gör (${items.length})',
                    style: frText(12, FontWeight.w800, color: FR.gold),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _InlinePendingPlaceRow extends StatelessWidget {
  const _InlinePendingPlaceRow({required this.data, required this.state});
  final Map<String, dynamic> data;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final id = (data['id'] ?? '').toString();
    final name = (data['displayName'] ?? data['name'] ?? '—').toString();
    final city = (data['cityName'] ?? data['city'] ?? '').toString();
    final district = (data['districtName'] ?? data['district'] ?? '').toString();
    final region = [district, city]
        .where((e) => e.trim().isNotEmpty)
        .join(' / ');
    return Container(
      padding: const EdgeInsets.all(12),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: FR.warn.withOpacity(.14),
                  borderRadius: FRRad.all(12),
                  border: Border.all(color: FR.warn.withOpacity(.35)),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.storefront_rounded,
                    color: FR.warn, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: frText(13, FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(region.isEmpty ? 'Bölgesi belirsiz' : region,
                        style:
                            frText(11, FontWeight.w700, color: FR.ink3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniPill(
                  label: 'Onayla',
                  color: FR.good,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await state.adminApproveStorePlace(id);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Mağaza onaylandı.')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniPill(
                  label: 'Reddet',
                  color: FR.bad,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await state.adminRejectStorePlace(id);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Mağaza reddedildi.')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentPlacesInlineSection extends StatelessWidget {
  const _RecentPlacesInlineSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.instance.storePlaces
          .orderBy('updatedAt', descending: true)
          .limit(6)
          .snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FRSectionHead(
              eyebrow: 'SON HAREKET',
              title: 'Son güncellenen mağazalar',
            ),
            const SizedBox(height: 10),
            if (docs.isEmpty)
              adminEmpty('Kayıt yok.')
            else
              adminRowList([
                for (final d in docs)
                  _RecentPlaceRow(data: d.data()),
              ]),
          ],
        );
      },
    );
  }
}

class _RecentPlaceRow extends StatelessWidget {
  const _RecentPlaceRow({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = (data['displayName'] ?? data['name'] ?? '—').toString();
    final type = (data['type'] ?? '').toString();
    final source = (data['sourceType'] ?? data['channel'] ?? '').toString();
    final isOnline = source == 'online' || type == 'online_market';
    final city = (data['cityName'] ?? data['city'] ?? '').toString();
    final district = (data['districtName'] ?? data['district'] ?? '').toString();
    final region = isOnline
        ? 'Online'
        : ([district, city].where((e) => e.trim().isNotEmpty).join(' / ').isEmpty
            ? 'Bölge yok'
            : [district, city].where((e) => e.trim().isNotEmpty).join(' / '));
    final status = (data['status'] ?? '').toString();
    final statusColor = switch (status) {
      'verified' => FR.good,
      'trusted' => FR.gold,
      'pending' => FR.warn,
      'rejected' => FR.bad,
      _ => FR.ink3,
    };
    return Container(
      padding: const EdgeInsets.all(12),
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
            alignment: Alignment.center,
            child: Icon(
              isOnline ? Icons.language_rounded : Icons.storefront_rounded,
              color: FR.gold,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frText(13, FontWeight.w800)),
                const SizedBox(height: 2),
                Text(region,
                    style: frText(11, FontWeight.w700, color: FR.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(.14),
              borderRadius: FRRad.all(999),
              border: Border.all(color: statusColor.withOpacity(.35)),
            ),
            child: Text(
              status.isEmpty ? '—' : status,
              style: frText(10, FontWeight.w800, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── System (banners, users, thresholds) ───────────────────────────────────

class _SystemTab extends StatelessWidget {
  const _SystemTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FRSectionHead(
          eyebrow: 'BANNER',
          title: 'Aktif banner yönetimi',
        ),
        const SizedBox(height: 10),
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
          padding: const EdgeInsets.all(12),
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
                  'Banner içerik sayfası veya doğrudan yönlendirme olarak çalışır. '
                  'Yönlendirme örnekleri: cheapest, newest, favorites, category:İçecek',
                  style: frText(11, FontWeight.w600,
                      color: FR.ink2, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseService.instance.banners.snapshots(),
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
              for (final b in banners) _BannerAdminRow(banner: b),
            ]);
          },
        ),
        const SizedBox(height: 22),
        const FRSectionHead(
          eyebrow: 'KULLANICILAR',
          title: 'Topluluk yönetimi',
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 22),
        const FRSectionHead(
          eyebrow: 'DOĞRULAMA EŞİKLERİ',
          title: 'Sistem ayarları',
        ),
        const SizedBox(height: 10),
        adminRowList([
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
        ]),
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
            child: Text('Sil',
                style: frText(13, FontWeight.w800, color: FR.bad)),
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
        padding: const EdgeInsets.all(12),
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
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared building blocks ────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(14),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      padding: const EdgeInsets.all(12),
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
        padding: const EdgeInsets.all(12),
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
              alignment: Alignment.center,
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
            if (withActions) Icon(Icons.chevron_right_rounded, color: FR.ink3),
          ],
        ),
      ),
    );
  }
}
