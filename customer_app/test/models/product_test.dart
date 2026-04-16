import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/product.dart';

void main() {
  group('Variant', () {
    test('fromJson creates Variant with all fields', () {
      final json = {
        'id': 'var-1',
        'product_id': 'prod-1',
        'size': '750ml',
        'unit_price': 1500.0,
        'case_size': 12,
        'case_price': 15000.0,
        'mrp': 1600.0,
      };

      final variant = Variant.fromJson(json);

      expect(variant.id, 'var-1');
      expect(variant.productId, 'prod-1');
      expect(variant.size, '750ml');
      expect(variant.unitPrice, 1500.0);
      expect(variant.caseSize, 12);
      expect(variant.casePrice, 15000.0);
      expect(variant.mrp, 1600.0);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'var-2',
        'product_id': 'prod-1',
        'size': '330ml',
        'unit_price': 300,
        'case_size': null,
        'case_price': null,
        'mrp': null,
      };

      final variant = Variant.fromJson(json);

      expect(variant.caseSize, isNull);
      expect(variant.casePrice, isNull);
      expect(variant.mrp, isNull);
    });

    test('fromJson handles int unit_price via num.toDouble()', () {
      final json = {
        'id': 'var-3',
        'product_id': 'prod-1',
        'size': '1L',
        'unit_price': 2000,
      };

      final variant = Variant.fromJson(json);

      expect(variant.unitPrice, 2000.0);
      expect(variant.unitPrice, isA<double>());
    });

    test('isCaseOnly returns true for case sizes', () {
      final variant = Variant(
        id: 'v1',
        productId: 'p1',
        size: 'Case of 24',
        unitPrice: 5000,
      );

      expect(variant.isCaseOnly, isTrue);
    });

    test('isCaseOnly returns false for bottle sizes', () {
      final variant = Variant(
        id: 'v1',
        productId: 'p1',
        size: '750ml',
        unitPrice: 1500,
      );

      expect(variant.isCaseOnly, isFalse);
    });

    test('savingsPerUnit calculates correctly', () {
      final variant = Variant(
        id: 'v1',
        productId: 'p1',
        size: '750ml',
        unitPrice: 1500,
        caseSize: 12,
        casePrice: 15000,
      );

      // 1500 - (15000/12) = 1500 - 1250 = 250
      expect(variant.savingsPerUnit, 250.0);
    });

    test('savingsPerUnit returns 0 when no case pricing', () {
      final variant = Variant(
        id: 'v1',
        productId: 'p1',
        size: '750ml',
        unitPrice: 1500,
      );

      expect(variant.savingsPerUnit, 0);
    });

    test('savingsPerUnit returns 0 for case-only variants', () {
      final variant = Variant(
        id: 'v1',
        productId: 'p1',
        size: 'Case of 24',
        unitPrice: 5000,
        caseSize: 24,
        casePrice: 5000,
      );

      expect(variant.savingsPerUnit, 0);
    });

    test('toJson roundtrip preserves data', () {
      final original = Variant(
        id: 'v1',
        productId: 'p1',
        size: '750ml',
        unitPrice: 1500.0,
        caseSize: 12,
        casePrice: 15000.0,
        mrp: 1600.0,
      );

      final json = original.toJson();
      final restored = Variant.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.productId, original.productId);
      expect(restored.size, original.size);
      expect(restored.unitPrice, original.unitPrice);
      expect(restored.caseSize, original.caseSize);
      expect(restored.casePrice, original.casePrice);
      expect(restored.mrp, original.mrp);
    });
  });

  group('Product', () {
    test('fromJson creates Product with variants', () {
      final json = {
        'id': 'prod-1',
        'subcategory_id': 'sub-1',
        'name': 'Johnnie Walker Black',
        'origin': 'Scotland',
        'description': 'Premium blended scotch',
        'image_url': 'https://example.com/jw.png',
        'tags': ['premium', 'scotch'],
        'variants': [
          {
            'id': 'var-1',
            'product_id': 'prod-1',
            'size': '750ml',
            'unit_price': 4500.0,
          },
          {
            'id': 'var-2',
            'product_id': 'prod-1',
            'size': '1L',
            'unit_price': 5500.0,
          },
        ],
      };

      final product = Product.fromJson(json);

      expect(product.id, 'prod-1');
      expect(product.subcategoryId, 'sub-1');
      expect(product.name, 'Johnnie Walker Black');
      expect(product.origin, 'Scotland');
      expect(product.description, 'Premium blended scotch');
      expect(product.imageUrl, 'https://example.com/jw.png');
      expect(product.tags, ['premium', 'scotch']);
      expect(product.variants, hasLength(2));
      expect(product.variants[0].size, '750ml');
      expect(product.variants[1].size, '1L');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'prod-2',
        'subcategory_id': 'sub-1',
        'name': 'Local Whiskey',
        'origin': 'Nepal',
      };

      final product = Product.fromJson(json);

      expect(product.description, isNull);
      expect(product.imageUrl, isNull);
      expect(product.tags, isEmpty);
      expect(product.variants, isEmpty);
    });

    test('lowestPrice returns cheapest variant price', () {
      final product = Product(
        id: 'p1',
        subcategoryId: 's1',
        name: 'Test',
        origin: 'Nepal',
        variants: [
          Variant(id: 'v1', productId: 'p1', size: '750ml', unitPrice: 2000),
          Variant(id: 'v2', productId: 'p1', size: '375ml', unitPrice: 1200),
          Variant(id: 'v3', productId: 'p1', size: '1L', unitPrice: 2500),
        ],
      );

      expect(product.lowestPrice, 1200.0);
    });

    test('lowestPrice returns 0 when no variants', () {
      final product = Product(
        id: 'p1',
        subcategoryId: 's1',
        name: 'Test',
        origin: 'Nepal',
      );

      expect(product.lowestPrice, 0);
    });

    test('toJson roundtrip preserves data', () {
      final original = Product(
        id: 'p1',
        subcategoryId: 's1',
        name: 'Test Product',
        origin: 'Nepal',
        description: 'A test',
        tags: ['tag1'],
        variants: [
          Variant(id: 'v1', productId: 'p1', size: '750ml', unitPrice: 1500),
        ],
      );

      final json = original.toJson();
      final restored = Product.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.origin, original.origin);
      expect(restored.description, original.description);
      expect(restored.tags, original.tags);
      expect(restored.variants, hasLength(1));
      expect(restored.variants[0].unitPrice, 1500.0);
    });
  });
}
