import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _pages = const [
    {
      'badge': 'Akıllı Takip',
      'title': 'Market Rafları Cebinde',
      'description':
          'Fiyatları akılda tutma devri bitti. Etrafındaki tüm güncel fiyatları tek ekranda gör, alışverişini akıllıca planla.',
      'icon': Icons.radar_rounded,
    },
    {
      'badge': 'Gücümüz Topluluk',
      'title': 'Birlikte Daha Güçlüyüz',
      'description':
          'Gördüğün güncel fiyatları paylaşarak ağımıza katıl. Kullanıcıların desteğiyle büyüyen bu sistemde, herkes için en şeffaf fiyat haritasını oluşturalım.',
      'icon': Icons.groups_rounded,
    },
    {
      'badge': 'Net Tasarruf',
      'title': 'Bütçenin Kontrolü Sende',
      'description':
          'İhtiyaç listeni gir, FiyatRadar senin için en uygun market kombinasyonunu bulsun. Hem zamanını hem paranı koru.',
      'icon': Icons.account_balance_wallet_rounded,
    },
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

  void _onNextPressed() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Row(
                children: [
                  Text(
                    'FiyatRadar',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: const Color(0xFF6B4226),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Atla',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFA38671),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 320),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF6F0),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(-12, -12),
                                  blurRadius: 24,
                                ),
                                BoxShadow(
                                  color: Color(0x1FA66632),
                                  offset: Offset(12, 12),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFFAF6F0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x26A66632),
                                            offset: Offset(8, 8),
                                            blurRadius: 16,
                                          ),
                                          BoxShadow(
                                            color: Color(0xFFFFFFFF),
                                            offset: Offset(-8, -8),
                                            blurRadius: 16,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        page['icon'] as IconData,
                                        size: 52,
                                        color: const Color(0xFF6B4226),
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  bottom: -15,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF6B4226),
                                          Color(0xFF4A2E1B),
                                        ],
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x4D6B4226),
                                          offset: Offset(0, 8),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      page['badge'] as String,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFFFFFFF),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              Text(
                                page['title'] as String,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF4A2E1B),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                page['description'] as String,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF8C6A53),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) {
                        final isActive = _currentIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF6B4226)
                                : const Color(0xFFEAD8C8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF8C5938), Color(0xFF4A2E1B)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x406B4226),
                            offset: Offset(0, 10),
                            blurRadius: 25,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0x00000000),
                          shadowColor: const Color(0x00000000),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          _currentIndex == _pages.length - 1
                              ? 'Uygulamaya Başla'
                              : 'Devam Et',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFFFFFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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
