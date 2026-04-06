import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);

    return FRAppScaffold(
      child: Column(
        children: [
          FRDarkHero(
            title: 'Bildirim Merkezi',
            subtitle: 'Alarmlar, seviye gelişimi ve sistem güncellemeleri',
            kicker: const FRKickerPill('Realtime Pulse'),
            actions: [
              FRHeroActionButton(
                icon: CupertinoIcons.check_mark_circled,
                onPressed: () => notifier.markAllAsRead(),
              ),
            ],
          ),
          Expanded(
            child: FRPageContainer(
              child: Padding(
                padding: const EdgeInsets.only(top: FRDsSpacing.space16, bottom: FRDsSpacing.space24),
                child: notificationsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: FRSurfaceCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline),
                          const SizedBox(height: FRDsSpacing.space8),
                          Text('Bildirimler yüklenemedi', style: FRDsTypography.titleMedium),
                          const SizedBox(height: FRDsSpacing.space8),
                          FRSecondaryButton(
                            label: 'Tekrar Dene',
                            onPressed: () => ref.invalidate(notificationsStreamProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const _EmptyState();
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: FRDsSpacing.space8),
                      itemBuilder: (_, i) => _NotificationRow(item: items[i]),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return FRSurfaceCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.bell_slash, size: 32),
          const SizedBox(height: FRDsSpacing.space8),
          Text('Sakin bir gün', style: FRDsTypography.titleMedium),
          const SizedBox(height: FRDsSpacing.space4),
          Text('Yeni gelişmeler burada görünecek.', style: FRDsTypography.bodyMedium),
        ],
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationNotifierProvider.notifier);
    final unread = !item.isRead;

    return FRInfoRowCard(
      onTap: () => notifier.markAsRead(item.id),
      leading: CircleAvatar(
        backgroundColor: unread ? FRDsColors.frGoldSoft : FRDsColors.frSurfaceMuted,
        child: Icon(_iconFor(item.type), color: FRDsColors.frBrownDeep),
      ),
      title: item.title,
      subtitle: '${item.message}\n${_formatDate(item.createdAtDate)}',
      trailing: unread ? const FRStatusBadge('Yeni') : const FRPill('Okundu', variant: FRPillVariant.muted),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'alarm':
        return CupertinoIcons.bell_fill;
      case 'level_up':
        return CupertinoIcons.rosette;
      default:
        return CupertinoIcons.info_circle_fill;
    }
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
}
