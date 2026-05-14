import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Status lifecycle for a community-reported price.
enum PriceStatus { pending, communityVerified, disputed, rejected }

PriceStatus _statusFromString(String? v) {
  switch (v) {
    case 'community_verified':
      return PriceStatus.communityVerified;
    case 'disputed':
      return PriceStatus.disputed;
    case 'rejected':
      return PriceStatus.rejected;
    case 'pending':
    default:
      return PriceStatus.pending;
  }
}

String statusToString(PriceStatus s) {
  switch (s) {
    case PriceStatus.communityVerified:
      return 'community_verified';
    case PriceStatus.disputed:
      return 'disputed';
    case PriceStatus.rejected:
      return 'rejected';
    case PriceStatus.pending:
      return 'pending';
  }
}

/// A user-reported price entry with community verification.
///
/// Verification signals:
/// - [upvotes] / [downvotes]: raw vote counts
/// - [verifiedByCount] / [rejectedByCount]: unique-user counts (same as votes)
/// - [verificationScore]: `upvotes - downvotes` (raw)
/// - [trustWeightedScore]: trust-weighted confidence score (-1..1)
/// - [status]: derived status from trust-weighted signals
/// - [voters]: map of `userId -> 'up' | 'down'` to prevent duplicate votes
@immutable
class PriceEntry {
  final String id;
  final String store;
  final double price;
  final DateTime date;
  final String reportedBy;
  final String reportedByUid;
  final String note;
  final String? proofImageUrl;
  final String? city;
  final String? district;

  final int upvotes;
  final int downvotes;
  final int verifiedByCount;
  final int rejectedByCount;
  final double trustWeightedScore;
  final PriceStatus status;
  final DateTime? statusUpdatedAt;
  final Map<String, String> voters; // uid -> 'up' | 'down'

  /// Denormalized snapshot of the reporter's profile at submit time. Used by
  /// product detail to surface "%X güven · PRO" pills next to a contributor
  /// without an extra user-doc fetch per entry.
  final bool reporterIsPro;
  final int? reporterTrustPercent;

  const PriceEntry({
    required this.id,
    required this.store,
    required this.price,
    required this.date,
    this.reportedBy = 'Topluluk',
    this.reportedByUid = '',
    this.note = '',
    this.proofImageUrl,
    this.city,
    this.district,
    this.upvotes = 0,
    this.downvotes = 0,
    this.verifiedByCount = 0,
    this.rejectedByCount = 0,
    this.trustWeightedScore = 0.0,
    this.status = PriceStatus.pending,
    this.statusUpdatedAt,
    this.voters = const {},
    this.reporterIsPro = false,
    this.reporterTrustPercent,
  });

  int get verificationScore => upvotes - downvotes;
  int get totalVotes => upvotes + downvotes;

  /// Trust percentage 0..100 for UI display.
  int get trustPercent {
    if (totalVotes == 0) return 50;
    final norm = ((trustWeightedScore + 1) / 2) * 100;
    return norm.clamp(0, 100).round();
  }

  /// Confidence label derived from status + vote count.
  String get trustLabel {
    switch (status) {
      case PriceStatus.communityVerified:
        return 'Doğrulandı';
      case PriceStatus.disputed:
        return 'İhtilaflı';
      case PriceStatus.rejected:
        return 'Reddedildi';
      case PriceStatus.pending:
        return totalVotes == 0 ? 'Yeni' : 'İncelemede';
    }
  }

  String? voteOf(String uid) => voters[uid];
  bool isOwnedBy(String uid) => reportedByUid.isNotEmpty && reportedByUid == uid;

  Map<String, dynamic> toMap() => {
        'id': id,
        'store': store,
        'price': price,
        'date': Timestamp.fromDate(date),
        'reportedBy': reportedBy,
        'reportedByUid': reportedByUid,
        'note': note,
        if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
        if (city != null && city!.trim().isNotEmpty) 'city': city,
        if (district != null && district!.trim().isNotEmpty) 'district': district,
        'upvotes': upvotes,
        'downvotes': downvotes,
        'verifiedByCount': verifiedByCount,
        'rejectedByCount': rejectedByCount,
        'trustWeightedScore': trustWeightedScore,
        'status': statusToString(status),
        if (statusUpdatedAt != null)
          'statusUpdatedAt': Timestamp.fromDate(statusUpdatedAt!),
        'voters': voters,
        if (reporterIsPro) 'reporterIsPro': true,
        if (reporterTrustPercent != null)
          'reporterTrustPercent': reporterTrustPercent,
      };

