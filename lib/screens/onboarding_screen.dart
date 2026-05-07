import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firebase_service.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
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

  static const _slides = <_Slide>[
    _Slide(
      icon: Icons.radar_rounded,
      overline: 'RADAR',
      title: 'Markette gördüğünü\nradarına al.',
      body:
          'FiyatRadar topluluğuyla zincir ve yerel marketlerin gerçek fiyatlarını anbean takip et.',
      stat: 'Kadıköy · son 24 saatte 3.4K yeni fiyat',
    ),
    _Slide(
      icon: Icons.compare_arrows_rounded,
      overline: 'KARŞILAŞTIR',
      title: 'Aynı ürün,\n5 farklı fiyat.',
      body:
          'Sepetini oluştur, hangi marketin hangi kombinasyonda daha ucuz olduğunu anında gör.',
      stat: 'Ortalama %14 tasarruf tespit edildi',
    ),
    _Slide(
      icon: Icons.notifications_active_rounded,
      overline: 'ALARM',
      title: 'Fiyat düşünce\nhaber al.',
      body:
          'Hedef fiyatı belirle. Ürün o fiyata indiğinde FiyatRadar seni uyansın.',
      stat: 'Her onaylı fiyat katkısı +10 puan',
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
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Row(
                children: [
                  SizedBox(
                    height: 40,
                    child: Image.asset(
                      'assets/images/fiyatradar_logo.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _finish,
                    borderRadius: FRRad.all(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: FR.surface,
                        borderRadius: FRRad.all(999),
                        border: Border.all(color: FR.hairline),
                      ),
                      child: Text('Geç', style: frText(12, FontWeight.w800, color: FR.ink2)),
                    ),
                  ),
                ],
              ),
            ),
            // Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Row(
                children: List.generate(_slides.length, (i) {
                  final active = i == _page;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      height: 3,
                      margin: EdgeInsets.only(right: i < _slides.length - 1 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: active ? FR.gold : FR.hairline,
                        borderRadius: FRRad.all(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
              child: FRCta(
                label: isLast ? 'Başla' : 'Devam',
                icon: isLast ? Icons.arrow_forward_rounded : null,
                onTap: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String overline;
  final String title;
  final String body;
  final String stat;
  const _Slide({
    required this.icon,
    required this.overline,
    required this.title,
    required this.body,
    required this.stat,
  });
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          Expanded(
            flex: 5,
            child: Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [FR.surface, FR.surfaceLo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: FRRad.all(44),
                  border: Border.all(color: FR.goldDeep.withOpacity(.3)),
                  boxShadow: [
                    BoxShadow(color: FR.gold.withOpacity(.14), blurRadius: 42, spreadRadius: 6),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(slide.icon, size: 64, color: FR.gold),
              ),
            ),
          ),
          // Text area
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slide.overline, style: frOverline()),
                const SizedBox(height: 10),
                Text(slide.title, style: frDisplay(32, FontWeight.w700, height: 1.15)),
                const SizedBox(height: 14),
                Text(
                  slide.body,
                  style: frText(14.5, FontWeight.w500, color: FR.ink2, height: 1.55),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: FR.surface,
                    borderRadius: FRRad.all(12),
                    border: Border.all(color: FR.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FRLiveDot(color: FR.gold),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          slide.stat,
                          style: frText(12, FontWeight.w700, color: FR.ink2),
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
