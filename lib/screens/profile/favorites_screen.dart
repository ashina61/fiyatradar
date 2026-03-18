import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/fr_colors.dart';
import '../product/product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.userId});

  final String userId;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Map<String, ProductModel> _productCache = <String, ProductModel>{};
  Set<String> _loadingIds = <String>{};

  Future<void> _ensureProducts(List<String> productIds) async {
    final missing = productIds.where((id) => id.isNotEmpty && !_productCache.containsKey(id)).toSet();
    if (missing.isEmpty || _loadingIds.containsAll(missing)) return;

    setState(() => _loadingIds = {..._loadingIds, ...missing});
    try {
      final products = await FirestoreService().getProductsByIds(missing.toList());
      if (!mounted) return;
      setState(() {
        for (final product in products) {
          _productCache[product.id] = product;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _loadingIds = _loadingIds.difference(missing));
      }
    }
  }

  Future<void> _removeFavorite(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('favorites')
          .doc(productId)
          .delete();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favoriler güncellenemedi. Tekrar dene.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FRColors.bgApp,
      appBar: AppBar(
        backgroundColor: FRColors.bgApp,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Favoriler'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('favorites')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _ExecutiveListFeedback(
              icon: CupertinoIcons.exclamationmark_triangle,
              title: 'Favoriler yüklenemedi',
              message: 'Bağlantını kontrol edip tekrar dene.',
            );
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const _ExecutiveListFeedback(
              icon: CupertinoIcons.heart,
              title: 'Henüz favori ürünün yok',
              message: 'Beğendiğin ürünleri kalbinle koleksiyonuna ekleyebilirsin.',
            );
          }

          final productIds = docs
              .map((doc) => (doc.data()['productId'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toList();
          WidgetsBinding.instance.addPostFrameCallback((_) => _ensureProducts(productIds));

          return _ExecutiveListCard(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: FRColors.borderLight),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final productId = (data['productId'] ?? '').toString();
                final product = _productCache[productId];
                final title = (product?.name ?? data['productName'] ?? 'Ürün').toString().trim();
                final subtitle = (product?.brand ?? data['categoryName'] ?? data['brand'] ?? 'Kategori').toString().trim();
                final initial = title.isEmpty ? 'Ü' : title.substring(0, 1).toUpperCase();

                return _ExecutiveRow(
                  onTap: productId.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)),
                          ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: FRColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: FRColors.espresso,
                      ),
                    ),
                  ),
                  title: Text(
                    title.isEmpty ? 'Ürün' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: FRColors.espresso,
                    ),
                  ),
                  subtitle: Text(
                    subtitle.isEmpty ? 'Kategori' : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: FRColors.textMuted,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () => _removeFavorite(productId),
                    icon: const Icon(CupertinoIcons.heart_fill, color: FRColors.danger, size: 21),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ExecutiveListCard extends StatelessWidget {
  const _ExecutiveListCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: FRColors.shadowSoft,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ExecutiveRow extends StatelessWidget {
  const _ExecutiveRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 4),
                  subtitle,
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _ExecutiveListFeedback extends StatelessWidget {
  const _ExecutiveListFeedback({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: FRColors.shadowSoft, blurRadius: 22, offset: Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: FRColors.camel, size: 28),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FRColors.espresso),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FRColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
