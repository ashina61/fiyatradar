import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../add_price/add_price_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/login_screen.dart';
import '../cart/cart_screen.dart';
import '../notifications/notifications_screen.dart';
import '../search/search_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  double _scrollOffset = 0;
  int _avatarShineTick = 0;

  void _triggerAvatarShine() {
    setState(() => _avatarShineTick++);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userModelStreamProvider).valueOrNull;
    final trust = (user?.reliabilityScore ?? 72).clamp(0, 100).toDouble();
    final monthlySavings = ((user?.points ?? 0) * 3.4).toStringAsFixed(0);
    final streak = ((user?.validations ?? 0) ~/ 2).clamp(0, 365);
    final topMarket = (user?.validations ?? 0) > 20 ? 'Migros' : 'A101';

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            setState(() => _scrollOffset = notification.metrics.pixels.clamp(0, 220));
          }
          return false;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 92,
              title: const Text('Profil'),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  RepaintBoundary(
                    child: _UltraHeroCard(
                      user: user,
                      trust: trust,
                      monthlySavings: monthlySavings,
                      topMarket: topMarket,
                      streak: streak,
                      scrollOffset: _scrollOffset,
                      avatarShineTick: _avatarShineTick,
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _QuickActions(
                    onMyPrices: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddPriceScreen()),
                    ),
                    onReceipts: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreenV2()),
                    ),
                    onFavorites: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    onNotifications: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LiveActivity(user: user),
                  const SizedBox(height: 16),
                  _BadgeCinema(
                    user: user,
                    onBadgeCelebrate: _triggerAvatarShine,
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(user: user),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UltraHeroCard extends StatefulWidget {
  const _UltraHeroCard({
    required this.user,
    required this.trust,
    required this.monthlySavings,
    required this.topMarket,
    required this.streak,
    required this.scrollOffset,
    required this.avatarShineTick,
    required this.onEdit,
  });

  final UserModel? user;
  final double trust;
  final String monthlySavings;
  final String topMarket;
  final int streak;
  final double scrollOffset;
  final int avatarShineTick;
  final VoidCallback onEdit;

  @override
  State<_UltraHeroCard> createState() => _UltraHeroCardState();
}

class _UltraHeroCardState extends State<_UltraHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..forward();

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user?.name.isNotEmpty == true ? widget.user!.name : 'FiyatRadar Üyesi';
    final trustTag = widget.trust >= 80 ? 'Elite Katkıcı' : 'Güven Ustası';
    final parallaxSlow = -widget.scrollOffset * 0.16;
    final parallaxMedium = -widget.scrollOffset * 0.24;

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final tilt = (1 - _entryController.value) * 0.06 + (widget.scrollOffset / 2200);
        return Transform.rotate(
          angle: -tilt * 0.35,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF4D6), Color(0xFFD9B26A), Color(0xFFB98A3F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC39243).withOpacity(0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.32)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(0, parallaxSlow),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.35),
                              const Color(0xFFD4A756).withOpacity(0.15),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, parallaxMedium),
                    child: IgnorePointer(
                      child: _BokehLayer(scrollOffset: widget.scrollOffset),
                    ),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _TiltGlowAvatar(
                                imageUrl: widget.user?.photoUrl,
                                initials: _initials(widget.user?.name),
                                scrollOffset: widget.scrollOffset,
                                shineTick: widget.avatarShineTick,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF3A2500),
                                          ),
                                    ),
                                    const SizedBox(height: 5),
                                    _MiniTag(label: trustTag),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Profili Düzenle',
                                onPressed: widget.onEdit,
                                icon: const Icon(Icons.edit_outlined),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.45),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Güven Skoru', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: widget.trust / 100),
                                  duration: const Duration(milliseconds: 1200),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, _) => ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      minHeight: 11,
                                      value: value,
                                      backgroundColor: Colors.white.withOpacity(0.4),
                                      valueColor: const AlwaysStoppedAnimation(Color(0xFF6A470A)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('%${widget.trust.toStringAsFixed(0)}'),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _GlowStatChip(label: 'Aylık Tasarruf: ₺${widget.monthlySavings}'),
                              _GlowStatChip(label: 'En iyi market: ${widget.topMarket}'),
                              _GlowStatChip(label: 'Seri: ${widget.streak} gün'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _initials(String? value) {
    if (value == null || value.trim().isEmpty) return 'FR';
    final parts = value.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _BokehLayer extends StatelessWidget {
  const _BokehLayer({required this.scrollOffset});

  final double scrollOffset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _dot(16, 16, 72, 0.12),
        _dot(220 + scrollOffset * 0.05, 34, 36, 0.2),
        _dot(150, 130 + scrollOffset * 0.04, 22, 0.2),
        _dot(265, 160 + scrollOffset * 0.06, 18, 0.18),
      ],
    );
  }

  Widget _dot(double left, double top, double size, double opacity) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      ),
    );
  }
}

