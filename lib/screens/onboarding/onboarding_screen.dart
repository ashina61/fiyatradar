import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/neo_design.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _items = [
    ('Canlı Fiyat Akışı', 'Güncel fiyatları tek panelde gör, hızlı karar ver.'),
    ('Akıllı Karşılaştırma', 'Sepetini market bazında kıyasla, en iyi kombinasyonu seç.'),
    ('Topluluk Gücü', 'Fiyat ekle, puan topla, güven skorunu büyüt.'),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeoScaffold(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text('FiyatRadar 2.0', style: NeoDesign.title()),
              const SizedBox(height: 6),
              Text('Sıfırdan tasarlanan sade ve hızlı deneyim.', style: NeoDesign.body()),
              const SizedBox(height: 20),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, i) => Container(
                    padding: const EdgeInsets.all(22),
                    decoration: NeoDesign.glassCard(highlighted: true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.radar, size: 54, color: NeoDesign.secondary),
                        const Spacer(),
                        Text(_items[i].$1, style: NeoDesign.title(30)),
                        const SizedBox(height: 10),
                        Text(_items[i].$2, style: NeoDesign.body(color: NeoDesign.text.withOpacity(0.8))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: i == _index ? 30 : 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: i == _index ? NeoDesign.primary : NeoDesign.muted.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _index == _items.length - 1
                      ? _complete
                      : () => _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut),
                  child: Text(_index == _items.length - 1 ? 'Başla' : 'Devam'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
