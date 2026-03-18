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

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;

  static const _steps = [
    (
      title: 'Market Rafları Cebinde',
      subtitle:
          'Fiyatları akılda tutma devri bitti. Etrafındaki tüm güncel fiyatları tek ekranda gör, alışverişini akıllıca planla.',
      badge: 'Güncel Fiyatlar',
      icon: Icons.track_changes_rounded,
      badgeBg: authEspresso,
      badgeFg: Colors.white,
    ),
    (
      title: 'Birlikte Daha Güçlüyüz',
      subtitle:
          'Gördüğün güncel fiyatları paylaşarak ağımıza katıl. Kullanıcıların desteğiyle büyüyen bu sistemde, herkes için en şeffaf fiyat haritasını oluşturalım.',
      badge: 'Görevleri Tamamla',
      icon: Icons.groups_rounded,
      badgeBg: authCamel,
      badgeFg: authEspresso,
    ),
    (
      title: 'Bütçenin Kontrolü Sende',
      subtitle:
          'İhtiyaç listeni gir, FiyatRadar senin için en uygun market kombinasyonunu bulsun. Hem zamanını hem paranı koru.',
      badge: 'En Uygun Sepet',
      icon: Icons.account_balance_wallet_rounded,
      badgeBg: Colors.white,
      badgeFg: authEspresso,
    ),
  ];

  Future<void> _goLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_currentStep == _steps.length - 1) {
      _goLogin();
      return;
    }
    setState(() => _currentStep += 1);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    return AuthSurface(
      child: Column(
        children: [
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.radar_rounded, color: authCamel, size: 24),
                  const SizedBox(width: 6),
                  Text('FiyatRadar', style: authText(size: 16, weight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
              const Spacer(),
              TextButton(onPressed: _goLogin, child: Text('Atla', style: authText(size: 14, weight: FontWeight.w700, color: authMuted))),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(position: Tween(begin: const Offset(.06, 0), end: Offset.zero).animate(anim), child: child),
              ),
              child: _OnboardingStepCard(
                key: ValueKey(_currentStep),
                title: step.title,
                subtitle: step.subtitle,
                badge: step.badge,
                icon: step.icon,
                badgeBg: step.badgeBg,
                badgeFg: step.badgeFg,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (i) {
              final active = i == _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? authCamel : authEspresso.withOpacity(.1),
                  borderRadius: BorderRadius.circular(100),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          MassivePrimaryButton(label: _currentStep == _steps.length - 1 ? 'Sisteme Bağlan' : 'Devam Et', onPressed: _next),
        ],
      ),
    );
  }
}

class _OnboardingStepCard extends StatelessWidget {
  const _OnboardingStepCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.badgeBg,
    required this.badgeFg,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color badgeBg;
  final Color badgeFg;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cardHeight = (size.height * 0.42).clamp(260.0, 320.0);
    final pillarHeight = (cardHeight * 0.81).clamp(210.0, 260.0);
    final pillarWidth = (size.width * 0.29).clamp(96.0, 110.0);
    return Column(
      children: [
        Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: cardHeight),
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .12), blurRadius: 40, offset: Offset(0, 20))],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: pillarWidth,
                height: pillarHeight,
                decoration: BoxDecoration(
                  color: authWhite,
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(color: Colors.white.withOpacity(.8)),
                  boxShadow: const [
                    BoxShadow(color: FRColors.white, blurRadius: 16, offset: Offset(-8, -8)),
                    BoxShadow(color: Color.fromRGBO(28, 17, 8, .05), blurRadius: 24, offset: Offset(8, 8)),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: authWhite,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color.fromRGBO(28, 17, 8, .08), blurRadius: 16, offset: Offset(6, 6)),
                        BoxShadow(color: FRColors.white, blurRadius: 10, offset: Offset(-4, -4)),
                      ],
                    ),
                    child: Icon(icon, size: 36, color: authEspresso),
                  ),
                ),
              ),
              Positioned(
                bottom: -16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(100),
                    border: const Border.fromBorderSide(BorderSide(color: authBg, width: 2)),
                    boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .2), blurRadius: 20, offset: Offset(0, 8))],
                  ),
                  child: Text(badge, style: authText(size: 12, weight: FontWeight.w800, color: badgeFg)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Text(title, textAlign: TextAlign.center, style: authText(size: 28, weight: FontWeight.w900, letterSpacing: -1, height: 1.15)),
        const SizedBox(height: 12),
        Text(subtitle, textAlign: TextAlign.center, style: authText(size: 14, weight: FontWeight.w500, color: authMuted, height: 1.5)),
      ],
    );
  }
}