class _TiltGlowAvatar extends StatefulWidget {
  const _TiltGlowAvatar({
    required this.imageUrl,
    required this.initials,
    required this.scrollOffset,
    required this.shineTick,
  });

  final String? imageUrl;
  final String initials;
  final double scrollOffset;
  final int shineTick;

  @override
  State<_TiltGlowAvatar> createState() => _TiltGlowAvatarState();
}

class _TiltGlowAvatarState extends State<_TiltGlowAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiltX = (widget.scrollOffset / 850).clamp(0.0, 0.06);
    final tiltY = -(widget.scrollOffset / 1400).clamp(0.0, 0.05);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glow = 16 + (10 * _pulseController.value);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(tiltX)
            ..rotateY(tiltY),
          child: Stack(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFCC6B).withOpacity(0.55),
                      blurRadius: glow,
                      spreadRadius: 1.2,
                    ),
                  ],
                ),
              ),
              ClipOval(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.75), width: 2.2),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                        Image.network(widget.imageUrl!, fit: BoxFit.cover)
                      else
                        Container(
                          color: const Color(0xFFAC7C33),
                          alignment: Alignment.center,
                          child: Text(
                            widget.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      _AvatarShineSweep(trigger: widget.shineTick),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarShineSweep extends StatefulWidget {
  const _AvatarShineSweep({required this.trigger});

  final int trigger;

  @override
  State<_AvatarShineSweep> createState() => _AvatarShineSweepState();
}

class _AvatarShineSweepState extends State<_AvatarShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didUpdateWidget(covariant _AvatarShineSweep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value == 0) return const SizedBox.shrink();
        return Transform.translate(
          offset: Offset(-70 + 140 * _controller.value, 0),
          child: Transform.rotate(
            angle: math.pi / 7,
            child: Container(
              width: 22,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.45),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _GlowStatChip extends StatelessWidget {
  const _GlowStatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF6D4D18).withOpacity(0.16),
        border: Border.all(color: Colors.white.withOpacity(0.38)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD083).withOpacity(0.28),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(label, style: const TextStyle(fontSize: 12.6)),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onMyPrices,
    required this.onReceipts,
    required this.onFavorites,
    required this.onNotifications,
  });

  final VoidCallback onMyPrices;
  final VoidCallback onReceipts;
  final VoidCallback onFavorites;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return _PremiumShell(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _AnimatedQuickButton(icon: Icons.price_change_outlined, label: 'Fiyatlarım', onTap: onMyPrices),
          _AnimatedQuickButton(icon: Icons.receipt_long_outlined, label: 'Fişlerim', onTap: onReceipts),
          _AnimatedQuickButton(icon: Icons.favorite_outline, label: 'Favoriler', onTap: onFavorites),
          _AnimatedQuickButton(icon: Icons.notifications_none, label: 'Bildirimler', onTap: onNotifications),
        ],
      ),
    );
  }
}

class _AnimatedQuickButton extends StatefulWidget {
  const _AnimatedQuickButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_AnimatedQuickButton> createState() => _AnimatedQuickButtonState();
}

class _AnimatedQuickButtonState extends State<_AnimatedQuickButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _pressed ? 0.94 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 21),
            const SizedBox(height: 5),
            Text(widget.label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _LiveActivity extends StatelessWidget {
  const _LiveActivity({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final empty = (user?.validations ?? 0) == 0 && (user?.priceEntries ?? 0) == 0;
    final items = const [
      (Icons.verified_rounded, 'Fiyat doğrulandı', 'Son kontrolünde bir ürün fiyatı doğruladın.'),
      (Icons.local_fire_department_rounded, 'Katkı kazanıldı', 'Topluluğa sağladığın katkı puanın arttı.'),
      (Icons.warning_amber_rounded, 'Rapor alındı', 'Bir fiyat bildirimin inceleme kuyruğuna eklendi.'),
    ];

    return _PremiumShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Son Aktiviteler', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (empty)
            const Text('Henüz aktivite yok. İlk katkını yaparak vitrini canlandır!')
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              return _ActivityRow(
                icon: item.$1,
                title: item.$2,
                subtitle: item.$3,
                delay: 80 * index,
                showDivider: index != items.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
    required this.showDivider,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int delay;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 480 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset((1 - value) * 20, 0),
        child: Opacity(opacity: value, child: child),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showDivider) Divider(color: Theme.of(context).dividerColor.withOpacity(0.35), height: 1),
        ],
      ),
    );
  }
}

class _BadgeCinema extends StatelessWidget {
  const _BadgeCinema({required this.user, required this.onBadgeCelebrate});

