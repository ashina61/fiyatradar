import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fiyatradar/models/price_model.dart';

void main() {
  test('PriceModel parses localized string values correctly', () {
    final model = PriceModel(
      id: 'p1',
      productId: 'prod-1',
      userId: 'u1',
      branchStoreId: 's1',
      price: 0,
      reportedAt: DateTime(2024, 1, 1),
    );

    // indirectly verifies parser behavior through toMap/fromMap usage pattern
    final firestoreMap = {
      'productId': 'prod-1',
      'userId': 'u1',
      'storeId': 's1',
      'price': '1.234,50 TL',
      'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      'status': 'active',
      'currency': 'TRY',
    };

    final snap = _FakeDoc('x1', firestoreMap);
    final parsed = PriceModel.fromFirestore(snap);
    expect(parsed.price, 1234.50);
    expect(parsed.productId, 'prod-1');
    expect(parsed.branchStoreId, 's1');
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

class _FakeDoc implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDoc(this._id, this._data);

  final String _id;
  final Map<String, dynamic> _data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
