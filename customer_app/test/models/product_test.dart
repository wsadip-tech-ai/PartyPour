import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/product.dart';

void main() {
  group('Product', () {
    test('fromJson creates product correctly', () {
      final json = {
        'id': 'test-id',
        'subcategory_id': 'sub-id',
        'name': 'Khukuri',
        'origin': 'local',
        'description': 'Popular Nepali whiskey',
        'image_url': null,
        'tags': ['popular'],
        'variants': [
          {
            'id': 'v1',
            'product_id': 'test-id',
            'size': '750ml',
            'unit_price': 550.0,
            'case_size': 12,
            'case_price': 6000.0,
            'mrp': 580.0,
          }
        ],
      };

      final product = Product.fromJson(json);

      expect(product.id, 'test-id');
      expect(product.name, 'Khukuri');
      expect(product.origin, 'local');
      expect(product.tags, ['popular']);
      expect(product.variants.length, 1);
      expect(product.variants.first.size, '750ml');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'test-id',
        'subcategory_id': 'sub-id',
        'name': 'Test',
        'origin': 'imported',
        'description': null,
        'image_url': null,
        'tags': null,
        'variants': null,
      };

      final product = Product.fromJson(json);

      expect(product.description, isNull);
      expect(product.tags, isEmpty);
      expect(product.variants, isEmpty);
    });

    test('lowestPrice returns cheapest variant', () {
      final product = Product(
        id: '1', subcategoryId: 's1', name: 'Test', origin: 'local',
        variants: [
          Variant(id: 'v1', productId: '1', size: '750ml', unitPrice: 550),
          Variant(id: 'v2', productId: '1', size: '375ml', unitPrice: 290),
        ],
      );

      expect(product.lowestPrice, 290);
    });

    test('lowestPrice returns 0 when no variants', () {
      final product = Product(id: '1', subcategoryId: 's1', name: 'Test', origin: 'local');
      expect(product.lowestPrice, 0);
    });
  });

  group('Variant', () {
    test('fromJson creates variant correctly', () {
      final json = {
        'id': 'v1',
        'product_id': 'p1',
        'size': '750ml',
        'unit_price': 550.0,
        'case_size': 12,
        'case_price': 6000.0,
        'mrp': 580.0,
      };

      final variant = Variant.fromJson(json);

      expect(variant.size, '750ml');
      expect(variant.unitPrice, 550.0);
      expect(variant.caseSize, 12);
      expect(variant.casePrice, 6000.0);
    });

    test('savingsPerUnit calculates correctly', () {
      final variant = Variant(
        id: 'v1', productId: 'p1', size: '750ml',
        unitPrice: 550, caseSize: 12, casePrice: 6000,
      );

      // 550 - (6000/12) = 550 - 500 = 50
      expect(variant.savingsPerUnit, 50);
    });

    test('savingsPerUnit returns 0 when no case pricing', () {
      final variant = Variant(id: 'v1', productId: 'p1', size: '750ml', unitPrice: 550);
      expect(variant.savingsPerUnit, 0);
    });
  });
}