  final UserModel? user;
  final VoidCallback onBadgeCelebrate;

  @override
  Widget build(BuildContext context) {
    final validations = user?.validations ?? 0;
    final entries = user?.priceEntries ?? 0;

    final badges = [
      _BadgeData(
        icon: Icons.travel_explore_rounded,
        title: 'Fiyat Avcısı',
        description: 'Yeni fiyat eklemelerde hızın arttı.',
        unlocked: entries >= 1,
      ),
      _BadgeData(
        icon: Icons.fact_check_rounded,
        title: 'Doğrulama Ustası',
        description: 'Doğrulama oranını istikrarlı şekilde yükselttin.',
        unlocked: validations >= 5,
      ),
      _BadgeData(
        icon: Icons.verified_user_rounded,
        title: 'Güven Sütunu',
        description: 'Topluluk güven puanında öne çıktın.',
        unlocked: (user?.reliabilityScore ?? 0) >= 80,
      ),
      _BadgeData(
        icon: Icons.groups_rounded,
        title: 'Topluluk Kalbi',
        description: 'Katkılarınla topluluk etkileşimini büyüttün.',
        unlocked: (user?.points ?? 0) >= 50,
      ),
    ];

    return _PremiumShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rozet Sineması', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return _BadgeCard(
                badge: badge,
                onTap: () {
                  if (!badge.unlocked) return;
                  onBadgeCelebrate();
                  showUltraBadgeOverlay(
                    context,
                    badgeTitle: badge.title,
                    badgeDescription: badge.description,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          const Text('Yeni rozet kazandığında sinematik kutlama otomatik açılır.'),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.onTap});

  final _BadgeData badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: badge.unlocked ? 1 : 0.45,
      child: Material(
        color: badge.unlocked
            ? const Color(0xFFF3E3BF).withOpacity(0.65)
            : Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: badge.unlocked ? const Color(0xFFFFD07A) : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: badge.unlocked
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFCB76).withOpacity(0.34),
                        blurRadius: 12,
                        spreadRadius: 0.2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(badge.icon, size: 22),
                const Spacer(),
                Text(badge.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeData {
  const _BadgeData({
    required this.icon,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool unlocked;
}

Future<void> showUltraBadgeOverlay(
  BuildContext context, {
  required String badgeTitle,
  required String badgeDescription,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierLabel: 'rozet-kutlama',
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.62),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, __) => _UltraBadgeOverlay(
      badgeTitle: badgeTitle,
      badgeDescription: badgeDescription,
    ),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

class _UltraBadgeOverlay extends StatefulWidget {
  const _UltraBadgeOverlay({required this.badgeTitle, required this.badgeDescription});

  final String badgeTitle;
  final String badgeDescription;

  @override
  State<_UltraBadgeOverlay> createState() => _UltraBadgeOverlayState();
}

class _UltraBadgeOverlayState extends State<_UltraBadgeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: SafeArea(
        child: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
            child: Container(
              width: 310,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF0CB), Color(0xFFD39D44)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD37F).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (context, v, child) => Transform.scale(scale: v, child: child),
                    child: const Icon(Icons.emoji_events_rounded, size: 58),
                  ),
                  const SizedBox(height: 10),
                  const Text('🏆 Yeni Rozet Kazanıldı!', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('[${widget.badgeTitle}]', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    widget.badgeDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF4B3000)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return _PremiumShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ayarlar', style: Theme.of(context).textTheme.titleMedium),
          _PremiumTile(
            title: 'Profili Düzenle',
            icon: Icons.edit_outlined,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          _PremiumTile(
            title: 'Karanlık Mod',
            icon: Icons.dark_mode_outlined,
            trailing: Switch(
              value: mode == ThemeMode.dark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggleDarkMode(),
            ),
          ),
          _PremiumTile(
            title: 'Bildirim Ayarları',
            icon: Icons.notifications_outlined,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          const _PremiumTile(title: 'Güvenlik', icon: Icons.shield_outlined),
          _PremiumTile(
            title: 'Admin Paneli',
            icon: Icons.admin_panel_settings_outlined,
            onTap: () {
              if (user?.isAdmin ?? false) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin paneli yalnızca yetkili hesaplar içindir.')),
                );
              }
            },
          ),
          _PremiumTile(
            title: 'Çıkış Yap',
            icon: Icons.logout,
            danger: true,
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PremiumTile extends StatelessWidget {
  const _PremiumTile({
    required this.title,
    required this.icon,
    this.onTap,
    this.trailing,
    this.danger = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red.shade700 : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: color),
          title: Text(title, style: TextStyle(color: color)),
          trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

class _PremiumShell extends StatelessWidget {
  const _PremiumShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: scheme.surface.withOpacity(0.78),
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.33)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
