import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';

/// Filter categories for notification types.
enum _NotificationFilter {
  all('Tumu'),
  priceDrop('Fiyat Dususu'),
  newPrice('Yeni Fiyat'),
  achievement('Basarim'),
  system('Sistem');

  final String label;
  const _NotificationFilter(this.label);
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

  List<NotificationModel> _filterNotifications(List<NotificationModel> notifications) {
    if (_selectedFilter == _NotificationFilter.all) {
      return notifications;
    }
    return notifications.where((n) {
      switch (_selectedFilter) {
        case _NotificationFilter.priceDrop:
          return n.type == NotificationType.priceDropped;
        case _NotificationFilter.newPrice:
          return n.type == NotificationType.priceVerified ||
              n.type == NotificationType.priceApproved;
        case _NotificationFilter.achievement:
          return n.type == NotificationType.newBadge;
        case _NotificationFilter.system:
          return n.type == NotificationType.system;
        default:
          return true;
      }
    }).toList();
  }

  void _markAllAsRead() {
    ref.read(notificationNotifierProvider.notifier).markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tum bildirimler okundu olarak isaretlendi'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  void _markAsRead(String id) {
    ref.read(notificationNotifierProvider.notifier).markAsRead(id);
  }

  void _deleteNotification(String id) {
    ref.read(notificationNotifierProvider.notifier).deleteNotification(id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bildirim silindi'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  void _onNotificationTap(NotificationModel notification) {
    _markAsRead(notification.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationDetailSheet(
        notification: notification,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          notificationsAsync.when(
            data: (notifications) {
              final hasUnread = notifications.any((n) => !n.isRead);
              if (hasUnread) {
                return TextButton(
                  onPressed: _markAllAsRead,
                  child: const Text(
                    'Tumunu Okundu Isaretle',
                    style: TextStyle(fontSize: 13),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterBar(theme),
          // Notification list or empty state
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) {
                final filtered = _filterNotifications(notifications);
                return filtered.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildNotificationList(filtered, theme);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildEmptyState(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: _NotificationFilter.values.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedFilter = filter);
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                backgroundColor: theme.colorScheme.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : theme.colorScheme.outline.withOpacity(0.3),
                    width: isSelected ? 0 : 1,
                  ),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Bildirim yok',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Henuz bildiriminiz bulunmuyor',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
      List<NotificationModel> notifications, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildDismissibleCard(notification, theme),
        );
      },
    );
  }

  Widget _buildDismissibleCard(
      NotificationModel notification, ThemeData theme) {
    return Dismissible(
      key: ValueKey(notification.id),
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.success,
        icon: Icons.check_circle_outline,
        label: 'Okundu',
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.error,
        icon: Icons.delete_outline,
        label: 'Sil',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _markAsRead(notification.id);
          return false; // don't actually dismiss
        }
        return true; // allow delete
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteNotification(notification.id);
        }
      },
      child: _NotificationCard(
        notification: notification,
        onTap: () => _onNotificationTap(notification),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      alignment: alignment,
      padding: EdgeInsets.only(
        left: isLeft ? AppSpacing.lg : 0,
        right: isLeft ? 0 : AppSpacing.lg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ]
            : [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(icon, color: Colors.white, size: 22),
              ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification Card
// ---------------------------------------------------------------------------

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;
    final iconConfig = _iconConfigForType(notification.type);

    return Material(
      color: isUnread
          ? AppColors.primary.withOpacity(0.04)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isUnread
                  ? AppColors.primary.withOpacity(0.15)
                  : theme.colorScheme.outline.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconConfig.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconConfig.icon,
                  color: iconConfig.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isUnread ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatRelativeTime(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (isUnread) ...[
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _IconConfig _iconConfigForType(NotificationType type) {
    switch (type) {
      case NotificationType.priceDropped:
        return const _IconConfig(Icons.trending_down, AppColors.success);
      case NotificationType.priceVerified:
      case NotificationType.priceApproved:
        return const _IconConfig(Icons.new_releases, AppColors.info);
      case NotificationType.newBadge:
        return const _IconConfig(Icons.emoji_events, Color(0xFFF59E0B));
      case NotificationType.priceRejected:
        return const _IconConfig(Icons.thumb_down_alt, AppColors.error);
      case NotificationType.newComment:
        return const _IconConfig(Icons.chat_bubble_outline, AppColors.primary);
      case NotificationType.system:
        return const _IconConfig(Icons.info_outline, AppColors.textTertiary);
    }
  }
}

class _IconConfig {
  final IconData icon;
  final Color color;
  const _IconConfig(this.icon, this.color);
}

// ---------------------------------------------------------------------------
// Notification Detail Bottom Sheet
// ---------------------------------------------------------------------------

class _NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationDetailSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconConfig = _iconConfigForType(notification.type);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconConfig.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconConfig.icon,
              color: iconConfig.color,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Title
          Text(
            notification.title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Body
          Text(
            notification.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Time
          Text(
            _formatRelativeTime(notification.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          if (notification.productName != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Product navigation could be handled here
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text('${notification.productName} Goruntule'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  _IconConfig _iconConfigForType(NotificationType type) {
    switch (type) {
      case NotificationType.priceDropped:
        return const _IconConfig(Icons.trending_down, AppColors.success);
      case NotificationType.priceVerified:
      case NotificationType.priceApproved:
        return const _IconConfig(Icons.new_releases, AppColors.info);
      case NotificationType.newBadge:
        return const _IconConfig(Icons.emoji_events, Color(0xFFF59E0B));
      case NotificationType.priceRejected:
        return const _IconConfig(Icons.thumb_down_alt, AppColors.error);
      case NotificationType.newComment:
        return const _IconConfig(Icons.chat_bubble_outline, AppColors.primary);
      case NotificationType.system:
        return const _IconConfig(Icons.info_outline, AppColors.textTertiary);
    }
  }
}

// ---------------------------------------------------------------------------
// Relative time helper (Turkish)
// ---------------------------------------------------------------------------

String _formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Simdi';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} dakika once';
  } else if (difference.inHours < 24) {
    final hours = difference.inHours;
    return '$hours saat once';
  } else if (difference.inDays == 1) {
    return 'Dun';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} gun once';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '$weeks hafta once';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '$months ay once';
  } else {
    final years = (difference.inDays / 365).floor();
    return '$years yil once';
  }
}
