import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/executive_ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      backgroundColor: ExecColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: state.notifications
                    .map(
                      (n) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: execCard(radius: 18).copyWith(border: Border.all(color: n.isRead ? ExecColors.bgDeep : ExecColors.gold.withOpacity(.35))),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: n.isRead ? ExecColors.bgSoft : const Color(0x1FC9A063), borderRadius: BorderRadius.circular(14)),
                            child: Icon(n.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded, color: n.isRead ? ExecColors.ink3 : ExecColors.goldDeep, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(n.title, style: manrope(13, n.isRead ? FontWeight.w700 : FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(n.body, style: manrope(12, FontWeight.w600, color: ExecColors.ink3, height: 1.4)),
                            ]),
                          ),
                          Text(_timeAgo(n.createdAt), style: manrope(11, FontWeight.w800, color: ExecColors.ink4))
                        ]),
                      ),
                    )
                    .toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}d';
    if (diff.inHours < 24) return '${diff.inHours}s';
    return '${diff.inDays}g';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(onTap: onBack, child: const Icon(Icons.chevron_left, color: ExecColors.ink2)),
        RichText(text: TextSpan(text: 'Bildirim ', style: fraunces(44, FontWeight.w700), children: [TextSpan(text: 'Merkezi', style: fraunces(44, FontWeight.w400, color: ExecColors.ink3, style: FontStyle.italic))])),
        const SizedBox(height: 8),
        Text('RADARDAN SANA NOTLAR', style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 2.2)),
      ]),
    );
  }
}
