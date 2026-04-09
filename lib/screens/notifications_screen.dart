import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/design.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final items = state.notifications;

    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          TextButton(
            onPressed: state.unreadNotificationCount == 0
                ? null
                : () => state.markAllNotificationsRead(),
            child: const Text('Tümünü okundu yap'),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Henüz bildirimin yok.',
                style: TextStyle(
                  color: CoffeeColors.cocoa,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = items[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: n.isRead
                          ? CoffeeColors.crema
                          : CoffeeColors.caramel.withOpacity(0.4),
                    ),
                    boxShadow: FR.softShadow,
                  ),
                  child: ListTile(
                    onTap: () => state.markNotificationRead(n.id),
                    leading: Icon(
                      n.isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active_outlined,
                      color: n.isRead
                          ? CoffeeColors.cocoa
                          : CoffeeColors.caramel,
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight:
                            n.isRead ? FontWeight.w600 : FontWeight.w800,
                        color: CoffeeColors.espresso,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        n.body,
                        style: const TextStyle(color: CoffeeColors.cocoa),
                      ),
                    ),
                    trailing: n.isRead
                        ? null
                        : TextButton(
                            onPressed: () =>
                                state.markNotificationRead(n.id),
                            child: const Text('Okundu'),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
