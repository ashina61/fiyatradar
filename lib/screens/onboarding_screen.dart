import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      emoji: '📡',
      title: 'Canlı Fiyat Sinyali',
      body:
          'Topluluk her gün binlerce fiyat gözlemi ekliyor. Gerçek zamanlı veri, anlık karar.',
      tag: 'GERÇEK ZAMANLI',
    ),
    _Slide(
      emoji: '⚖️',
      title: 'Akıllı Karşılaştırma',
      body:
          'Marketleri yan yana gör. En avantajlı sepeti tek ekranda hesapla. Tasarrufu kaybet.',
      tag: 'KARAR DESTEĞİ',
    ),
    _Slide(
      emoji: '☕',
      title: 'Katkı Sağla, Puan Kazan',
      body:
          'Markette gördüğün fiyatı saniyeler içinde paylaş. Topluluk güçlenir, sen puan kazanırsın.',
      tag: 'TOPLULUK KATKISI',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: CoffeeColors.espresso,
      body: SafeArea(
        child: Column(
          children: [
            // Skip row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo mark
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: CoffeeColors.caramel,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text('☕',
                            style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'FiyatRadar',
                        style: TextStyle(
                          color: CoffeeColors.cream,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  // Skip
                  GestureDetector(
                    onTap: _finish,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.12)),
                      ),
                      child: const Text(
                        'Geç',
                        style: TextStyle(
                          color: CoffeeColors.latte,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) =>
                    _SlideView(slide: _slides[i]),
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: Column(
                children: [
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? CoffeeColors.caramel
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLast) {
                          _finish();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CoffeeColors.caramel,
                        foregroundColor: CoffeeColors.espresso,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isLast ? 'Başla →' : 'Devam',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
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

class _Slide {
  final String emoji;
  final String title;
  final String body;
  final String tag;
  const _Slide({
    required this.emoji,
    required this.title,
    required this.body,
    required this.tag,
  });
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration area
          Expanded(
            flex: 5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: CoffeeColors.darkRoast,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: CoffeeColors.caramel.withOpacity(0.15),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(slide.emoji,
                        style: const TextStyle(fontSize: 64)),
                  ),
                  const SizedBox(height: 24),
                  // Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: CoffeeColors.caramel.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: CoffeeColors.caramel.withOpacity(0.32)),
                    ),
                    child: Text(
                      slide.tag,
                      style: const TextStyle(
                        color: CoffeeColors.caramel,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Text area
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slide.title,
                  style: const TextStyle(
                    color: CoffeeColors.cream,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  slide.body,
                  style: const TextStyle(
                    color: CoffeeColors.latte,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
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
