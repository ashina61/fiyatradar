import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      title: 'Mahallendeki fırsatları keşfet',
      description:
          'Yakındaki marketlerde fiyatları canlı takip et, her alışverişte en avantajlı rotayı seç.',
      icon: Icons.explore_rounded,
      stats: '150K+ doğrulanmış fiyat',
      highlights: ['Canlı market karşılaştırması', 'Konuma göre öneriler'],
      accent: AppColors.primary,
      glow: Color(0xFFD4874A),
    ),
    _OnboardingPageData(
      title: 'Topluluk gücüyle güvenli veri',
      description:
          'Doğrulanan fiyatlara katkı ver, güven puanı yükselt ve premium deneyimi açan ödüller kazan.',
      icon: Icons.verified_user_rounded,
      stats: '%98 güvenilirlik skoru',
      highlights: ['Topluluk onay sistemi', 'Akıllı güven puanı'],
      accent: AppColors.accent,
      glow: Color(0xFFE8C9A8),
    ),
    _OnboardingPageData(
      title: 'Sepeti tek dokunuşla optimize et',
      description:
          'Ürün listeni ekle, marketleri otomatik kıyasla ve toplam maliyeti tek ekranda düşür.',
      icon: Icons.shopping_bag_rounded,
      stats: 'Aylık ort. %23 tasarruf',
      highlights: ['Akıllı sepet kıyaslama', 'Anlık tasarruf analizi'],
      accent: AppColors.secondaryDark,
      glow: Color(0xFFF5EDE6),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFAF6F3), Color(0xFFF5EDE6), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _GlowOrb(color: page.glow, size: 260),
            ),
            Positioned(
              bottom: 120,
              left: -120,
              child: _GlowOrb(color: page.accent.withOpacity(0.16), size: 320),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.outlineVariant,
                            ),
                          ),
                          child: const Text(
                            'FiyatRadar',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _currentPage == _pages.length - 1
                              ? null
                              : _completeOnboarding,
                          child: const Text('Geç'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (value) => setState(() => _currentPage = value),
                      itemBuilder: (context, index) => _OnboardingPage(data: _pages[index]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: _currentPage == index ? 34 : 10,
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                gradient: _currentPage == index
                                    ? AppColors.gradientWarm
                                    : null,
                                color: _currentPage == index
                                    ? null
                                    : AppColors.outlineVariant,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _nextPage,
                            icon: Icon(
                              _currentPage == _pages.length - 1
                                  ? Icons.auto_awesome_rounded
                                  : Icons.arrow_forward_rounded,
                            ),
                            label: Text(
                              _currentPage == _pages.length - 1
                                  ? 'Premium Deneyime Başla'
                                  : 'Devam Et',
                            ),
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
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.stats,
    required this.highlights,
    required this.accent,
    required this.glow,
  });

  final String title;
  final String description;
  final IconData icon;
  final String stats;
  final List<String> highlights;
  final Color accent;
  final Color glow;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.95),
                  data.glow.withOpacity(0.28),
                ],
              ),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.7)),
              boxShadow: [
                BoxShadow(
                  color: data.accent.withOpacity(0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [data.accent, data.glow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 40),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.78),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    data.stats,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...data.highlights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: data.accent),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0.08),
              Colors.transparent,
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}
