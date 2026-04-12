import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/prototype_ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ProtoColors.border))),
              child: Row(
                children: [
                  const Expanded(child: Text('Bildirimler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: protoSurface(radius: 18),
                      child: const Icon(Icons.close, color: ProtoColors.textSecondary, size: 18),
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  ...state.notifications.map(
                    (n) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ProtoColors.surface,
                        borderRadius: FRRadii.lg,
                        border: Border.all(color: n.isRead ? ProtoColors.border : ProtoColors.tan.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          if (!n.isRead)
                            Container(
                              width: 3,
                              height: 40,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(color: ProtoColors.tan, borderRadius: FRRadii.sm),
                            ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: ProtoColors.surfaceAlt, borderRadius: FRRadii.pill),
                            alignment: Alignment.center,
                            child: Text(n.isRead ? '🔕' : '🔔', style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(n.title, style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(n.body, style: const TextStyle(fontSize: 12, color: ProtoColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(_timeAgo(n.createdAt), style: const TextStyle(fontSize: 10, color: ProtoColors.textSubtle)),
                            ]),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }
}
