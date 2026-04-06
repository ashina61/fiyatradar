import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';

class HelpAndFaqScreen extends StatelessWidget {
  const HelpAndFaqScreen({super.key});

  static const List<({String question, String answer})> _items = [
    (
      question: 'Puan sistemi nasıl çalışır?',
      answer: 'Her fiyat katkısı puan kazandırır. Doğruluk arttıkça güven skorunuz yükselir ve seviye ilerlersiniz.',
    ),
    (
      question: 'Güven puanı nasıl kazanılır?',
      answer: 'Topluluk ve sistem tarafından doğrulanan katkılar güven skorunu artırır.',
    ),
    (
      question: 'Fiyat nasıl eklerim?',
      answer: 'Fiyat Ekle akışında ürün seçip fiyat/market bilgisi girerek katkınızı kaydedebilirsiniz.',
    ),
    (
      question: 'Hesap silme talebi nasıl oluşturulur?',
      answer: 'Ayarlar ekranındaki hesap silme aksiyonu üzerinden destek ekibine yönlendirilirsiniz.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FRAppScaffold(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FRDarkHero(
              title: 'Yardım ve SSS',
              subtitle: 'Sık sorulan sorular ve kullanım rehberi',
              kicker: const FRKickerPill('Product Maturity'),
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
                  eyebrow: 'KULLANIM REHBERİ',
                  title: 'En çok sorulanlar',
                  children: [
                    for (final item in _items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: FRDsSpacing.space8),
                        child: FRSurfaceCard(
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(item.question, style: FRDsTypography.titleMedium),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(item.answer, style: FRDsTypography.bodyMedium),
                              ),
                            ],
                          ),
                        ),
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
}
