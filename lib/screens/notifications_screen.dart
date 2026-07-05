import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/messaging_service.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _onlyUnread = false;

  // Silinen (ya da silinmekte olan) bildirim id'leri. Firestore stream'i
  // güncellemeden önce listeden anında düşmeleri için tutuluyor; aksi halde
  // Dismissible "hâlâ ağaçta" assertion'ı atıyor ve unread sayısı bir kare
  // gecikmeli görünüyor.
  final Set<String> _pendingDelete = <String>{};

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final s = AppStrings.of(context);
    final all = state.notifications
        .where((n) => !_pendingDelete.contains(n.id))
        .toList();
    final visible =
        _onlyUnread ? all.where((n) => !n.isRead).toList() : all;
    final unreadCount = all.where((n) => !n.isRead).length;

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
                  if (unreadCount > 0)
                    TextButton.icon(
                      onPressed: () => state.markAllNotificationsRead(),
                      icon: Icon(Icons.done_all_rounded,
                          color: FR.gold, size: 18),
                      label: Text(s.t('notifCenter.markAllRead'),
                          style: frText(12, FontWeight.w800, color: FR.gold)),
                    ),
                  if (all.isNotEmpty)
                    IconButton(
                      tooltip: s.t('notifCenter.clearAll'),
                      onPressed: () => _confirmClearAll(context, state),
                      icon: Icon(Icons.delete_sweep_rounded,
                          color: FR.ink3, size: 22),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                  FRSpace.xl, 10, FRSpace.xl, 0),
              child: FRPageHeader(
                overline: s.t('notifCenter.overline'),
                title: s.t('notifCenter.title'),
                italicTail: s.t('notifCenter.titleTail'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  _Pill(
                    label: '${s.t('notifCenter.filter.all')} · ${all.length}',
                    active: !_onlyUnread,
                    onTap: () => setState(() => _onlyUnread = false),
                  ),
                  const SizedBox(width: 8),
                  _Pill(
                    label:
                        '${s.t('notifCenter.filter.unread')} · $unreadCount',
                    active: _onlyUnread,
                    onTap: () => setState(() => _onlyUnread = true),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: MessagingService.instance.notificationsBlocked,
              builder: (context, blocked, _) {
                if (!blocked) return const SizedBox.shrink();
                return const _PermissionBlockedBanner();
              },
            ),
            Expanded(
              child: visible.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final n = visible[i];
                        return Dismissible(
                          key: ValueKey(n.id),
                          direction: DismissDirection.endToStart,
                          background: const _DismissBackground(),
                          onDismissed: (_) => _deleteOne(context, state, n.id),
                          child: _NotificationTile(
                            notification: n,
                            strings: s,
                            onTap: () => state.markNotificationRead(n.id),
                            onDelete: () => _deleteOne(context, state, n.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteOne(
      BuildContext context, AppState state, String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = AppStrings.of(context);
    // Anında listeden düş — stream güncellemesi gelene kadar yeniden görünmesin
    // ve Dismissible assertion'ı atmasın.
    setState(() => _pendingDelete.add(id));
    try {
      await state.deleteNotification(id);
      messenger.showSnackBar(
        SnackBar(content: Text(s.t('notifCenter.deleted'))),
      );
    } catch (_) {
      // Silme başarısızsa geri getir.
      if (mounted) setState(() => _pendingDelete.remove(id));
      messenger.showSnackBar(
        SnackBar(content: Text(s.t('notifCenter.deleteFailed'))),
      );
    }
  }

  Future<void> _confirmClearAll(BuildContext context, AppState state) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FR.surface,
        title: Text(s.t('notifCenter.clearAll.title'),
            style: frText(15, FontWeight.w800)),
        content: Text(
          s.t('notifCenter.clearAll.confirm'),
          style: frText(13, FontWeight.w600, color: FR.ink2, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.t('common.dismiss'),
                style: frText(13, FontWeight.w800, color: FR.ink2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.t('notifCenter.clearAll'),
                style: frText(13, FontWeight.w800, color: FR.warn)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ids = state.notifications.map((n) => n.id).toList();
    setState(() => _pendingDelete.addAll(ids));
    try {
      await state.clearAllNotifications();
      messenger.showSnackBar(
        SnackBar(content: Text(s.t('notifCenter.clearAll.done'))),
      );
    } catch (_) {
      if (mounted) setState(() => _pendingDelete.removeAll(ids));
      messenger.showSnackBar(
        SnackBar(content: Text(s.t('notifCenter.clearAll.failed'))),
      );
    }
  }
}

/// Swipe-to-delete arkasında görünen kırmızı silme şeridi.
class _DismissBackground extends StatelessWidget {
  const _DismissBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: FR.warn.withOpacity(.16),
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.warn.withOpacity(.40)),
      ),
      child: Icon(Icons.delete_outline_rounded, color: FR.warn, size: 22),
    );
  }
}

/// Bildirim izni kapalıyken görünür uyarı. Kullanıcı fiyat alarmı push'u
/// alamayacağı için sebebi açıkça söylüyoruz (sessiz kalmıyoruz).
class _PermissionBlockedBanner extends StatelessWidget {
  const _PermissionBlockedBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
          FRSpace.xl, FRSpace.m, FRSpace.xl, 0),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
            FRSpace.m, FRSpace.m, FRSpace.m, FRSpace.m),
        decoration: BoxDecoration(
          color: FR.warn.withOpacity(.10),
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: FR.warn.withOpacity(.40)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_off_outlined, color: FR.warn, size: 20),
            const SizedBox(width: FRSpace.s),
            Expanded(
              child: Text(
                AppStrings.of(context).t('notifCenter.permissionBlocked'),
                style: frText(12, FontWeight.w700, color: FR.ink2, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active, this.onTap});
  final String label;
  final bool active;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? FR.gold : FR.surface,
          borderRadius: FRRad.all(999),
          border: Border.all(color: active ? FR.gold : FR.hairline),
        ),
        child: Text(
          label,
          // onGold: altın dolgu üzerindeki metin için ayrılmış token —
          // FR.bg açık temada krem olduğu için kontrast garantisi vermez.
          style: frText(11.5, FontWeight.w800,
              color: active ? FR.onGold : FR.ink2),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.strings,
    required this.onTap,
    this.onDelete,
  });
  final AppNotification notification;
  final AppStrings strings;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

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
                    _iconForType(notification),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _ago(notification.createdAt, strings),
                  style: frText(10.5, FontWeight.w800, color: FR.ink3),
                ),
                if (onDelete != null) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: FRRad.all(999),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(2),
                      child: Icon(Icons.close_rounded,
                          color: FR.ink3, size: 16),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _ago(DateTime date, AppStrings s) {
    final diff = DateTime.now().difference(date);
    final isEn = s.locale.languageCode == 'en';
    if (diff.inMinutes < 1) return s.t('notifCenter.time.now');
    if (diff.inMinutes < 60) {
      return isEn ? '${diff.inMinutes}m' : '${diff.inMinutes}dk';
    }
    if (diff.inHours < 24) {
      return isEn ? '${diff.inHours}h' : '${diff.inHours}sa';
    }
    return isEn ? '${diff.inDays}d' : '${diff.inDays}g';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
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
            Text(AppStrings.of(context).t('notifCenter.empty.title'),
                style: frDisplay(20, FontWeight.w700)),
            const SizedBox(height: 4),
            Text(AppStrings.of(context).t('notifCenter.empty.desc'),
                textAlign: TextAlign.center,
                style: frText(12.5, FontWeight.w600, color: FR.ink3, height: 1.45)),
          ],
        ),
      ),
    );
  }
}

