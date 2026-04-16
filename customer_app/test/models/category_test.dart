import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/category.dart';

void main() {
  group('Category', () {
    test('fromJson creates Category with all fields', () {
      final json = {
        'id': 'cat-1',
        'name': 'Spirits',
        'slug': 'spirits',
        'sort_order': 1,
        'image_url': 'https://example.com/spirits.png',
      };

      final category = Category.fromJson(json);

      expect(category.id, 'cat-1');
      expect(category.name, 'Spirits');
      expect(category.slug, 'spirits');
      expect(category.sortOrder, 1);
      expect(category.imageUrl, 'https://example.com/spirits.png');
    });

    test('fromJson handles null imageUrl', () {
      final json = {
        'id': 'cat-2',
        'name': 'Beer',
        'slug': 'beer',
        'sort_order': 2,
        'image_url': null,
      };

      final category = Category.fromJson(json);

      expect(category.id, 'cat-2');
      expect(category.imageUrl, isNull);
    });
  });

  group('Subcategory', () {
    test('fromJson creates Subcategory with all fields', () {
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
      expect(subcategory.slug, 'whiskey');
      expect(subcategory.sortOrder, 1);
      expect(subcategory.imageUrl, 'https://example.com/whiskey.png');
    });

    test('fromJson handles null imageUrl', () {
      final json = {
        'id': 'sub-2',
        'category_id': 'cat-1',
        'name': 'Vodka',
        'slug': 'vodka',
        'sort_order': 2,
        'image_url': null,
      };

      final subcategory = Subcategory.fromJson(json);

      expect(subcategory.imageUrl, isNull);
    });
  });
}
