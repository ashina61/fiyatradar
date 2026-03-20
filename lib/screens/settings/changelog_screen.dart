import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/fr_colors.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  static const List<_ChangelogEntry> _entries = <_ChangelogEntry>[
    _ChangelogEntry(
      version: 'v1.0.0 - Sürüm Adayı',
      dateLabel: 'Mart 2026',
      title: 'V6 Executive Güncellemesi & Güvenlik Kalkanı',
      features: <_FeatureLine>[
        _FeatureLine(description: 'Tasarım Dili Yenilendi: FiyatRadar artık çok daha premium ve lüks bir arayüze (V6) sahip.'),
        _FeatureLine(description: 'Güvenlik Duvarı: Sahte hesapları engellemek için zorunlu E-Posta doğrulama sistemi getirildi.'),
        _FeatureLine(description: 'Dinamik Puan Sistemi: Oyunlaştırma altyapısı tek bir merkeze bağlandı, puan ve seviye kazanımları kusursuzlaştırıldı.'),
        _FeatureLine(description: 'Akıllı Arama: Fiyat ekleme ekranında sadece onaylı ürünlerde arama yapma ve yeni ürün talep etme özelliği eklendi.'),
        _FeatureLine(description: 'Bildirim Merkezi: Rütbe atladığınızda veya fiyat alarmınız tetiklendiğinde anında haberdar olacağınız yepyeni bir bildirim merkezi kuruldu.'),
      ],
    ),
    _ChangelogEntry(
      version: 'FR 3.1',
      dateLabel: 'BUGÜN',
      title: 'Mimari Devrim & Premium UI',
      features: <_FeatureLine>[
        _FeatureLine(
          label: 'Porsche DNA',
          description:
              'Ana sayfa banner modülü lüks tasarım diliyle yeniden yazıldı. Köşe sızmaları bıçak gibi kesildi.',
        ),
        _FeatureLine(
          label: 'Single Source',
          description:
              'Profil ve sistemdeki parçalı yapı tek bir globale bağlandı. Veri tutarsızlığı bitti.',
        ),
        _FeatureLine(
          label: 'Kurşun Geçirmez',
          description:
              'Firestore güvenlik kuralları senkronize edildi, crash riskleri WriteBatch ile sıfırlandı.',
        ),
        _FeatureLine(
          label: 'Hukuki Kalkan',
          description:
              'Kayıt ekranına premium tasarımlı, loglanabilir KVKK onayı eklendi.',
        ),
      ],
    ),
    _ChangelogEntry(
      version: 'FR 3.0',
      dateLabel: '30.01.2026',
      title: 'Profil ve Deneyim',
      features: <_FeatureLine>[
        _FeatureLine(description: 'Profil düzenleme ekranı yeniden tasarlandı ve akış sadeleştirildi.'),
        _FeatureLine(description: 'Konum yönetimi il/ilçe/mahalle odaklı yapıya geçirildi.'),
        _FeatureLine(description: 'Yardım, ayarlar ve bilgi ekranları tek bir dilde birleştirildi.'),
      ],
    ),
    _ChangelogEntry(
      version: 'FR 2.5',
      dateLabel: '10.11.2025',
      title: 'Topluluk ve Güven',
      features: <_FeatureLine>[
        _FeatureLine(description: 'Fiyat doğrulama oyları ve güven puanı hesaplama altyapısı geliştirildi.'),
        _FeatureLine(description: 'Liderlik tablosu puan, seviye ve rozet göstergeleriyle güncellendi.'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: FRColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, topPadding + 18, 24, 12),
              child: Row(
                children: [
                  _TopActionButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: _Header(),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = _entries[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == _entries.length - 1 ? 0 : 20),
                    child: _ChangelogCard(entry: entry, isVip: index == 0),
                  );
                },
                childCount: _entries.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Sürüm Notları',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: FRColors.espresso,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'RADARDAKİ SON GELİŞMELER',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FRColors.camel,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangelogCard extends StatelessWidget {
  const _ChangelogCard({required this.entry, required this.isVip});

  final _ChangelogEntry entry;
  final bool isVip;

  @override
  Widget build(BuildContext context) {
    final contentColor = isVip ? FRColors.white : FRColors.espresso;
    final mutedColor = isVip ? FRColors.white.withOpacity(0.7) : FRColors.textMutedSoft;
    final cardDecoration = BoxDecoration(
      color: isVip ? null : FRColors.surface,
      gradient: isVip
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1D120C),
                Color(0xFF2A190F),
                Color(0xFF24140F),
              ],
              stops: [0, 0.52, 1],
            )
          : null,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: isVip ? const Color(0xFFD8B377).withOpacity(0.65) : FRColors.border,
      ),
      boxShadow: [
        if (isVip)
          const BoxShadow(
            color: Color(0x26150D09),
            blurRadius: 40,
            spreadRadius: 1,
            offset: Offset(0, 18),
          )
        else
          BoxShadow(
            color: FRColors.espresso.withOpacity(0.03),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
      ],
    );

    return Container(
      decoration: cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            if (isVip) ...[
              Positioned(
                top: -60,
                right: -50,
                child: IgnorePointer(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0x80D2A25E),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.72],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -60,
                child: IgnorePointer(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0x26E9D2A7),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.78],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _VersionPill(version: entry.version, isVip: isVip),
                      const Spacer(),
                      Text(
                        entry.dateLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isVip ? const Color(0xCCF1E7D7) : FRColors.textMutedSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    entry.title,
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: contentColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: entry.features
                        .map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _FeatureRow(
                              feature: feature,
                              isVip: isVip,
                              textColor: mutedColor,
                              strongColor: contentColor,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({required this.version, required this.isVip});

  final String version;
  final bool isVip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: isVip
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0BE84),
                  Color(0xFFC9995A),
                ],
              )
            : null,
        color: isVip ? null : FRColors.background,
        borderRadius: BorderRadius.circular(999),
        border: isVip
            ? Border.all(color: const Color(0xFFF0D6A5).withOpacity(0.65))
            : Border.all(color: FRColors.border),
        boxShadow: isVip
            ? [
                BoxShadow(
                  color: const Color(0x40AE7B44),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVip) ...[
            const _PulseDot(),
            const SizedBox(width: 8),
          ],
          Text(
            version,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: FRColors.espresso,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 0.5 + _controller.value;
          final opacity = (0.8 * (1 - _controller.value)).clamp(0.0, 0.8);
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: FRColors.espresso,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: FRColors.espresso,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.feature,
    required this.isVip,
    required this.textColor,
    required this.strongColor,
  });

  final _FeatureLine feature;
  final bool isVip;
  final Color textColor;
  final Color strongColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _DiamondSpark(isVip: isVip),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              children: [
                if (feature.label != null)
                  TextSpan(
                    text: '${feature.label}: ',
                    style: TextStyle(
                      color: strongColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                TextSpan(text: feature.description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DiamondSpark extends StatelessWidget {
  const _DiamondSpark({required this.isVip});

  final bool isVip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isVip ? FRColors.camel : FRColors.espresso.withOpacity(0.08),
        boxShadow: isVip
            ? [
                BoxShadow(
                  color: FRColors.camel.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Transform.rotate(
        angle: math.pi / 4,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isVip ? FRColors.camel : FRColors.espresso.withOpacity(0.08),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: FRColors.surface,
                shape: BoxShape.rectangle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FRColors.surfaceSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FRColors.border),
            boxShadow: [
              BoxShadow(
                color: FRColors.espresso.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: FRColors.espresso),
        ),
      ),
    );
  }
}

class _ChangelogEntry {
  const _ChangelogEntry({
    required this.version,
    required this.dateLabel,
    required this.title,
    required this.features,
    this.isVip = false,
  });

  final String version;
  final String dateLabel;
  final String title;
  final List<_FeatureLine> features;
  final bool isVip;
}

class _FeatureLine {
  const _FeatureLine({this.label, required this.description});

  final String? label;
  final String description;
}
