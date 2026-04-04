import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/fr_colors.dart';
import '../auth/widgets/auth_portal_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _masterController;
  int _currentStep = 0;

  static const _steps = [
    (
      title: 'Market Rafları Cebinde',
      subtitle:
          'Canlı fiyat akışını premium radar ekranında izle, çevrendeki fırsatları saniyeler içinde yakala ve alışveriş kararını güvenle ver.',
      badge: 'Güncel Fiyatlar',
      type: _ShowcaseType.radar,
    ),
    (
      title: 'Topluluk Gücüyle Büyü',
      subtitle:
          'Görevleri tamamla, fiyat ağını besle ve topluluğun merkezine akan verilerle FiyatRadar deneyimini birlikte güçlendirin.',
      badge: 'Görevleri Tamamla',
      type: _ShowcaseType.community,
    ),
    (
      title: 'Sepetini Akıllıca Kur',
      subtitle:
          'Lüks sepet görünümüyle en doğru market kombinasyonunu keşfet; düşen fırsatları yakala, toplam harcamayı minimumda tut.',
      badge: 'En Uygun Sepet',
      type: _ShowcaseType.basket,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _masterController.dispose();
    super.dispose();
  }

  Future<void> _goLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _next() async {
    if (_currentStep == _steps.length - 1) {
      await _goLogin();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthSurface(
      child: Column(
        children: [
          Row(
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 26,
                      height: 26,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'FiyatRadar',
                    style: authText(
                      size: 16,
                      weight: FontWeight.w900,
                      color: FRColors.espresso,
                      letterSpacing: -.4,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: _goLogin,
                child: Text(
                  'Atla',
                  style: authText(
                    size: 14,
                    weight: FontWeight.w800,
                    color: FRColors.espresso.withOpacity(.62),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _steps.length,
              onPageChanged: (index) => setState(() => _currentStep = index),
              itemBuilder: (context, index) {
                final step = _steps[index];
                return AnimatedBuilder(
                  animation: _masterController,
                  builder: (context, _) {
                    return _OnboardingStepCard(
                      title: step.title,
                      subtitle: step.subtitle,
                      badge: step.badge,
                      type: step.type,
                      progress: _masterController.value,
                      isActive: index == _currentStep,
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (i) {
              final active = i == _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? FRColors.espresso : FRColors.espresso.withOpacity(.14),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          MassivePrimaryButton(
            label: _currentStep == _steps.length - 1
                ? 'Sisteme Bağlan'
                : 'Devam Et',
            onPressed: _next,
          ),
        ],
      ),
    );
  }
}

enum _ShowcaseType { radar, community, basket }

class _OnboardingStepCard extends StatelessWidget {
  const _OnboardingStepCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.type,
    required this.progress,
    required this.isActive,
  });

  final String title;
  final String subtitle;
  final String badge;
  final _ShowcaseType type;
  final double progress;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cardHeight = math.min(size.height * .46, 410.0);

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: const LinearGradient(
              colors: [Color(0xFF040404), Color(0xFF121212), Color(0xFF1C1C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: FRColors.goldGlowSoft.withOpacity(.72), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.20),
                blurRadius: 34,
                offset: const Offset(0, 22),
              ),
              BoxShadow(
                color: FRColors.goldGlowSoft.withOpacity(.08),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 42),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: FRColors.goldGlowSoft.withOpacity(.12),
                      ),
                    ),
                    child: _ShowcaseAnimation(type: type, progress: progress, isActive: isActive),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE39B), Color(0xFFD3A63D)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: FRColors.goldGlowSoft.withOpacity(.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      badge,
                      style: authText(
                        size: 12,
                        weight: FontWeight.w900,
                        color: FRColors.espresso,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 38),
        Text(
          title,
          textAlign: TextAlign.center,
          style: authText(
            size: 30,
            weight: FontWeight.w900,
            color: FRColors.espresso,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: authText(
              size: 14,
              weight: FontWeight.w600,
              color: FRColors.espresso.withOpacity(.72),
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShowcaseAnimation extends StatelessWidget {
  const _ShowcaseAnimation({
    required this.type,
    required this.progress,
    required this.isActive,
  });

  final _ShowcaseType type;
  final double progress;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final effectiveProgress = isActive ? progress : 0.0;
    switch (type) {
      case _ShowcaseType.radar:
        return _RadarShowcase(progress: effectiveProgress);
      case _ShowcaseType.community:
        return _CommunityShowcase(progress: effectiveProgress);
      case _ShowcaseType.basket:
        return _BasketShowcase(progress: effectiveProgress);
    }
  }
}

class _RadarShowcase extends StatelessWidget {
  const _RadarShowcase({required this.progress});

  final double progress;

  static const _labels = [
    ('34.90 ₺', Alignment(-.72, -.48)),
    ('12.50 ₺', Alignment(.70, -.22)),
    ('89.99 ₺', Alignment(.08, -.72)),
    ('22.75 ₺', Alignment(-.18, .58)),
    ('49.95 ₺', Alignment(.58, .52)),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = math.min(constraints.maxWidth, constraints.maxHeight);
        final centerSize = shortest * .26;
        return Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              _buildRadarWave(shortest, i),
            Transform.rotate(
              angle: progress * math.pi * 2,
              child: Container(
                width: shortest * .78,
                height: shortest * .78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      FRColors.goldGlowSoft.withOpacity(.06),
                      FRColors.goldGlowSoft.withOpacity(.38),
                      Colors.transparent,
                    ],
                    stops: const [0, .75, .88, 1],
                  ),
                ),
              ),
            ),
            Container(
              width: shortest * .74,
              height: shortest * .74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: FRColors.goldGlowSoft.withOpacity(.10)),
              ),
            ),
            Container(
              width: shortest * .48,
              height: shortest * .48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: FRColors.goldGlowSoft.withOpacity(.14)),
              ),
            ),
            Container(
              width: centerSize,
              height: centerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    FRColors.goldGlowSoft.withOpacity(.95),
                    FRColors.goldGlowSoft.withOpacity(.25),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: FRColors.goldGlowSoft.withOpacity(.20),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(Icons.radar_rounded, color: Color(0xFF2A1B03), size: 34),
            ),
            for (var i = 0; i < _labels.length; i++) _buildPriceTag(_labels[i].$1, _labels[i].$2, i),
          ],
        );
      },
    );
  }

  Widget _buildRadarWave(double shortest, int index) {
    final phase = ((progress + index * .28) % 1);
    final scale = .32 + (phase * .92);
    final opacity = (1 - phase).clamp(0.0, 1.0) * .34;
    return Container(
      width: shortest * scale,
      height: shortest * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: FRColors.goldGlowSoft.withOpacity(opacity), width: 1.4),
      ),
    );
  }

  Widget _buildPriceTag(String text, Alignment alignment, int index) {
    final phase = ((progress * 1.35) + index * .22) % 1;
    final visible = math.sin(phase * math.pi);
    return Align(
      alignment: alignment,
      child: Opacity(
        opacity: visible.clamp(0.0, 1.0) * .95,
        child: Transform.translate(
          offset: Offset(0, (1 - visible) * 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1208).withOpacity(.90),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: FRColors.goldGlowSoft.withOpacity(.40)),
            ),
            child: Text(
              text,
              style: authText(
                size: 11,
                weight: FontWeight.w800,
                color: FRColors.goldGlowSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityShowcase extends StatelessWidget {
  const _CommunityShowcase({required this.progress});

  final double progress;

  static const _nodes = [
    Alignment(0, -.72),
    Alignment(.72, -.16),
    Alignment(.52, .60),
    Alignment(-.52, .60),
    Alignment(-.76, -.12),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final center = Offset(width / 2, height / 2);
        final points = _nodes
            .map((alignment) => Offset(
                  center.dx + alignment.x * width * .34,
                  center.dy + alignment.y * height * .34,
                ))
            .toList();

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _NetworkRoutesPainter(points: points, center: center, progress: progress),
              ),
            ),
            for (var i = 0; i < points.length; i++)
              Positioned(
                left: points[i].dx - 18,
                top: points[i].dy - 18,
                child: _BlinkingNode(delay: i * .16, progress: progress),
              ),
            Center(
              child: Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      FRColors.goldGlowSoft.withOpacity(.92),
                      FRColors.gold.withOpacity(.72),
                      const Color(0xFF7F5A15),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: FRColors.goldGlowSoft.withOpacity(.24),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.groups_rounded, size: 44, color: Color(0xFF271807)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BlinkingNode extends StatelessWidget {
  const _BlinkingNode({required this.delay, required this.progress});

  final double delay;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final pulse = (math.sin((progress + delay) * math.pi * 2) + 1) / 2;
    final scale = .84 + (pulse * .28);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: FRColors.goldGlowSoft.withOpacity(.16 + pulse * .18),
          border: Border.all(color: FRColors.goldGlowSoft.withOpacity(.64)),
          boxShadow: [
            BoxShadow(
              color: FRColors.goldGlowSoft.withOpacity(.16 + pulse * .10),
              blurRadius: 12,
            ),
          ],
        ),
        child: const Icon(Icons.person_rounded, size: 18, color: FRColors.goldGlowSoft),
      ),
    );
  }
}

class _NetworkRoutesPainter extends CustomPainter {
  const _NetworkRoutesPainter({
    required this.points,
    required this.center,
    required this.progress,
  });

  final List<Offset> points;
  final Offset center;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final dashed = Paint()
      ..color = FRColors.goldGlowSoft.withOpacity(.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final pulse = Paint()
      ..color = FRColors.goldGlowSoft.withOpacity(.75)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    for (var i = 0; i < points.length; i++) {
      final node = points[i];
      _drawDashedLine(canvas, center, node, dashed);

      final segmentProgress = ((progress + i * .18) % 1);
      final start = Offset.lerp(node, center, segmentProgress.clamp(0.0, .92))!;
      final end = Offset.lerp(node, center, (segmentProgress + .18).clamp(0.0, 1.0))!;
      canvas.drawLine(start, end, pulse);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 7.0;
    const gap = 6.0;
    final vector = end - start;
    final distance = vector.distance;
    final direction = vector / distance;
    double drawn = 0;
    while (drawn < distance) {
      final from = start + direction * drawn;
      final to = start + direction * math.min(drawn + dash, distance);
      canvas.drawLine(from, to, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkRoutesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.points != points;
  }
}

class _BasketShowcase extends StatelessWidget {
  const _BasketShowcase({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final pulse = (math.sin(progress * math.pi * 2) + 1) / 2;
    final basketScale = .96 + (pulse * .07);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final iconConfigs = [
          (Icons.inventory_2_rounded, width * .28, 0.00, 0.00),
          (Icons.sell_rounded, width * .50, .22, .12),
          (Icons.local_offer_rounded, width * .72, .44, -.08),
        ];

        return Stack(
          alignment: Alignment.center,
          children: [
            for (final config in iconConfigs)
              _FallingGoldIcon(
                icon: config.$1,
                left: config.$2,
                progress: ((progress + config.$3) % 1),
                swayOffset: config.$4,
                canvasHeight: height,
              ),
            Transform.scale(
              scale: basketScale,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      FRColors.goldGlowSoft.withOpacity(.96),
                      FRColors.gold.withOpacity(.78),
                      const Color(0xFF704A11),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: FRColors.goldGlowSoft.withOpacity(.24 + pulse * .10),
                      blurRadius: 26,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_basket_rounded,
                  size: 54,
                  color: Color(0xFF281A08),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FallingGoldIcon extends StatelessWidget {
  const _FallingGoldIcon({
    required this.icon,
    required this.left,
    required this.progress,
    required this.swayOffset,
    required this.canvasHeight,
  });

  final IconData icon;
  final double left;
  final double progress;
  final double swayOffset;
  final double canvasHeight;

  @override
  Widget build(BuildContext context) {
    final top = (progress * canvasHeight * .88) - 18;
    final fade = (1 - (progress - .78).clamp(0.0, 1.0) / .22).clamp(0.0, 1.0);
    final xShift = math.sin((progress * math.pi * 2) + swayOffset) * 10;
    return Positioned(
      left: left + xShift - 16,
      top: top,
      child: Opacity(
        opacity: fade,
        child: Transform.rotate(
          angle: (progress - .5) * .35,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: FRColors.goldGlowSoft.withOpacity(.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FRColors.goldGlowSoft.withOpacity(.58)),
            ),
            child: Icon(icon, size: 17, color: FRColors.goldGlowSoft),
          ),
        ),
      ),
    );
  }
}
