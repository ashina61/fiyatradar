class ProductDetailResponse {
  ProductDetailResponse({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.categories,
    required this.viewCount,
    required this.priceEntryCount,
    required this.bestPrice,
    required this.stats,
    required this.trust,
    required this.comments,
  });

  final String id;
  final String title;
  final String imageUrl;
  final List<String> categories;
  final int viewCount;
  final int priceEntryCount;
  final BestPrice bestPrice;
  final PriceStats stats;
  final TrustStats trust;
  final List<ProductComment> comments;

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) {
    return ProductDetailResponse(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      categories: ((json['categories'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      priceEntryCount: (json['priceEntryCount'] as num?)?.toInt() ?? 0,
      bestPrice: BestPrice.fromJson((json['bestPrice'] as Map<String, dynamic>?) ?? const {}),
      stats: PriceStats.fromJson((json['stats'] as Map<String, dynamic>?) ?? const {}),
      trust: TrustStats.fromJson((json['trust'] as Map<String, dynamic>?) ?? const {}),
      comments: ((json['comments'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ProductComment.fromJson)
          .toList(),
    );
  }
}

class BestPrice {
  BestPrice({
    required this.id,
    required this.price,
    required this.store,
    required this.userName,
    required this.userTier,
    required this.createdAtLabel,
    required this.storeUrl,
    required this.upVotes,
    required this.downVotes,
  });

  final String id;
  final double price;
  final String store;
  final String userName;
  final String userTier;
  final String createdAtLabel;
  final String storeUrl;
  final int upVotes;
  final int downVotes;

  factory BestPrice.fromJson(Map<String, dynamic> json) {
    return BestPrice(
      id: (json['id'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      store: (json['store'] ?? '').toString(),
      userName: (json['userName'] ?? '').toString(),
      userTier: (json['userTier'] ?? 'Elmas VIP').toString(),
      createdAtLabel: (json['createdAtLabel'] ?? '').toString(),
      storeUrl: (json['storeUrl'] ?? '').toString(),
      upVotes: (json['upVotes'] as num?)?.toInt() ?? 0,
      downVotes: (json['downVotes'] as num?)?.toInt() ?? 0,
    );
  }
}

class PriceStats {
  PriceStats({required this.lowest, required this.average, required this.highest});

  final double lowest;
  final double average;
  final double highest;

  factory PriceStats.fromJson(Map<String, dynamic> json) {
    return PriceStats(
      lowest: (json['lowest'] as num?)?.toDouble() ?? 0,
      average: (json['average'] as num?)?.toDouble() ?? 0,
      highest: (json['highest'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TrustStats {
  TrustStats({required this.scorePercent, required this.approveCount, required this.rejectCount});

  final int scorePercent;
  final int approveCount;
  final int rejectCount;

  factory TrustStats.fromJson(Map<String, dynamic> json) {
    return TrustStats(
      scorePercent: (json['scorePercent'] as num?)?.toInt() ?? 0,
      approveCount: (json['approveCount'] as num?)?.toInt() ?? 0,
      rejectCount: (json['rejectCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductComment {
  ProductComment({
    required this.id,
    required this.author,
    required this.avatarBgHex,
    required this.text,
    required this.timeAgo,
  });

  final String id;
  final String author;
  final String avatarBgHex;
  final String text;
  final String timeAgo;

  factory ProductComment.fromJson(Map<String, dynamic> json) {
    return ProductComment(
      id: (json['id'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      avatarBgHex: (json['avatarBgHex'] ?? '#C8956C').toString(),
      text: (json['text'] ?? '').toString(),
      timeAgo: (json['timeAgo'] ?? '').toString(),
    );
  }
}

class PriceHistoryPoint {
  PriceHistoryPoint({
    required this.dateLabel,
    required this.price,
    required this.reportedAt,
  });

  final String dateLabel;
  final double price;
  final DateTime reportedAt;

  factory PriceHistoryPoint.fromJson(Map<String, dynamic> json) {
    final rawReportedAt = json['reportedAt'];
    final reportedAt = rawReportedAt is String
        ? DateTime.tryParse(rawReportedAt) ?? DateTime.now()
        : DateTime.now();

    return PriceHistoryPoint(
      dateLabel: (json['dateLabel'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      reportedAt: reportedAt,
    );
  }
}
