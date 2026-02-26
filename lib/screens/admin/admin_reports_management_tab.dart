import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/product_provider.dart';
import '../../utils/theme.dart';
import '../product/product_detail_screen.dart';
import 'report_detail_screen.dart';

class AdminReportsManagementTab extends ConsumerStatefulWidget {
  final String? initialFilter;

  const AdminReportsManagementTab({super.key, this.initialFilter});

  @override
  ConsumerState<AdminReportsManagementTab> createState() =>
      _AdminReportsManagementTabState();
}

class _AdminReportsManagementTabState
    extends ConsumerState<AdminReportsManagementTab> {
  late String _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialFilter ?? 'all';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.accent;
      case 'resolved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'resolved':
        return 'Cozuldu';
      case 'rejected':
        return 'Reddedildi';
      default:
        return status;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'priceEntry':
        return 'Fiyat';
      case 'comment':
        return 'Yorum';
      case 'product':
        return 'Urun';
      case 'user':
        return 'Kullanici';
      case 'other':
        return 'Diger';
      default:
        return type;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'priceEntry':
        return Icons.price_change_outlined;
      case 'comment':
        return Icons.comment_outlined;
      case 'product':
        return Icons.inventory_2_outlined;
      case 'user':
        return Icons.person_outline;
      default:
        return Icons.flag_outlined;
    }
  }

  Future<void> _openReportedContent(Map<String, dynamic> report) async {
    final targetType = (report['targetType'] as String? ?? '').toLowerCase();
    final targetId = report['targetId'] as String? ?? '';
    final contextId = report['contextId'] as String?;
    final service = ref.read(adminModerationDomainServiceProvider);

    try {
      if (targetType == 'comment') {
        final comment = await service.getCommentById(targetId);
        final productId = contextId ?? comment?.productId;
        if (productId != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                productId: productId,
                highlightedCommentId: targetId,
              ),
            ),
          );
          return;
        }
      }

      if (targetType == 'priceentry' || targetType == 'price') {
        final price = await service.getPriceById(targetId);
        final productId = contextId ?? price?.productId;
        if (productId != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                productId: productId,
                highlightedPriceId: targetId,
              ),
            ),
          );
          return;
        }
      }

      if (targetType == 'product' && targetId.isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: targetId),
          ),
        );
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportDetailScreen(report: report)),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportDetailScreen(report: report)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);
    final theme = Theme.of(context);

    return reportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag_outlined, size: 64, color: theme.hintColor),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Henuz rapor yok',
                  style: TextStyle(color: theme.hintColor, fontSize: 16),
                ),
              ],
            ),
          );
        }
        final filteredReports = _statusFilter == 'all'
            ? reports
            : reports.where((report) => report['status'] == _statusFilter).toList();
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: filteredReports.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    _ReportsStatusChip(
                      label: 'Tumu',
                      selected: _statusFilter == 'all',
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    _ReportsStatusChip(
                      label: 'Bekleyen',
                      selected: _statusFilter == 'pending',
                      onTap: () => setState(() => _statusFilter = 'pending'),
                    ),
                    _ReportsStatusChip(
                      label: 'Cozuldu',
                      selected: _statusFilter == 'resolved',
                      onTap: () => setState(() => _statusFilter = 'resolved'),
                    ),
                    _ReportsStatusChip(
                      label: 'Reddedildi',
                      selected: _statusFilter == 'rejected',
                      onTap: () => setState(() => _statusFilter = 'rejected'),
                    ),
                  ],
                ),
              );
            }
            final report = filteredReports[index - 1];
            final status = report['status'] as String;
            final type = report['targetType'] as String? ?? '';
            final reason = report['reason'] as String;
            final createdAt = report['createdAt'] as DateTime;

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () => _openReportedContent(report),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              _typeIcon(type),
                              color: _statusColor(status),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.xs,
                                        ),
                                      ),
                                      child: Text(
                                        _typeLabel(type),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _statusColor(status),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.xs,
                                        ),
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _statusColor(status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reason,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: theme.hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${createdAt.day}.${createdAt.month}.${createdAt.year}',
                            style: TextStyle(fontSize: 11, color: theme.hintColor),
                          ),
                          const Spacer(),
                          if (status == 'pending') ...[
                            SizedBox(
                              height: 30,
                              child: TextButton.icon(
                                onPressed: () {
                                  ref
                                      .read(adminModerationDomainServiceProvider)
                                      .updateReportStatus(report['id'], 'resolved');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Rapor cozuldu olarak isaretlendi',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Coz',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                              child: TextButton.icon(
                                onPressed: () {
                                  ref
                                      .read(adminModerationDomainServiceProvider)
                                      .updateReportStatus(report['id'], 'rejected');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Rapor reddedildi'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.cancel_outlined, size: 16),
                                label: const Text(
                                  'Reddet',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SizedBox(
                            height: 30,
                            child: IconButton(
                              onPressed: () {
                                ref
                                    .read(adminModerationDomainServiceProvider)
                                    .deleteReport(report['id']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Rapor silindi'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                              color: AppColors.error,
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Raporlar yuklenemedi')),
    );
  }
}

class _ReportsStatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReportsStatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withOpacity(0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : Theme.of(context).hintColor,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.primary.withOpacity(0.4)
            : Theme.of(context).dividerColor,
      ),
    );
  }
}
