// lib/screens/legal/legal_screen.dart
// GREENFIELD v2 — legal / disclaimer dossier in the "Quiet Intelligence" language.
// A long-form editorial page: title, subtitle, hairline-separated sections of body text.
// Written in the same voice as the rest of the app: calm, confident, human.

import 'package:flutter/material.dart';

import '../../theme/fr_ink.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  static const _sections = <_LegalSection>[
    _LegalSection(
      label: 'SORUMLULUK REDDİ',
      title: 'FiyatRadar bir satış kanalı değildir.',
      body:
          'FiyatRadar; topluluk üyeleri tarafından bildirilen fiyatları toplayan, '
          'karşılaştıran ve trend eden bir bilgi platformudur. Gösterilen fiyatlar '
          'gerçek zamanlı resmi mağaza fiyatları değildir; kullanıcıların raf fotoğrafları '
          've girdilerinden üretilir. Nihai ödeme tutarı, kampanyalar, stok durumu ve '
          'bölgesel farklar için ilgili mağazanın kendi kanallarını esas alın.',
    ),
    _LegalSection(
      label: 'KVKK · VERİ İŞLEME',
      title: 'Verini senin için şeffaf tutuyoruz.',
      body:
          '6698 sayılı KVKK kapsamında; ad, e-posta, kullanıcı adı ve katkı geçmişi '
          'yalnızca hesabınızın işletilmesi, topluluk güven puanının hesaplanması ve '
          'platformun geliştirilmesi amacıyla işlenir. Verileriniz üçüncü taraflarla '
          'pazarlama amacıyla paylaşılmaz. Silme, düzeltme veya dışa aktarma talepleri '
          'için ayarlar ekranından bize ulaşabilirsiniz.',
    ),
    _LegalSection(
      label: 'TOPLULUK KURALLARI',
      title: 'Güven topluluğun üzerine kurulur.',
      body:
          'Doğru ve güncel fiyat bildir. Reklam, spam, hakaret, kişisel bilgi paylaşımı '
          've ürün olmayan içerikler yasaktır. Hatalı bildirimler topluluk oylamasıyla '
          'puanını düşürür; tekrarlayan ihlaller hesabın askıya alınmasına yol açabilir. '
          'Her katkı, bir sonraki kullanıcı için daha net bir fiyat haritası demektir.',
    ),
    _LegalSection(
      label: 'FİKRİ MÜLKİYET',
      title: 'Markalar sahiplerine aittir.',
      body:
          'Uygulamada geçen tüm marka adları, logolar ve ürün görselleri ilgili '
          'sahiplerinin tescilli varlıklarıdır. FiyatRadar bu markaların resmi temsilcisi '
          'veya iş ortağı değildir; yalnızca fiyat referansı amacıyla atıfta bulunur.',
    ),
    _LegalSection(
      label: 'İLETİŞİM',
      title: 'Bir şey yanlış görünüyorsa bize yaz.',
      body:
          'Veri silme, içerik itirazı, hata bildirimi veya iş birliği için '
          'legal@fiyatradar.app adresine ulaşabilirsin. Geri dönüşleri bir iş günü '
          'içinde yanıtlamaya çalışıyoruz.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FRInk.paper,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(FRInk.gutter, 14, FRInk.gutter, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Icon(Icons.arrow_back_rounded, size: 24, color: FRInk.ink),
                    ),
                    const Spacer(),
                    const Text('HUKUK', style: FRType.micro),
                    const Spacer(),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(FRInk.gutter, 28, FRInk.gutter, 6),
                child: Text('Yasal bilgiler', style: FRType.title),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(FRInk.gutter, 0, FRInk.gutter, 22),
                child: Text(
                  'Topluluk, güven ve verinin çerçevesi. Kısa ve açık.',
                  style: FRType.body,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: FRHairline()),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i.isOdd) return const FRHairline();
                  return _SectionBlock(section: _sections[i ~/ 2]);
                },
                childCount: _sections.length * 2 - 1,
              ),
            ),
            const SliverToBoxAdapter(child: FRHairline()),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(FRInk.gutter, 22, FRInk.gutter, 40),
                child: Text(
                  'Bu belge yalnızca bilgilendirme amaçlıdır ve hukuki bağlayıcılığı '
                  'Kullanım Şartları ile Gizlilik Politikası metinlerine atıfla oluşur.',
                  style: TextStyle(
                    fontFamily: FRType.family,
                    fontSize: 12,
                    height: 1.5,
                    color: FRInk.inkMute,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection({required this.label, required this.title, required this.body});
  final String label;
  final String title;
  final String body;
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});
  final _LegalSection section;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 26, FRInk.gutter, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.label, style: FRType.micro),
          const SizedBox(height: 10),
          Text(section.title, style: FRType.subtitle),
          const SizedBox(height: 10),
          Text(section.body, style: FRType.body.copyWith(height: 1.55)),
        ],
      ),
    );
  }
}
