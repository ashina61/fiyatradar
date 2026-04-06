// lib/screens/notifications/notifications_screen.dart
// GREENFIELD v2 — notification center in the "Quiet Intelligence" language.
// Rejected: dark hero pill, "Realtime Pulse" kicker, card list with icons.
// UX goal: a chronological log of signals. Thin rows, unread dot, mark-all action.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../theme/fr_ink.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: FRInk.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(onClose: () => Navigator.of(context).maybePop(), onMarkAll: notifier.markAllAsRead),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.fromLTRB(FRInk.gutter, 0, FRInk.gutter, 0),
              child: Text('SİNYALLER', style: FRType.micro),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: FRInk.gutter),
              child: Text('Bildirimler', style: FRType.title),
            ),
            const SizedBox(height: 24),
            const FRHairline(),
            Expanded(
              child: async.when(
                loading: () => const _CenterLoader(),
                error: (_, __) => const _CenterMsg('Bildirimler alınamadı.'),
                data: (list) => list.isEmpty
                    ? const _CenterMsg('Henüz bildirim yok.')
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 40),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const FRHairline(indent: FRInk.gutter),
                        itemBuilder: (_, i) => _NotifRow(
                          item: list[i],
                          onTap: () => notifier.markAsRead(list[i].id),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, required this.onMarkAll});
  final VoidCallback onClose;
  final VoidCallback onMarkAll;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 14, FRInk.gutter, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.arrow_back_rounded, size: 24, color: FRInk.ink),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onMarkAll,
            child: const Text(
              'tümünü oku',
              style: TextStyle(
                fontFamily: FRType.family,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FRInk.saffron,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({required this.item, required this.onTap});
  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dt = item.createdAt.toDate();
    final time = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: item.isRead ? FRInk.hairline : FRInk.saffron,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: FRType.bodyStrong,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(time, style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.message, style: FRType.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterLoader extends StatelessWidget {
  const _CenterLoader();
  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: FRInk.ink),
        ),
      );
}

class _CenterMsg extends StatelessWidget {
  const _CenterMsg(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(FRInk.gutter),
          child: Text(text, style: FRType.body, textAlign: TextAlign.center),
        ),
      );
}
