import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  static const List<({String version, String date, String title, List<String> notes})> _entries = [
    (
      version: 'v1.0.0',
      date: 'Mart 2026',
      title: 'Executive Güncelleme',
      notes: [
        'Tasarım dili ve ekran hiyerarşisi standardize edildi.',
        'Güvenlik ve doğrulama akışları güçlendirildi.',
        'Topluluk katkı kalitesi için altyapı iyileştirildi.',
      ],
    ),
    (
      version: 'FR 3.1',
      date: 'BUGÜN',
      title: 'Premium UI İyileştirmeleri',
      notes: [
        'Profil ve sistem ekranlarında tutarlılık artırıldı.',
        'Veri tutarlılığı ve crash önlemleri geliştirildi.',
      ],
    ),
    (
      version: 'FR 3.0',
      date: '30.01.2026',
      title: 'Profil ve Deneyim',
      notes: [
        'Profil düzenleme akışı sadeleştirildi.',
        'Yardım ve ayar ekranları tek dilde birleştirildi.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FRAppScaffold(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FRDarkHero(
              title: 'Sürüm Notları',
              subtitle: 'Radar ürün yolculuğundaki güncellemeler',
              kicker: const FRKickerPill('Release Notes'),
              leading: FRHeroActionButton(
                icon: CupertinoIcons.back,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FRPageContainer(
              child: Padding(
                padding: const EdgeInsets.only(top: FRDsSpacing.space20, bottom: FRDsSpacing.space32),
                child: FRAccountShortcutsSection(
                  eyebrow: 'ÜRÜN GELİŞİMİ',
                  title: 'Son sürümler',
                  children: [
                    for (var i = 0; i < _entries.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: FRDsSpacing.space12),
                        child: i == 0 ? _darkEntry(_entries[i]) : _lightEntry(_entries[i]),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkEntry(({String version, String date, String title, List<String> notes}) entry) {
    return FRDarkFeatureCard(
      child: _entryBody(entry, isDark: true),
    );
  }

  Widget _lightEntry(({String version, String date, String title, List<String> notes}) entry) {
    return FRSurfaceCard(
      child: _entryBody(entry),
    );
  }

  Widget _entryBody(({String version, String date, String title, List<String> notes}) entry, {bool isDark = false}) {
    final titleStyle = isDark
        ? FRDsTypography.titleLarge.copyWith(color: FRDsColors.frSurface)
        : FRDsTypography.titleLarge;
    final noteStyle = isDark
        ? FRDsTypography.bodyMedium.copyWith(color: FRDsColors.frGoldSoft)
        : FRDsTypography.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FRPill(entry.version, variant: isDark ? FRPillVariant.gold : FRPillVariant.soft),
            const Spacer(),
            Text(entry.date, style: noteStyle),
          ],
        ),
        const SizedBox(height: FRDsSpacing.space12),
        Text(entry.title, style: titleStyle),
        const SizedBox(height: FRDsSpacing.space12),
        ...entry.notes.map((note) => Padding(
              padding: const EdgeInsets.only(bottom: FRDsSpacing.space8),
              child: Text('• $note', style: noteStyle),
            )),
      ],
    );
  }
}