  factory PriceEntry.fromMap(Map<String, dynamic> m) {
    final d = m['date'];
    final su = m['statusUpdatedAt'];
    final voters = <String, String>{};
    final rawVoters = m['voters'];
    if (rawVoters is Map) {
      rawVoters.forEach((k, v) {
        voters[k.toString()] = v.toString();
      });
    }
    return PriceEntry(
      id: (m['id'] ?? '') as String,
      store: (m['store'] ?? '') as String,
      price: (m['price'] as num?)?.toDouble() ?? 0,
      date: d is Timestamp ? d.toDate() : DateTime.now(),
      reportedBy: (m['reportedBy'] ?? 'Topluluk') as String,
      reportedByUid: (m['reportedByUid'] ?? '') as String,
      note: (m['note'] ?? '') as String,
      proofImageUrl: m['proofImageUrl'] as String?,
      city: (m['city'] as String?)?.trim().isNotEmpty == true
          ? (m['city'] as String)
          : null,
      district: (m['district'] as String?)?.trim().isNotEmpty == true
          ? (m['district'] as String)
          : null,
      upvotes: (m['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (m['downvotes'] as num?)?.toInt() ?? 0,
      verifiedByCount: (m['verifiedByCount'] as num?)?.toInt() ?? 0,
      rejectedByCount: (m['rejectedByCount'] as num?)?.toInt() ?? 0,
      trustWeightedScore:
          (m['trustWeightedScore'] as num?)?.toDouble() ?? 0.0,
      status: _statusFromString(m['status'] as String?),
      statusUpdatedAt: su is Timestamp ? su.toDate() : null,
      voters: voters,
      reporterIsPro: (m['reporterIsPro'] as bool?) == true,
      reporterTrustPercent: (m['reporterTrustPercent'] as num?)?.toInt(),
    );
  }

  PriceEntry copyWith({
    int? upvotes,
    int? downvotes,
    int? verifiedByCount,
    int? rejectedByCount,
    double? trustWeightedScore,
    PriceStatus? status,
    DateTime? statusUpdatedAt,
    Map<String, String>? voters,
  }) =>
      PriceEntry(
        id: id,
        store: store,
        price: price,
        date: date,
        reportedBy: reportedBy,
        reportedByUid: reportedByUid,
        note: note,
        proofImageUrl: proofImageUrl,
        city: city,
        district: district,
        upvotes: upvotes ?? this.upvotes,
        downvotes: downvotes ?? this.downvotes,
        verifiedByCount: verifiedByCount ?? this.verifiedByCount,
        rejectedByCount: rejectedByCount ?? this.rejectedByCount,
        trustWeightedScore: trustWeightedScore ?? this.trustWeightedScore,
        status: status ?? this.status,
        statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
        voters: voters ?? this.voters,
        reporterIsPro: reporterIsPro,
        reporterTrustPercent: reporterTrustPercent,
      );
}

class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String emoji;
  final String unit;
  final String? imageUrl;
  final String? imagePath;
  final String? barcode;
  final bool isActive;
  final List<PriceEntry> priceHistory;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.emoji,
    required this.unit,
    this.imageUrl,
    this.imagePath,
    this.barcode,
    this.isActive = true,
    List<PriceEntry>? priceHistory,
  }) : priceHistory = priceHistory ?? [];

  /// Entries deemed trustworthy enough to surface (not rejected).
  List<PriceEntry> get validEntries =>
      priceHistory.where((e) => e.status != PriceStatus.rejected).toList();

  double? get latestPrice {
    final valid = validEntries;
    if (valid.isEmpty) return null;
    valid.sort((a, b) => a.date.compareTo(b.date));
    return valid.last.price;
  }

  double? get previousPrice {
    final valid = validEntries;
    if (valid.length < 2) return null;
    valid.sort((a, b) => a.date.compareTo(b.date));
    return valid[valid.length - 2].price;
  }

  double? get priceChangePct {
    final l = latestPrice;
    final p = previousPrice;
    if (l == null || p == null || p == 0) return null;
    return ((l - p) / p) * 100.0;
  }

  double? get lowestPrice {
    final valid = validEntries;
    if (valid.isEmpty) return null;
    return valid.map((e) => e.price).reduce((a, b) => a < b ? a : b);
  }

  String? get cheapestStore {
    final valid = validEntries;
    if (valid.isEmpty) return null;
    final p = valid.reduce((a, b) => a.price < b.price ? a : b);
    return p.store;
  }

  /// Best-value entry: balances price, freshness, and verification trust so
  /// a cheap-but-unverified entry doesn't beat a verified one with a
  /// slightly higher price.
  ///
  /// Score = normalisedPrice * 0.55 + freshness * 0.2 + trust * 0.25
  /// (lower is better; normalisedPrice uses min-max across valid entries)
  PriceEntry? get bestValueEntry {
    final valid = validEntries;
    if (valid.isEmpty) return null;
    if (valid.length == 1) return valid.first;
    final prices = valid.map((e) => e.price).toList();
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final span = (maxP - minP).abs() < 1e-6 ? 1.0 : (maxP - minP);
    final now = DateTime.now();

    PriceEntry? best;
    double bestScore = double.infinity;
    for (final e in valid) {
      final priceNorm = (e.price - minP) / span; // 0 best, 1 worst
      final ageDays = now.difference(e.date).inHours / 24.0;
      final freshness = (ageDays / 14.0).clamp(0.0, 1.0); // 0 fresh, 1 stale
      // Trust: communityVerified best, pending neutral, disputed penalty
      final trust = switch (e.status) {
        PriceStatus.communityVerified => 0.0,
        PriceStatus.pending => 0.5,
        PriceStatus.disputed => 0.85,
        PriceStatus.rejected => 1.0,
      };
      final score =
          priceNorm * 0.55 + freshness * 0.2 + trust * 0.25;
      if (score < bestScore) {
        bestScore = score;
        best = e;
      }
    }
    return best;
  }

  /// Aggregate trust percentage across all valid entries, weighted by
  /// vote count so popular verified entries dominate.
  int get aggregateTrustPercent {
    final valid = validEntries;
    if (valid.isEmpty) return 0;
    double sum = 0;
    int weightSum = 0;
    for (final e in valid) {
      final w = 1 + e.totalVotes;
      sum += e.trustPercent * w;
      weightSum += w;
    }
    if (weightSum == 0) return 0;
    return (sum / weightSum).round().clamp(0, 100);
  }

  int get verifiedCount => priceHistory
      .where((e) => e.status == PriceStatus.communityVerified)
      .length;

  Map<String, dynamic> toMap() => {
        'name': name,
        'brand': brand,
        'category': category,
        'emoji': emoji,
        'unit': unit,
        'priceHistory': priceHistory.map((e) => e.toMap()).toList(),
      };

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final list = (m['priceHistory'] as List?) ?? const [];
    final entries = <PriceEntry>[];
    for (var i = 0; i < list.length; i++) {
      final raw = Map<String, dynamic>.from(list[i] as Map);
      // Entries may have been seeded without an id; synthesise one so that
      // voting can reference them stably.
      if ((raw['id'] as String?)?.isNotEmpty != true) {
        raw['id'] = '${d.id}_$i';
      }
      entries.add(PriceEntry.fromMap(raw));
    }
    return Product(
      id: d.id,
      name: (m['name'] ?? '') as String,
      brand: (m['brand'] ?? '') as String,
      category: (m['category'] ?? 'Tümü') as String,
      emoji: (m['emoji'] ?? '🛒') as String,
      unit: (m['unit'] ?? '') as String,
      imageUrl: m['imageUrl'] as String?,
      imagePath: m['imagePath'] as String?,
      barcode: m['barcode'] as String?,
      isActive: (m['isActive'] as bool?) ?? true,
      priceHistory: entries,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

/// One block of banner content used by the in-app blog-style page.
/// `type` is one of `heading`, `text`, `image`. The `value` semantics
/// depend on the type (heading/text → markdown-ish text, image → URL).
@immutable
class BannerContentBlock {
  final String type;
  final String value;
  const BannerContentBlock({required this.type, required this.value});

  Map<String, dynamic> toMap() => {'type': type, 'value': value};

  factory BannerContentBlock.fromMap(Map<String, dynamic> m) {
    return BannerContentBlock(
      type: (m['type'] ?? 'text') as String,
      value: (m['value'] ?? '') as String,
    );
  }
}

/// Action target for a banner tap. Either takes the user to an in-app
/// generated page made of content blocks (`page`) or routes them
/// somewhere meaningful inside the app (`route`).
class AppBanner {
  final String id;
  final String title;
  final String subtitle;
  final String actionLabel;
  final int order;
  final String? imageUrl;
  final String? imagePath;
  final String actionType; // 'page' | 'route' | 'none'
  final String actionTarget; // page id (or banner id) | route key
  final List<BannerContentBlock> contentBlocks;
  const AppBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.order,
    this.imageUrl,
    this.imagePath,
    this.actionType = 'page',
    this.actionTarget = '',
    this.contentBlocks = const [],
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory AppBanner.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final rawBlocks = (m['contentBlocks'] as List?) ?? const [];
    final blocks = <BannerContentBlock>[];
    for (final b in rawBlocks) {
      if (b is Map) {
        blocks.add(
          BannerContentBlock.fromMap(Map<String, dynamic>.from(b)),
        );
      }
    }
    final url = (m['imageUrl'] as String?)?.trim();
    final path = (m['imagePath'] as String?)?.trim();
    return AppBanner(
      id: d.id,
      title: (m['title'] ?? '') as String,
      subtitle: (m['subtitle'] ?? '') as String,
      actionLabel: (m['actionLabel'] ?? 'Keşfet') as String,
      order: (m['order'] as num?)?.toInt() ?? 0,
      imageUrl: (url != null && url.isNotEmpty) ? url : null,
      imagePath: (path != null && path.isNotEmpty) ? path : null,
      actionType: (m['actionType'] as String?)?.trim().isNotEmpty == true
          ? (m['actionType'] as String)
          : 'page',
      actionTarget: (m['actionTarget'] as String?) ?? '',
      contentBlocks: blocks,
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  /// Cloud Function tarafından yazılan tip etiketi. Bilinenler:
  ///   'price_drop'            — legacy products.priceHistory drop
  ///   'regional_price_drop'   — yeni priceGroups omurgası drop
  ///   'product_request_*'     — admin onay/red bildirimi
  final String? type;
  final String? productId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.type,
    this.productId,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final created = m['createdAt'];
    final read = m['readAt'];
    return AppNotification(
      id: d.id,
      title: (m['title'] ?? '') as String,
      body: (m['body'] ?? '') as String,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      readAt: read is Timestamp ? read.toDate() : null,
      type: (m['type'] as String?)?.trim().isNotEmpty == true
          ? (m['type'] as String)
          : null,
      productId: (m['productId'] as String?)?.trim().isNotEmpty == true
          ? (m['productId'] as String)
          : null,
    );
  }
}

/// Community-sourced product suggestion awaiting admin approval.
/// Stored in the `product_requests` collection.
class ProductRequest {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String unit;
  final String emoji;
  final String barcode;
  final String note;
  final String requestedByUid;
  final String requestedByName;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? rejectionReason;
  final String? approvedProductId;
  final DateTime createdAt;
  final DateTime? decidedAt;

  const ProductRequest({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.unit,
    required this.emoji,
    required this.barcode,
    required this.note,
    required this.requestedByUid,
    required this.requestedByName,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.approvedProductId,
    this.decidedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory ProductRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final created = m['createdAt'];
    final decided = m['decidedAt'];
    return ProductRequest(
      id: d.id,
      name: (m['name'] ?? '') as String,
      brand: (m['brand'] ?? '') as String,
      category: (m['category'] ?? 'Tümü') as String,
      unit: (m['unit'] ?? '') as String,
      emoji: (m['emoji'] ?? '🛒') as String,
      barcode: (m['barcode'] ?? '') as String,
      note: (m['note'] ?? '') as String,
      requestedByUid: (m['requestedByUid'] ?? '') as String,
      requestedByName: (m['requestedByName'] ?? 'Topluluk') as String,
      status: (m['status'] ?? 'pending') as String,
      rejectionReason: m['rejectionReason'] as String?,
      approvedProductId: m['approvedProductId'] as String?,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      decidedAt: decided is Timestamp ? decided.toDate() : null,
    );
  }
}

class ProductAlert {
  final String productId;
  final double targetPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductAlert({
    required this.productId,
    required this.targetPrice,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductAlert.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final created = m['createdAt'];
    final updated = m['updatedAt'];
    return ProductAlert(
      productId: d.id,
      targetPrice: (m['targetPrice'] as num?)?.toDouble() ?? 0,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }
}
