import 'package:flutter/material.dart';

import '../../utils/theme.dart';

class UpdateHistoryScreen extends StatelessWidget {
  const UpdateHistoryScreen({super.key});

  static const updates = <Map<String, String>>[
    {
      'version': 'v1.5.0',
      'date': '2025 Q2',
      'title': 'Premium Profil Deneyimi',
      'notes': 'Profil header tasarımı yenilendi, güven skoru backend verisine bağlandı ve seviye görünümü sadeleştirildi.',
    },
    {
      'version': 'v1.4.0',
      'date': '2025 Q1',
      'title': 'Rozet ve Kart İyileştirmeleri',
      'notes': 'Seviye rozetleri görsel olarak standartlaştırıldı ve fiyat kartı tipografisi düzenlendi.',
    },
    {
      'version': 'v1.3.0',
      'date': '2024 Q4',
      'title': 'Hesap Yönetimi Güncellemesi',
      'notes': 'Bildirimler, favoriler ve profil düzenleme deneyimi yenilendi.',
    },
    {
      'version': 'v1.2.0',
      'date': '2024 Q3',
      'title': 'Ürün Detay Güçlendirme',
      'notes': 'Ürün detayları iyileştirildi. En ucuz mağaza listesi ve katkı yapan kullanıcı bilgileri güçlendirildi.',
    },
    {
      'version': 'v1.1.0',
      'date': '2024 Q2',
      'title': 'Puan Sistemi Lansmanı',
      'notes': 'Puan sistemi, seviyeler ve katkı geçmişi ekranları eklendi.',
    },
    {
      'version': 'v1.0.0',
      'date': '2024 Q1',
      'title': 'İlk Yayın',
      'notes': 'FiyatRadar yayınlandı. Ürün arama, fiyat ekleme ve temel profil altyapısı aktif edildi.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Güncelleme Geçmişi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...updates.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: const Color(0xFFDCE7F8)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${item['version']} • ${item['date']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(item['notes']!, style: const TextStyle(height: 1.35)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