/// Bildirim tipine göre net ikon. Her tip kendi anlamını taşıyan tek bir
/// ikonla gelir; okunmuş/okunmamış farkı ikon değil, kartın rengi + altın
/// nokta + çerçevesi ile gösterilir (bkz. `_NotificationTile`). Bilinmeyen
/// tipler güvenle generic ikona düşer — crash etmez.
///
/// Cloud Function (`functions/index.js`) ve istemci (`app_state.dart`) bu tip
/// stringlerini üretir.
IconData _iconForType(AppNotification n) {
  switch (n.type) {
    // Fiyat alarmı kuruldu — zil/alarm
    case 'price_alert_created':
      return Icons.notifications_active_rounded;
    // Hedef fiyatın altına düştü — bayrak/hedef
    case 'price_alert_target':
      return Icons.flag_rounded;
    // Fiyat düştü — aşağı trend
    case 'regional_price_drop':
    case 'price_drop':
      return Icons.trending_down_rounded;
    // Her yeni fiyat — yeni alarm
    case 'price_new':
      return Icons.add_alert_rounded;
    // Fiyat yükseldi — yukarı trend
    case 'price_rise':
      return Icons.trending_up_rounded;
    // Fiyat katkın alındı — fiyat etiketi
    case 'price_report_created':
      return Icons.local_offer_rounded;
    // Katkın incelemede — kum saati
    case 'price_report_pending':
      return Icons.hourglass_bottom_rounded;
    // Fiyatın doğrulandı — onay rozeti
    case 'price_verified':
      return Icons.verified_rounded;
    // Fiyat raporu onaylandı — onay çemberi
    case 'price_report_approved':
      return Icons.check_circle_rounded;
    // Fiyat raporu / fiyat reddedildi — uyarı
    case 'price_rejected':
    case 'price_report_rejected':
      return Icons.error_outline_rounded;
    // Ürün talebi onaylandı — katalog/doğrulama
    case 'product_request_approved':
      return Icons.verified_rounded;
    // Ürün talebi reddedildi — uyarı
    case 'product_request_rejected':
      return Icons.report_problem_rounded;
    // Ürün görseli onaylandı — görsel/onay
    case 'product_image_approved':
      return Icons.image_rounded;
    // Ürün görseli reddedildi — görsel/uyarı
    case 'product_image_rejected':
      return Icons.image_not_supported_rounded;
    // Rozet kazanıldı — kupa/rozet
    case 'badge_earned':
      return Icons.workspace_premium_rounded;
    // Seviye atladın — askeri rütbe
    case 'level_up':
      return Icons.military_tech_rounded;
    // Haftalık özet — istatistik
    case 'weekly_summary':
      return Icons.insights_rounded;
    case 'generic':
      return Icons.notifications_none_rounded;
    default:
      return Icons.notifications_none_rounded;
  }
}
