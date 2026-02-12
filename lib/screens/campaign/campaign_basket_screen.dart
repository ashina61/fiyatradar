import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../../models/banner_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../product/product_detail_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/home_product_card.dart';

class CampaignBasketScreen extends ConsumerStatefulWidget {
  final String campaignId;
  final BannerModel? banner;

  const CampaignBasketScreen({
    super.key,
    required this.campaignId,
    this.banner,
  });

  @override
  ConsumerState<CampaignBasketScreen> createState() => _CampaignBasketScreenState();
}

class _CampaignBasketScreenState extends ConsumerState<CampaignBasketScreen> {
  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadProducts();
  }

  Future<List<ProductModel>> _loadProducts() async {
    if (!firebaseInitialized) return const [];
    final service = ref.read(firestoreServiceProvider);

    var productIds = widget.banner?.targetProductIds ?? const <String>[];
    if (productIds.isEmpty) {
      productIds = await service.getCampaignProductIdsForBanner(widget.campaignId);
    }

    if (productIds.isEmpty) return const [];
    return service.getProductsByIds(productIds);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.banner?.title ?? 'Kampanya Sepeti';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<ProductModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Kampanya ürünleri yüklenemedi'));
          }

          final products = snapshot.data ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.banner?.description != null && widget.banner!.description!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                  child: Text(
                    widget.banner!.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              Expanded(
                child: products.isEmpty
                    ? const Center(child: Text('Bu kampanyada ürün bulunamadı'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 12.0;
                          final cardWidth = (constraints.maxWidth - (AppSpacing.md * 2) - spacing) / 2;
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
                            itemCount: products.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return HomeProductCard(
                                product: product,
                                width: cardWidth,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(productId: product.id),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
