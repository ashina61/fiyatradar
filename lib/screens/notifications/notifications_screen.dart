import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../theme/fr_colors.dart';
import '../../widgets/premium_scaffold_shell.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: FRColors.background,
      appBar: AppBar(
        backgroundColor: FRColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Bildirim Merkezi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: FRColors.espresso,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: const Text(
                'Tümünü Okundu İşaretle',
                style: TextStyle(
                  color: FRColors.camel,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: PremiumScaffoldShell(
        child: notificationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: FRColors.camel),
          ),
          error: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Bildirimler yüklenemedi.',
                  style: TextStyle(
                    color: FRColors.espresso,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(notificationsStreamProvider),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
          data: (items) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: items.isEmpty ? const _EmptyState() : _NotificationsList(items: items),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x14C09A60),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Icon(
                  CupertinoIcons.bell_slash,
                  size: 34,
                  color: FRColors.camel,
                ),
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Sakin Bir Gün',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: FRColors.espresso,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Şu an için yeni bir gelişme yok. Alarmların ve puanların burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: FRColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsList extends ConsumerWidget {
  const _NotificationsList({required this.items});

  final List<NotificationItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationNotifierProvider.notifier);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final isUnread = !item.isRead;
        final iconTheme = _resolveIconTheme(item.type);
        return Material(
          color: isUnread ? FRColors.camel.withOpacity(0.05) : FRColors.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => notifier.markAsRead(item.id),
            child: Container(
              decoration: BoxDecoration(
                color: isUnread ? FRColors.camel.withOpacity(0.05) : FRColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FRColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: FRColors.shadowSoft,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: SizedBox(
                  width: 46,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: FRColors.camel,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: FRColors.camel.withOpacity(0.55),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconTheme.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(iconTheme.icon, color: iconTheme.foreground, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: FRColors.espresso,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.message,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: FRColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(item.createdAtDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                          color: isUnread ? FRColors.camelDeep : FRColors.textMutedSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
    if (diff.inDays < 1) return '${diff.inHours} sa önce';
    if (diff.inDays == 1) return 'Dün';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  _IconThemeData _resolveIconTheme(String type) {
    switch (type) {
      case 'alarm':
        return const _IconThemeData(
          icon: CupertinoIcons.bell_fill,
          background: Color(0x1FC09A60),
          foreground: FRColors.camel,
        );
      case 'level_up':
        return const _IconThemeData(
          icon: CupertinoIcons.rosette,
          background: FRColors.espresso,
          foreground: FRColors.surface,
        );
      default:
        return const _IconThemeData(
          icon: CupertinoIcons.info_circle_fill,
          background: Color(0xFFEDEAE6),
          foreground: FRColors.textMuted,
        );
    }
  }
}

class _IconThemeData {
  const _IconThemeData({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}
