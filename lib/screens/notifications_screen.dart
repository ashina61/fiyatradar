import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/prototype_ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (state.notifications.isEmpty)
            const ProtoCard(child: Text('Henüz bildirimin yok.')),
          ...state.notifications.map((n) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => state.markNotificationRead(n.id),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ProtoColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: n.isRead ? ProtoColors.border : ProtoColors.tan),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: ProtoColors.surfaceAlt, borderRadius: BorderRadius.circular(99)),
                        alignment: Alignment.center,
                        child: Text(n.isRead ? '🔕' : '🔔'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(n.body, style: const TextStyle(fontSize: 12, color: ProtoColors.textSecondary)),
                        ]),
                      )
                    ]),
                  ),
                ),
              ))
        ],
      ),
    );
  }
}
