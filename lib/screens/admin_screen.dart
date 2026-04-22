import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int tab = 0;
  static const tabs = [
    'Panel',
    'Ürünler',
    'Fiyatlar',
    'Doğrulama',
    'Moderasyon',
    'Ayarlar',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: FR.gold.withOpacity(.14),
                      borderRadius: FRRad.all(999),
                      border: Border.all(color: FR.goldDeep.withOpacity(.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FRLiveDot(),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: FRPageHeader(
                overline: 'FİYATRADAR KONTROL MERKEZİ',
                title: 'Admin',
                italicTail: ' konsolu',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _TabChip(
                  label: tabs[i],
                  active: tab == i,
                  onTap: () => setState(() => tab = i),
                ),
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
    switch (tab) {
      case 0:
        return _Panel(state: state);
      case 1:
        return _ProductsTab(state: state);
      case 2:
        return _PricesTab(state: state);
      case 3:
        return _VerificationTab(state: state);
      case 4:
        return _ModerationTab(state: state);
      default:
        return _SettingsTab(state: state);
    }
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? FR.gold : FR.surface,
          borderRadius: FRRad.all(999),
          border: Border.all(color: active ? FR.gold : FR.hairline),
        ),
        child: Text(
          label,
          style: frText(12, FontWeight.w800,
              color: active ? FR.bg : FR.ink2, letter: .2),
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
    final pending = _collectEntries(products, status: PriceStatus.pending).length;
    final disputed =
        _collectEntries(products, status: PriceStatus.disputed).length;
    final verified = state.aggregateVerifiedCount;
    final trust = state.catalogTrustPercent;

    final recent = _recentEntries(products).take(4).toList();

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
        FRSectionHead(eyebrow: 'CANLI', title: 'Son katkılar'),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          _empty('Topluluktan henüz katkı gelmedi.')
        else
          _rowList([
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
    if (products.isEmpty) return _empty('Henüz ürün yok.');
    return _rowList([
      for (final p in products)
        _GenericRow(
          title: p.name,
          subtitle:
              '${p.validEntries.length} fiyat · ${p.verifiedCount} doğrulama · %${p.aggregateTrustPercent} güven',
          icon: Icons.inventory_2_rounded,
          withActions: false,
        ),
    ]);
  }
}

class _PricesTab extends StatelessWidget {
  const _PricesTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final recent = _recentEntries(state.products).take(20).toList();
    if (recent.isEmpty) return _empty('Fiyat akışı boş.');
    return _rowList([
      for (final r in recent) _EntryRow(product: r.$1, entry: r.$2),
    ]);
  }
}

class _VerificationTab extends StatelessWidget {
  const _VerificationTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pending =
        _collectEntries(state.products, status: PriceStatus.pending).take(20).toList();
    final disputed =
        _collectEntries(state.products, status: PriceStatus.disputed).take(20).toList();
    if (pending.isEmpty && disputed.isEmpty) {
      return _empty('Tüm fiyatlar doğrulanmış.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (disputed.isNotEmpty) ...[
          FRSectionHead(eyebrow: 'DİKKAT', title: 'İhtilaflı fiyatlar'),
          const SizedBox(height: 10),
          _rowList([
            for (final r in disputed) _EntryRow(product: r.$1, entry: r.$2),
          ]),
          const SizedBox(height: 18),
        ],
        if (pending.isNotEmpty) ...[
          FRSectionHead(eyebrow: 'BEKLEYEN', title: 'Topluluk oyuna açık'),
          const SizedBox(height: 10),
          _rowList([
            for (final r in pending) _EntryRow(product: r.$1, entry: r.$2),
          ]),
        ],
      ],
    );
  }
}

class _ModerationTab extends StatelessWidget {
  const _ModerationTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final rejected =
        _collectEntries(state.products, status: PriceStatus.rejected)
            .take(20)
            .toList();
    if (rejected.isEmpty) return _empty('Reddedilmiş fiyat yok.');
    return _rowList([
      for (final r in rejected) _EntryRow(product: r.$1, entry: r.$2),
    ]);
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _rowList([
      _GenericRow(
        title: 'Minimum oy sayısı',
        subtitle:
            '${VerificationRules.minVotesForStatus} oy sonrası durum değişir',
        icon: Icons.verified_rounded,
        withActions: false,
      ),
      _GenericRow(
        title: 'Doğrulama eşiği',
        subtitle:
            'Güven ağırlıklı skor ≥ ${VerificationRules.verifyScore} → doğrulandı',
        icon: Icons.tune_rounded,
        withActions: false,
      ),
      _GenericRow(
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
    ]);
  }
}

Widget _empty(String label) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: frSurface(radius: FRRad.l),
    alignment: Alignment.center,
    child: Text(label, style: frText(12.5, FontWeight.w600, color: FR.ink3)),
  );
}

Widget _rowList(List<Widget> rows) {
  return Column(
    children: [
      for (var i = 0; i < rows.length; i++) ...[
        rows[i],
        if (i < rows.length - 1) const SizedBox(height: 10),
      ],
    ],
  );
}

/// Flatten products into (product, entry) pairs filtered by status.
List<(Product, PriceEntry)> _collectEntries(
  List<Product> products, {
  PriceStatus? status,
}) {
  final out = <(Product, PriceEntry)>[];
  for (final p in products) {
    for (final e in p.priceHistory) {
      if (status == null || e.status == status) out.add((p, e));
    }
  }
  out.sort((a, b) => b.$2.date.compareTo(a.$2.date));
  return out;
}

List<(Product, PriceEntry)> _recentEntries(List<Product> products) {
  return _collectEntries(products);
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool withActions;

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
    );
  }
}
