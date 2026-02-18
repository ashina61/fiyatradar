import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/firebase_init_provider.dart';
import '../../models/banner_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/home_product_card.dart';
import '../product/product_detail_screen.dart';

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
  late Future<_CampaignBasketData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCampaignBasket();
  }

  Future<_CampaignBasketData> _loadCampaignBasket() async {
    if (!firebaseInitialized) return const _CampaignBasketData.empty();
    final service = ref.read(firestoreServiceProvider);

    final campaignId = widget.campaignId.trim();
    if (campaignId.isEmpty) {
      return const _CampaignBasketData.empty(
        emptyMessage: 'Bu kampanyaya ait ürün yok',
      );
    }

    final basketData = await service.getCampaignBasket(campaignId);
    if (basketData == null) {
      return const _CampaignBasketData.empty(
        emptyMessage: 'Bu kampanyada ürün bulunamadı',
      );
    }

    final products = await service.getCampaignBasketProducts(campaignId);
    if (products.isEmpty) {
      return _CampaignBasketData(
        title: basketData['title']?.toString(),
        subtitle: basketData['subtitle']?.toString(),
        products: const [],
        emptyMessage: 'Bu kampanyada ürün bulunamadı',
      );
    }

    return _CampaignBasketData(
      title: basketData['title']?.toString(),
      subtitle: basketData['subtitle']?.toString(),
      products: products,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallbackTitle = widget.banner?.title ?? 'Kampanya Sepeti';

    return Scaffold(
      appBar: AppBar(title: Text(fallbackTitle)),
      body: FutureBuilder<_CampaignBasketData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Kampanya ürünleri yüklenemedi'));
          }

          final data = snapshot.data ?? const _CampaignBasketData.empty();
          final products = data.products;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((data.subtitle ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    data.subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              Expanded(
                child: products.isEmpty
                    ? Center(child: Text(data.emptyMessage))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 12.0;
                          final cardWidth =
                              (constraints.maxWidth - (AppSpacing.md * 2) - spacing) /
                                  2;
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              AppSpacing.lg,
                            ),
                            itemCount: products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
                                      builder: (_) =>
                                          ProductDetailScreen(productId: product.id),
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

class _CampaignBasketData {
  final String? title;
  final String? subtitle;
  final List<ProductModel> products;
  final String emptyMessage;

  const _CampaignBasketData({
    this.title,
    this.subtitle,
    required this.products,
    this.emptyMessage = 'Bu kampanyada ürün bulunamadı',
  });

  const _CampaignBasketData.empty({
    this.emptyMessage = 'Bu kampanyada ürün bulunamadı',
  })  : title = null,
        subtitle = null,
        products = const [];
}
