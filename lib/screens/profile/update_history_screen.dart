import 'package:flutter/material.dart';

class UpdateHistoryScreen extends StatelessWidget {
  const UpdateHistoryScreen({super.key});

  static const _items = <Map<String, dynamic>>[
    {
      'version': 'v3.0.0',
      'date': 'Bugün',
      'notes': [
        'Profil düzenleme alanı sayfa yapısına geçirildi. Jilet gibi animasyon eklendi.',
        'Market bulma algoritması için mahalle detayına kadar konum seçimi eklendi.',
        'Uygulama DNA\'sına uygun yepyeni karamel/kahve tonlarına geçildi.',
        'Gereksiz hesap dondurma ve tüm cihazlardan çıkış butonları kaldırıldı.',
      ],
    },
    {
      'version': 'v2.1.0',
      'date': 'Geçen Hafta',
      'notes': [
        'Liderlik tablosundaki puan hataları giderildi. (Bug Fixes)',
        'Önbellek temizleme butonu ayarlar menüsüne eklendi.',
        'Bildirim tercihleri (Kampanya, Alarm) detaylandırıldı.',
      ],
    },
    {
      'version': 'v1.0.0',
      'date': 'İlk Çıkış',
      'notes': [
        'FiyatRadar ilk sürümüyle marketlerde yerini aldı! Piyasayı sallamaya hazırız.',
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
          '${item['version']} (${item['date']})',
          style: const TextStyle(fontSize: 16, color: Color(0xFF8B4D22), fontWeight: FontWeight.w700),
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
