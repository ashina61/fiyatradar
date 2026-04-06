import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/tokens/colors.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  static const List<({String version, String date, String title, bool dark, List<String> notes})> _entries = [
    (
      version: 'v1.0.0 - Sürüm Adayı',
      date: 'Mart 2026',
      title: 'V6 Executive Güncellemesi & Güvenlik Kalkanı',
      dark: true,
      notes: [
        'Tasarım dili yenilendi: FiyatRadar artık daha premium ve lüks bir arayüze (V6) sahip.',
        'Güvenlik duvarı: sahte hesapları engellemek için zorunlu e-posta doğrulama sistemi getirildi.',
        'Dinamik puan sistemi: oyunlaştırma altyapısı tek bir merkeze bağlandı.',
        'Akıllı arama: fiyat ekleme ekranında onaylı ürün arama ve yeni ürün talep etme eklendi.',
        'Bildirim merkezi: rütbe ve alarm tetiklerinde anlık haber akışı sağlandı.',
      ],
    ),
    (
      version: 'FR 3.0',
      date: '30.01.2026',
      title: 'Profil ve Deneyim',
      dark: false,
      notes: [
        'Profil düzenleme ekranı yeniden tasarlandı ve akış sadeleştirildi.',
        'Konum yönetimi il/ilçe/mahalle odaklı yapıya geçirildi.',
        'Yardım, ayarlar ve bilgi ekranları tek bir dilde birleştirildi.',
      ],
    ),
    (
      version: 'FR 2.5',
      date: '10.11.2025',
      title: 'Topluluk ve Güven',
      dark: false,
      notes: [
        'Fiyat doğrulama oyları ve güven puanı hesaplama altyapısı geliştirildi.',
        'Liderlik tablosu puan, seviye ve rozet göstergeleri güncellendi.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FRDsColors.frBackground,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: FRDsColors.frSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(CupertinoIcons.back, size: 24),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sürüm Notları',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: Color(0xFF180E0B),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'RADARDAKİ SON GELİŞMELER',
              style: TextStyle(
                fontSize: 15,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC39963),
              ),
            ),
            const SizedBox(height: 24),
            for (final entry in _entries) ...[
              _EntryCard(entry: entry),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final ({String version, String date, String title, bool dark, List<String> notes}) entry;

  @override
  Widget build(BuildContext context) {
    final dark = entry.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF23130E) : FRDsColors.frSurface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: dark ? const Color(0xFF8C643D) : const Color(0x111A100C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFFE2BC8A) : const Color(0xFFF1EFEB),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  entry.version,
                  style: TextStyle(
                    color: dark ? const Color(0xFF2A1A14) : const Color(0xFF2E241D),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                entry.date,
                style: TextStyle(
                  color: dark ? const Color(0xFFBFA998) : FRDsColors.frTextMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            entry.title,
            style: TextStyle(
              color: dark ? Colors.white : const Color(0xFF180E0B),
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final note in entry.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      CupertinoIcons.star_fill,
                      size: 14,
                      color: dark ? const Color(0xFFE2BC8A) : const Color(0xFFD9D5CF),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: dark ? const Color(0xFFDDCEC3) : FRDsColors.frTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
