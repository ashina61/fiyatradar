import 'package:flutter_test/flutter_test.dart';
import 'package:fiyatradar/models/price_model.dart';

void main() {
  test('PriceModel constructor keeps reportedAt as createdAt alias', () {
    final reportedAt = DateTime(2024, 1, 1);
    final model = PriceModel(
      id: 'p1',
      productId: 'prod-1',
      userId: 'u1',
      branchStoreId: 's1',
      price: 1234.50,
      reportedAt: reportedAt,
    );

    expect(model.createdAt, reportedAt);
    expect(model.branchStoreId, 's1');
    expect(model.currency, 'TRY');
  });

  test('PriceModel toFirestore contains required keys', () {
    final model = PriceModel(
      id: 'p2',
      productId: 'prod-2',
      userId: 'u2',
      branchStoreId: 's2',
      price: 99.9,
      reportedAt: DateTime(2024, 2, 1),
      isApproved: true,
      isPending: false,
    );

    final map = model.toFirestore();
    expect(map['productId'], 'prod-2');
    expect(map['price'], 99.9);
    expect(map['currency'], 'TRY');
    expect(map['status'], 'active');
    expect(map.containsKey('reportedAt'), isTrue);
  });
}
