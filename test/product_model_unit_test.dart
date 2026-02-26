import 'package:flutter_test/flutter_test.dart';
import 'package:fiyatradar/models/product_model.dart';

void main() {
  test('ProductModel.toFirestore writes category fallback', () {
    final model = ProductModel(
      id: 'p1',
      name: 'Süt',
      brand: 'X',
      categories: const ['Süt Ürünleri', 'Gıda'],
      createdAt: DateTime(2024, 1, 1),
    );

    final map = model.toFirestore();
    expect(map['name'], 'Süt');
    expect(map['brand'], 'X');
    expect(map['category'], 'Süt Ürünleri');
    expect((map['categories'] as List).length, 2);
  });

  test('ProductModel.copyWith preserves untouched fields', () {
    final model = ProductModel(
      id: 'p1',
      name: 'Süt',
      brand: 'X',
      categories: const ['Süt Ürünleri'],
      viewCount: 1,
      createdAt: DateTime(2024, 1, 1),
    );

    final updated = model.copyWith(name: 'Yoğurt');
    expect(updated.name, 'Yoğurt');
    expect(updated.brand, 'X');
    expect(updated.viewCount, 1);
  });
}
