import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firebase_service.dart';
import '../theme.dart';
import '../widgets/design.dart';
import 'login_screen.dart';
import 'main_screen.dart';

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
      emoji: '🔎',
      title: 'Ürün Ara, Net Gör',
      body: 'Keşfet’te ürünü bul, marketlerdeki güncel fiyatı tek bakışta gör.',
      tag: 'HIZLI KEŞİF',
      highlight: 'Arama + filtre ile hızlı karar.',
    ),
    _Slide(
      emoji: '⚖️',
      title: 'Karşılaştır ve Karar Ver',
      body: 'Sepetine ekle, en iyi marketi veya karma kombinasyonu anında karşılaştır.',
      tag: 'KARAR DESTEĞİ',
      highlight: 'Daha iyi fiyatı kaçırma.',
    ),
    _Slide(
      emoji: '📈',
      title: 'Katkı Yap, Alarm Kur',
      body: 'Fiyat ekleyip topluluğu güçlendir, alarm kurup hedef fiyatı takip et.',
      tag: 'AKILLI TAKİP',
      highlight: 'Daha iyi alışveriş kararı ver.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    final user = FirebaseService.instance.auth.currentUser;
    final goMain = user != null && !user.isAnonymous;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => goMain ? const MainScreen() : const LoginScreen(),
      ),
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
            // ── Top bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: CoffeeColors.caramel,
                          borderRadius: BorderRadius.circular(11),
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
                  // Skip button
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

            // ── Slide counter ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Row(
                children: List.generate(_slides.length, (i) {
                  final isActive = i == _page;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 3,
                      margin: EdgeInsets.only(right: i < _slides.length - 1 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: isActive
                            ? CoffeeColors.caramel
                            : Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Slides ────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) =>
                    _SlideView(slide: _slides[i]),
              ),
            ),

            // ── Bottom CTA ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 320),
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
  final String highlight;
  const _Slide({
    required this.emoji,
    required this.title,
    required this.body,
    required this.tag,
    required this.highlight,
  });
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          Expanded(
            flex: 5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      color: CoffeeColors.darkRoast,
                      borderRadius: BorderRadius.circular(42),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: CoffeeColors.caramel.withOpacity(0.18),
                          blurRadius: 48,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(slide.emoji,
                        style: const TextStyle(fontSize: 64)),
                  ),
                  const SizedBox(height: 22),
                  // Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: CoffeeColors.caramel.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              CoffeeColors.caramel.withOpacity(0.30)),
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
                const SizedBox(height: 12),
                Text(
                  slide.body,
                  style: const TextStyle(
                    color: CoffeeColors.latte,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                // Highlight stat
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LiveDot(color: CoffeeColors.caramel),
                      const SizedBox(width: 8),
                      Text(
                        slide.highlight,
                        style: const TextStyle(
                          color: CoffeeColors.caramel,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
