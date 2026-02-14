import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userModelStreamProvider).valueOrNull;
    final trust = (user?.reliabilityScore ?? 72).clamp(0, 100).toDouble();
    final monthlySavings = ((user?.points ?? 0) * 3.4).toStringAsFixed(0);
    final streak = ((user?.validations ?? 0) ~/ 2).clamp(0, 365);
    final topMarket = (user?.validations ?? 0) > 20 ? 'Migros' : 'A101';

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            title: Text(l10n.profileTitle),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _HeroCard(
                  user: user,
                  trust: trust,
                  monthlySavings: monthlySavings,
                  topMarket: topMarket,
                  streak: streak,
                  onEdit: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
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
                _ActivityFeed(user: user),
                const SizedBox(height: 16),
                _Badges(user: user),
                const SizedBox(height: 16),
                _SettingsCard(user: user),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.user,
    required this.trust,
    required this.monthlySavings,
    required this.topMarket,
    required this.streak,
    required this.onEdit,
  });

  final UserModel? user;
  final double trust;
  final String monthlySavings;
  final String topMarket;
  final int streak;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.secondaryContainer.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                        ? Text(_initials(user?.name))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name.isNotEmpty == true ? user!.name : l10n.genericUser,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        _MiniBadge(label: trust >= 80 ? l10n.eliteContributor : l10n.validatorBadge),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l10n.editProfile,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.trustScoreLabel),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: trust / 100,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('%${trust.toStringAsFixed(0)}'),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(label: '${l10n.monthlySavings}: ₺$monthlySavings'),
                  _StatChip(label: '${l10n.bestMarket}: $topMarket'),
                  _StatChip(label: '${l10n.streakLabel}: $streak ${l10n.dayLabel}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String? value) {
    if (value == null || value.trim().isEmpty) return 'FR';
    final parts = value.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
    final l10n = AppLocalizations.of(context)!;
    return _CardShell(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionButton(icon: Icons.price_change_outlined, label: l10n.myPrices, onTap: onMyPrices),
          _ActionButton(icon: Icons.receipt_long_outlined, label: l10n.myReceipts, onTap: onReceipts),
          _ActionButton(icon: Icons.favorite_outline, label: l10n.favorites, onTap: onFavorites),
          _ActionButton(icon: Icons.notifications_none, label: l10n.notifications, onTap: onNotifications),
        ],
      ),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final events = <(String, String)>[
      (l10n.priceVerifiedTitle, l10n.priceVerifiedSubtitle),
      (l10n.contributionGainedTitle, l10n.contributionGainedSubtitle),
      (l10n.reportReceivedTitle, l10n.reportReceivedSubtitle),
    ];

    if ((user?.validations ?? 0) == 0 && (user?.priceEntries ?? 0) == 0) {
      return _CardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.recentActivities, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Text(l10n.noActivity),
          ],
        ),
      );
    }

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.recentActivities, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...events.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                tileColor: Theme.of(context).colorScheme.surface.withOpacity(0.45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Text(e.$1),
                subtitle: Text(e.$2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badges = <(String, String)>[
      (l10n.badgeValidator, l10n.badgeValidatorDesc),
      (l10n.badgeHunter, l10n.badgeHunterDesc),
      (l10n.badgeReliable, l10n.badgeReliableDesc),
      (l10n.badgeCommunity, l10n.badgeCommunityDesc),
    ];

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.badgesTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if ((user?.validations ?? 0) == 0 && (user?.priceEntries ?? 0) == 0)
            Text(l10n.noBadges)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: badges.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, index) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(badges[index].$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(badges[index].$2, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
            ),
            child: Text(l10n.nextBadgeSuggestion),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mode = ref.watch(themeModeProvider);

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settings, style: Theme.of(context).textTheme.titleMedium),
          _SettingsTile(
            title: l10n.editProfile,
            icon: Icons.edit_outlined,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          _SettingsTile(
            title: l10n.darkMode,
            icon: Icons.dark_mode_outlined,
            trailing: Switch(
              value: mode == ThemeMode.dark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggleDarkMode(),
            ),
          ),
          _SettingsTile(
            title: l10n.notificationSettings,
            icon: Icons.notifications_outlined,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          _SettingsTile(title: l10n.security, icon: Icons.shield_outlined),
          if (user?.isAdmin ?? false)
            _SettingsTile(
              title: l10n.adminPanel,
              icon: Icons.admin_panel_settings_outlined,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
            ),
          _SettingsTile(
            title: l10n.logout,
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

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surface.withOpacity(0.8),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
      ),
      child: child,
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.5),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
      ),
      child: Text(label),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
