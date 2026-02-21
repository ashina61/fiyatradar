class PriceReport {
  const PriceReport({
    required this.productName,
    required this.category,
    required this.price,
    required this.storeId,
    required this.storeType,
    required this.userId,
    this.barcode,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String productName;
  final String category;
  final double price;
  final String storeId;
  final String storeType;
  final String userId;
  final String? barcode;
  final DateTime createdAt;

  factory PriceReport.fromJson(Map<String, dynamic> json) {
    return PriceReport(
      productName: json['productName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      storeId: json['storeId'] as String? ?? '',
      storeType: json['storeType'] as String? ?? 'nearby',
      userId: json['userId'] as String? ?? '',
      barcode: json['barcode'] as String?,
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'category': category,
      'price': price,
      'storeId': storeId,
      'storeType': storeType,
      'userId': userId,
      'barcode': barcode,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
