import 'package:flutter/material.dart';

class UpdateHistoryScreen extends StatelessWidget {
  const UpdateHistoryScreen({super.key});

  static const _items = <Map<String, dynamic>>[
    {
      'version': '30.01.2026 • FR 3.0',
      'date': 'Profil ve deneyim güncellemesi',
      'notes': [
        'Profil düzenleme ekranı yeniden tasarlandı ve akış sadeleştirildi.',
        'Konum yönetimi il/ilçe/mahalle odaklı yapıya geçirildi.',
        'Yardım, ayarlar ve bilgi ekranları tek bir dilde birleştirildi.',
      ],
    },
    {
      'version': '10.11.2025 • FR 2.5',
      'date': 'Topluluk ve güven sistemi',
      'notes': [
        'Fiyat doğrulama oyları ve güven puanı hesaplama altyapısı geliştirildi.',
        'Liderlik tablosu puan, seviye ve rozet göstergeleriyle güncellendi.',
        'Bildirim tercihleri kampanya/alarm/rozet ayrımına göre detaylandırıldı.',
      ],
    },
    {
      'version': '18.08.2025 • FR 2.0',
      'date': 'Karşılaştırma ve sepet dönemi',
      'notes': [
        'Sepet karşılaştırma ekranı ve market bazlı toplam kıyaslama özelliği eklendi.',
        'Ürün detay sayfalarında fiyat geçmişi ve katkı görünürlüğü artırıldı.',
        'Favori ürün, arama geçmişi ve kampanya modülleri iyileştirildi.',
      ],
    },
    {
      'version': '03.05.2025 • FR 1.5',
      'date': 'Katkı akışlarının güçlendirilmesi',
      'notes': [
        'Fiyat ekleme adımları sadeleştirildi, fotoğraflı katkı desteği genişletildi.',
        'Kategori, marka ve market verileri genişletilerek arama kalitesi artırıldı.',
        'Temel performans, yükleme ve hata yönetimi iyileştirmeleri yapıldı.',
      ],
    },
    {
      'version': '23.12.2024 • FR 1.0',
      'date': 'İlk yayın',
      'notes': [
        'Uygulamanın kemik yapısı oluşturuldu.',
        'Ana sayfalar, giriş/kayıt ve profil ekranları yayına alındı.',
        'İlk fiyat paylaşımı ve ürün listeleme akışı tamamlandı.',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF9).withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF8B4D22)),
        title: const Text('Güncelleme Geçmişi', style: TextStyle(color: Color(0xFF2D241E), fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x148B4D22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _items
                  .expand((item) => [
                        _block(item),
                        if (item != _items.last) const Divider(height: 32, color: Color(0x148B4D22)),
                      ])
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _block(Map<String, dynamic> item) {
    final notes = (item['notes'] as List<dynamic>).cast<String>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['version'].toString(),
          style: const TextStyle(fontSize: 16, color: Color(0xFF8B4D22), fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          item['date'].toString(),
          style: const TextStyle(fontSize: 13, color: Color(0xFF8E8A86), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...notes.map(
          (note) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text('• ', style: TextStyle(color: Color(0xFF8B4D22), fontWeight: FontWeight.w700)),
                ),
                Expanded(child: Text(note, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF2D241E)))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
