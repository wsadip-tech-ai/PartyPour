import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/cart_item.dart';
import 'package:customer_app/models/product.dart';

void main() {
  final product = Product(id: 'p1', subcategoryId: 's1', name: 'Tuborg', origin: 'local');
  final variant = Variant(id: 'v1', productId: 'p1', size: '650ml', unitPrice: 380, caseSize: 12, casePrice: 4200);

  group('CartItem', () {
    test('unitPrice returns bottle price for unit type', () {
      final item = CartItem(product: product, variant: variant, unitType: 'unit');
      expect(item.unitPrice, 380);
    });

    test('unitPrice returns case price for case type', () {
      final item = CartItem(product: product, variant: variant, unitType: 'case');
      expect(item.unitPrice, 4200);
    });

    test('totalPrice multiplies unit price by quantity', () {
      final item = CartItem(product: product, variant: variant, unitType: 'unit', quantity: 5);
      expect(item.totalPrice, 1900); // 380 * 5
    });

    test('totalPrice for cases', () {
      final item = CartItem(product: product, variant: variant, unitType: 'case', quantity: 3);
      expect(item.totalPrice, 12600); // 4200 * 3
    });

    test('effectiveUnits calculates bottles in cases', () {
      final item = CartItem(product: product, variant: variant, unitType: 'case', quantity: 2);
      expect(item.effectiveUnits, 24); // 2 cases * 12 per case
    });

    test('effectiveUnits returns quantity for unit type', () {
      final item = CartItem(product: product, variant: variant, unitType: 'unit', quantity: 5);
      expect(item.effectiveUnits, 5);
    });
  });
}
