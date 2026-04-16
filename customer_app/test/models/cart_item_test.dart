import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/cart_item.dart';
import 'package:customer_app/models/product.dart';

void main() {
  final testProduct = Product(
    id: 'p1',
    subcategoryId: 's1',
    name: 'Test Whiskey',
    origin: 'Nepal',
  );

  final bottleVariant = Variant(
    id: 'v1',
    productId: 'p1',
    size: '750ml',
    unitPrice: 1500,
    caseSize: 12,
    casePrice: 15000,
  );

  final noCaseVariant = Variant(
    id: 'v2',
    productId: 'p1',
    size: '375ml',
    unitPrice: 800,
  );

  group('CartItem', () {
    test('unitPrice returns bottle price for bottle unit type', () {
      final item = CartItem(
        product: testProduct,
        variant: bottleVariant,
        unitType: 'bottle',
        quantity: 5,
      );

      expect(item.unitPrice, 1500.0);
    });

    test('unitPrice returns case price for case unit type', () {
      final item = CartItem(
        product: testProduct,
        variant: bottleVariant,
        unitType: 'case',
        quantity: 2,
      );

      expect(item.unitPrice, 15000.0);
    });

    test('unitPrice falls back to unit price when no case price', () {
      final item = CartItem(
        product: testProduct,
        variant: noCaseVariant,
        unitType: 'case',
        quantity: 1,
      );

      expect(item.unitPrice, 800.0);
    });

    test('totalPrice calculates correctly for bottles', () {
      final item = CartItem(
        product: testProduct,
        variant: bottleVariant,
        unitType: 'bottle',
        quantity: 3,
      );

      expect(item.totalPrice, 4500.0);
    });

    test('totalPrice calculates correctly for cases', () {
      final item = CartItem(
        product: testProduct,
        variant: bottleVariant,
        unitType: 'case',
        quantity: 2,
      );

      expect(item.totalPrice, 30000.0);
    });

    test('effectiveUnits multiplies by case size for case orders', () {
      final item = CartItem(
        product: testProduct,
        variant: bottleVariant,
        unitType: 'case',
        quantity: 2,
      );

      // 2 cases * 12 per case = 24 units
      expect(item.effectiveUnits, 24);
    });

    test('effectiveUnits equals quantity for bottle orders', () {
      final item = CartItem(
        product: testProduct,
        variant: bottleVariant,
        unitType: 'bottle',
        quantity: 5,
      );

      expect(item.effectiveUnits, 5);
    });

    test('effectiveUnits equals quantity when no case size', () {
      final item = CartItem(
        product: testProduct,
        variant: noCaseVariant,
        unitType: 'case',
        quantity: 3,
      );

      expect(item.effectiveUnits, 3);
    });

    test('default quantity is 1', () {
      final item = CartItem(
        product: testProduct,
        variant: bottleVariant,
        unitType: 'bottle',
      );

      expect(item.quantity, 1);
    });

    test('quantity is mutable', () {
      final item = CartItem(
        product: testProduct,
        variant: bottleVariant,
        unitType: 'bottle',
        quantity: 1,
      );

      item.quantity = 10;
      expect(item.quantity, 10);
      expect(item.totalPrice, 15000.0);
    });
  });
}
