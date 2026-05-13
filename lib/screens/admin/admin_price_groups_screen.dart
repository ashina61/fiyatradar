import 'package:flutter/material.dart';

import '../../models/price_reporting.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';

/// Admin moderasyon: yeni omurgadaki `priceGroups` dokümanlarını
/// görüntüleme + sayaçları sıfırlama. Audit raporundaki
/// "Yeni omurga için admin moderation tool yok" maddesine yanıt.
///
/// Buton akışı:
///   • Reset: `verifiedCount` 0, `confidence` low. Rules `lastReporterId ==
///     auth.uid` invariant'ını koruyor — adminin uid'siyle yazılır.
///   • adminActions log'u: `priceGroup.reset` aksiyonu admin denetim için
///     ayrı koleksiyona düşer.
///
/// Production iyileştirmesi: reset Cloud Function'a taşınmalı; rule cap'i
/// (counter +1 only) admin context'inde gevşetilmiyor — bu nedenle reset'in
/// gerçek "0'a indir" davranışı için server-side çağrı gerek. Şu anki
/// implementation **sayaç ileri-yön** olduğu için DENIED olur — UI sadece
/// `confidence='low'` ve `latestPrice = trustedPrice` set'ini başarılı yapar.
class AdminPriceGroupsScreen extends StatelessWidget {
  const AdminPriceGroupsScreen({super.key});

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
              child: Row(children: [
                FRIconChip(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: FRPageHeader(
                overline: 'ADMIN · MODERASYON',
                title: 'Bölgesel fiyat grupları',
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<List<PriceGroupModel>>(
                stream: state.watchAdminRecentPriceGroups(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
                      child: FRSkeletonList(
                        count: 6,
                        itemHeight: 96,
                        radius: 16,
                      ),
                    );
                  }
                  final groups = snap.data ?? const <PriceGroupModel>[];
                  if (groups.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'Henüz priceGroup yok.',
                          style:
                              frText(13, FontWeight.w700, color: FR.ink3),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _PriceGroupRow(state: state, group: groups[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceGroupRow extends StatelessWidget {
  const _PriceGroupRow({required this.state, required this.group});
  final AppState state;
  final PriceGroupModel group;

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bu grubu resetle'),
        content: Text(
          'Bu işlem ${group.chainName} · ${group.districtName} grubunun '
          'güven sayaçlarını sıfırlar. Geri alınamaz.\n\n'
          'Sayaçlar: reportCount=${group.reportCount} · '
          'verifiedCount=${group.verifiedCount} · '
          'confidence=${group.confidence}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resetle'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await state.adminResetPriceGroupAggregates(groupId: group.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grup reset edildi.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset başarısız: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: frSurface(radius: FRRad.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(group.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: frText(13.5, FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              FRPriceText(group.preferredPrice ?? group.latestPrice,
                  size: 16, color: FR.gold),
            ],
          ),
          const SizedBox(height: 6),
          Text(group.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: frText(11.5, FontWeight.w700, color: FR.ink3)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pill(label: 'Bildirim · ${group.reportCount}'),
              _Pill(label: 'Doğrulama · ${group.verifiedCount}'),
              _Pill(label: 'Foto · ${group.photoReportCount}'),
              _Pill(label: 'Güven · ${confidenceLabelTr(group.confidence)}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: FRCta(
                label: 'Sıfırla',
                icon: Icons.refresh_rounded,
                filled: false,
                height: 36,
                onTap: () => _confirmReset(context),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FR.bgElev,
        borderRadius: FRRad.all(999),
        border: Border.all(color: FR.hairline),
      ),
      child: Text(label, style: frText(10.5, FontWeight.w800, color: FR.ink2)),
    );
  }
}

// AdminStorePlacesPendingScreen kaldırıldı: bekleyen mağaza onayları artık
// Admin > Mağaza sekmesinde inline gösteriliyor ve "Hepsini gör" linki
// AdminStoreManagementScreen'in "Onay Bekleyen" sekmesini açıyor.
