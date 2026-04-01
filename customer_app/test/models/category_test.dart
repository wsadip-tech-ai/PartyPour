import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/category.dart';

void main() {
  group('Category', () {
    test('fromJson creates category correctly', () {
      final json = {
        'id': 'cat-1',
        'name': 'Hard Drinks',
        'slug': 'hard-drinks',
        'sort_order': 1,
        'image_url': null,
      };

      final category = Category.fromJson(json);

      expect(category.id, 'cat-1');
      expect(category.name, 'Hard Drinks');
      expect(category.slug, 'hard-drinks');
      expect(category.sortOrder, 1);
      expect(category.imageUrl, isNull);
    });
  });

  group('Subcategory', () {
    test('fromJson creates subcategory correctly', () {
      final json = {
        'id': 'sub-1',
        'category_id': 'cat-1',
        'name': 'Whiskey',
        'slug': 'whiskey',
        'sort_order': 1,
        'image_url': 'https://example.com/whiskey.png',
      };

      final subcategory = Subcategory.fromJson(json);

      expect(subcategory.id, 'sub-1');
      expect(subcategory.categoryId, 'cat-1');
      expect(subcategory.name, 'Whiskey');
      expect(subcategory.imageUrl, 'https://example.com/whiskey.png');
    });
  });
}
