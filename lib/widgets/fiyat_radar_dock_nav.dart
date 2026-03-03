import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// FiyatRadar için CodePen tarzı dinamik dock bottom navigation.
///
/// - 5 slot düzeni: Home, Explore, Center Action, Cart, Profile
/// - Aktif tab "hap" gibi genişler (ikon + label)
/// - Pasif tab sadece ikon gösterir
/// - Ortadaki aksiyon butonu dock'un üstüne taşar
class FiyatRadarDockNav extends StatelessWidget {
  const FiyatRadarDockNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  static const Duration _kDuration = Duration(milliseconds: 400);
  static const Curve _kCurve = Curves.easeOutBack;

  // Tasarım renkleri (ileride token sistemine bağlanabilir).
  static const Color _kActiveColor = Color(0xFF6B4226);
  static const Color _kInactiveColor = Color(0xFFA38671);
  static const Color _kActiveBackground = Color(0x1A6B4226); // rgba(107,66,38,0.10)

  static const List<_DockTabData> _tabs = <_DockTabData>[
    _DockTabData(index: 0, label: 'Home', icon: Icons.home_rounded),
    _DockTabData(index: 1, label: 'Explore', icon: Icons.explore_rounded),
    _DockTabData(index: 3, label: 'Cart', icon: Icons.shopping_cart_rounded),
    _DockTabData(index: 4, label: 'Profile', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 112 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + bottomInset,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                  bottom: Radius.circular(24),
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  for (final _DockTabData tab in _tabs.take(2))
                    Expanded(
                      child: _DockTab(
                        duration: _kDuration,
                        curve: _kCurve,
                        icon: tab.icon,
                        label: tab.label,
                        selected: currentIndex == tab.index,
                        activeColor: _kActiveColor,
                        inactiveColor: _kInactiveColor,
                        activeBackground: _kActiveBackground,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onTap(tab.index);
                        },
                      ),
                    ),
                  const SizedBox(width: 64),
                  for (final _DockTabData tab in _tabs.skip(2))
                    Expanded(
                      child: _DockTab(
                        duration: _kDuration,
                        curve: _kCurve,
                        icon: tab.icon,
                        label: tab.label,
                        selected: currentIndex == tab.index,
                        activeColor: _kActiveColor,
                        inactiveColor: _kInactiveColor,
                        activeBackground: _kActiveBackground,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onTap(tab.index);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            // Dock yüzeyinin üstüne taşan merkez buton.
            bottom: 24 + bottomInset + 62,
            child: _CenterActionButton(onTap: onCenterTap),
          ),
        ],
      ),
    );
  }
}

class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.duration,
    required this.curve,
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.activeBackground,
    required this.onTap,
  });

  final Duration duration;
  final Curve curve;
  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: duration,
              curve: curve,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? activeBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedSize(
                duration: duration,
                curve: curve,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      icon,
                      size: 26,
                      color: selected ? activeColor : inactiveColor,
                    ),
                    AnimatedContainer(
                      duration: duration,
                      curve: curve,
                      margin: EdgeInsets.only(left: selected ? 8 : 0),
                      constraints: BoxConstraints(maxWidth: selected ? 110 : 0),
                      child: AnimatedOpacity(
                        duration: duration,
                        curve: curve,
                        opacity: selected ? 1 : 0,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: activeColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterActionButton extends StatefulWidget {
  const _CenterActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CenterActionButton> createState() => _CenterActionButtonState();
}

class _CenterActionButtonState extends State<_CenterActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow> shadows = _pressed
        ? const <BoxShadow>[
            BoxShadow(
              color: Color(0x266B4226),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ]
        : const <BoxShadow>[
            BoxShadow(
              color: Color(0x406B4226),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _pressed ? 0.92 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF8C5938), Color(0xFF4A2E1B)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: shadows,
          ),
          child: Transform.rotate(
            angle: 45 * (3.1415926535897932 / 180),
            child: Center(
              child: Transform.rotate(
                angle: -45 * (3.1415926535897932 / 180),
                child: const Icon(
                  Icons.add_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockTabData {
  const _DockTabData({
    required this.index,
    required this.label,
    required this.icon,
  });

  final int index;
  final String label;
  final IconData icon;
}

/// Demo kullanım örneği.
///
/// Bu widget, dock'u sayfa altına `Stack` ile yerleştirir ve SafeArea alt boşluğunu
/// dock içerisinde hesaba katar.
class FiyatRadarDockNavDemoPage extends StatefulWidget {
  const FiyatRadarDockNavDemoPage({super.key});

  @override
  State<FiyatRadarDockNavDemoPage> createState() => _FiyatRadarDockNavDemoPageState();
}

class _FiyatRadarDockNavDemoPageState extends State<FiyatRadarDockNavDemoPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2ED),
      body: Stack(
        children: <Widget>[
          Center(
            child: Text(
              'Active index: $_currentIndex',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FiyatRadarDockNav(
              currentIndex: _currentIndex,
              onTap: (int index) => setState(() => _currentIndex = index),
              onCenterTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Center action tapped')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
