import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final items = state.notifications;

    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  FRIconChip(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (state.unreadNotificationCount > 0)
                    TextButton.icon(
                      onPressed: () => state.markAllNotificationsRead(),
                      icon: Icon(Icons.done_all_rounded,
                          color: FR.gold, size: 18),
                      label: Text('Tümünü okundu işaretle',
                          style: frText(12, FontWeight.w800, color: FR.gold)),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(FRSpace.xl, 10, FRSpace.xl, 0),
              child: FRPageHeader(
                overline: 'RADAR SİNYALLERİ',
                title: 'Bildirim',
                italicTail: ' merkezi',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  _Pill(label: 'Tümü · ${items.length}', active: true),
                  const SizedBox(width: 8),
                  _Pill(
                    label: 'Okunmamış · ${state.unreadNotificationCount}',
                    active: false,
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _NotificationTile(
                        notification: items[i],
                        onTap: () => state.markNotificationRead(items[i].id),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active});
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? FR.gold : FR.surface,
        borderRadius: FRRad.all(999),
        border: Border.all(color: active ? FR.gold : FR.hairline),
      ),
      child: Text(
        label,
        style: frText(11.5, FontWeight.w800, color: active ? FR.bg : FR.ink2),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(
            color: notification.isRead ? FR.hairline : FR.goldDeep.withOpacity(.55),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: notification.isRead ? FR.surfaceHi : FR.gold.withOpacity(.16),
                    borderRadius: FRRad.all(12),
                    border: Border.all(
                      color: notification.isRead ? FR.hairline : FR.goldDeep,
                    ),
                  ),
                  child: Icon(
                    notification.isRead
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                    color: notification.isRead ? FR.ink3 : FR.gold,
                    size: 19,
                  ),
                ),
                if (!notification.isRead)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: FR.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: FR.bg, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: frText(
                      13.5,
                      notification.isRead ? FontWeight.w700 : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: frText(12, FontWeight.w500, color: FR.ink2, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _ago(notification.createdAt),
              style: frText(10.5, FontWeight.w800, color: FR.ink3),
            ),
          ],
        ),
      ),
    );
  }

  static String _ago(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
    if (diff.inHours < 24) return '${diff.inHours}sa';
    return '${diff.inDays}g';
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [FR.surface, FR.surfaceLo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: FRRad.all(28),
                border: Border.all(color: FR.hairline),
              ),
              child: Icon(Icons.notifications_off_outlined,
                  color: FR.ink3, size: 38),
            ),
            const SizedBox(height: 14),
            Text('Henüz sinyal yok', style: frDisplay(20, FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Fiyat alarmların ve radar bildirimleri burada görünür.',
                textAlign: TextAlign.center,
                style: frText(12.5, FontWeight.w600, color: FR.ink3, height: 1.45)),
          ],
        ),
      ),
    );
  }
}
