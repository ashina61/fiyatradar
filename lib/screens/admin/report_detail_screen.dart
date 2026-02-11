import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/comment_model.dart';
import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/theme.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> report;

  const ReportDetailScreen({
    super.key,
    required this.report,
  });

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  final TextEditingController _resolutionController = TextEditingController();
  bool _isResolving = false;

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchTarget() async {
    final service = ref.read(firestoreServiceProvider);
    final targetType = widget.report['targetType'] as String? ?? '';
    final targetId = widget.report['targetId'] as String? ?? '';
    final contextId = widget.report['contextId'] as String?;

    switch (targetType) {
      case 'comment':
        final comment = await service.getCommentById(targetId);
        final productId = contextId ?? comment?.productId;
        final product = productId != null ? await service.getProduct(productId) : null;
        final user = comment != null ? await service.getUserById(comment.userId) : null;
        return {
          'comment': comment,
          'product': product,
          'user': user,
        };
      case 'product':
        final product = await service.getProduct(targetId);
        return {'product': product};
      case 'user':
        final user = await service.getUserById(targetId);
        return {'user': user};
      case 'priceEntry':
      case 'price':
        final price = await service.getPriceById(targetId);
        final productId = contextId ?? price?.productId;
        final product = productId != null ? await service.getProduct(productId) : null;
        return {
          'price': price,
          'product': product,
        };
      default:
        return null;
    }
  }

  Future<void> _resolveReport(String status) async {
    setState(() => _isResolving = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      await ref.read(firestoreServiceProvider).updateReportStatus(
            widget.report['id'] as String,
            status,
            resolvedBy: currentUser?.uid,
            resolutionNote: _resolutionController.text.trim().isEmpty
                ? null
                : _resolutionController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = widget.report;
    final targetType = report['targetType'] as String? ?? '';
    final status = report['status'] as String? ?? 'pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapor Detayi'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchTarget(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final isMissing = snapshot.connectionState == ConnectionState.done &&
              (data == null ||
                  (data['comment'] == null &&
                      data['product'] == null &&
                      data['user'] == null &&
                      data['price'] == null));

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _ReportInfoCard(report: report),
              const SizedBox(height: AppSpacing.md),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (isMissing)
                _MissingTargetCard()
              else ...[
                if (targetType == 'comment')
                  _CommentTargetCard(
                    comment: data?['comment'] as CommentModel?,
                    product: data?['product'] as ProductModel?,
                    user: data?['user'] as UserModel?,
                  ),
                if (targetType == 'product')
                  _ProductTargetCard(product: data?['product'] as ProductModel?),
                if (targetType == 'user')
                  _UserTargetCard(user: data?['user'] as UserModel?),
                if (targetType == 'priceEntry' || targetType == 'price')
                  _PriceTargetCard(
                    price: data?['price'] as PriceModel?,
                    product: data?['product'] as ProductModel?,
                  ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('Cozum Notu', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _resolutionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Raporu kapatirken not ekleyin (opsiyonel)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_isResolving)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: status == 'resolved'
                            ? null
                            : () => _resolveReport('resolved'),
                        child: const Text('Cozuldu'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: status == 'rejected'
                            ? null
                            : () => _resolveReport('rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Reddet'),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportInfoCard extends StatelessWidget {
  final Map<String, dynamic> report;

  const _ReportInfoCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final createdAt = report['createdAt'] as DateTime?;
    final status = report['status'] as String? ?? 'pending';
    final targetType = report['targetType'] as String? ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rapor Bilgisi', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(label: 'Durum', value: status),
            _InfoRow(label: 'Tur', value: targetType),
            _InfoRow(label: 'Neden', value: report['reason'] ?? '-'),
            if (createdAt != null)
              _InfoRow(
                label: 'Tarih',
                value: '${createdAt.day}.${createdAt.month}.${createdAt.year}',
              ),
          ],
        ),
      ),
    );
  }
}

class _MissingTargetCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text('Hedef bulunamadi (silinmis olabilir).'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTargetCard extends StatelessWidget {
  final CommentModel? comment;
  final ProductModel? product;
  final UserModel? user;

  const _CommentTargetCard({
    required this.comment,
    required this.product,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yorum', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(comment?.text ?? 'Yorum bulunamadi'),
            const SizedBox(height: AppSpacing.md),
            Text('Urun', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(product?.name ?? 'Urun bulunamadi'),
            const SizedBox(height: AppSpacing.md),
            Text('Yorumcu', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(user?.name ?? 'Kullanici bulunamadi'),
          ],
        ),
      ),
    );
  }
}

class _ProductTargetCard extends StatelessWidget {
  final ProductModel? product;

  const _ProductTargetCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Urun Detayi', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(product?.name ?? 'Urun bulunamadi'),
            const SizedBox(height: AppSpacing.xs),
            Text(product?.brand ?? ''),
            const SizedBox(height: AppSpacing.xs),
            Text(product?.category ?? ''),
          ],
        ),
      ),
    );
  }
}

class _UserTargetCard extends StatelessWidget {
  final UserModel? user;

  const _UserTargetCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kullanici', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(user?.name ?? 'Kullanici bulunamadi'),
            const SizedBox(height: AppSpacing.xs),
            Text(user?.email ?? ''),
            const SizedBox(height: AppSpacing.xs),
            Text('Puan: ${user?.points ?? 0}'),
          ],
        ),
      ),
    );
  }
}

class _PriceTargetCard extends StatelessWidget {
  final PriceModel? price;
  final ProductModel? product;

  const _PriceTargetCard({
    required this.price,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fiyat Girdisi', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('Urun: ${product?.name ?? 'Bilinmiyor'}'),
            const SizedBox(height: AppSpacing.xs),
            Text('Market: ${price?.storeName ?? '-'}'),
            const SizedBox(height: AppSpacing.xs),
            Text('Fiyat: ${price?.price.toStringAsFixed(2) ?? '-'}'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
