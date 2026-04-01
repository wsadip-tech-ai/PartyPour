import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/providers/cart_provider.dart';
import 'package:customer_app/models/product.dart';

void main() {
  final product = Product(id: 'p1', subcategoryId: 's1', name: 'Tuborg', origin: 'local');
  final variant650 = Variant(id: 'v1', productId: 'p1', size: '650ml', unitPrice: 380, caseSize: 12, casePrice: 4200);
  final variant330 = Variant(id: 'v2', productId: 'p1', size: '330ml', unitPrice: 210, caseSize: 24, casePrice: 4600);

  group('CartNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('starts empty', () {
      final cart = container.read(cartProvider);
      expect(cart, isEmpty);
      expect(container.read(cartCountProvider), 0);
      expect(container.read(cartTotalProvider), 0);
    });

    test('addItem adds new item', () {
      container.read(cartProvider.notifier).addItem(product, variant650, 'unit');
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.product.name, 'Tuborg');
      expect(cart.first.variant.size, '650ml');
      expect(cart.first.quantity, 1);
    });

    test('addItem increments quantity for same variant+unitType', () {
      container.read(cartProvider.notifier).addItem(product, variant650, 'unit');
      container.read(cartProvider.notifier).addItem(product, variant650, 'unit', quantity: 3);
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.quantity, 4);
    });

    test('addItem creates separate entry for different unit type', () {
      container.read(cartProvider.notifier).addItem(product, variant650, 'unit');
      container.read(cartProvider.notifier).addItem(product, variant650, 'case');
      final cart = container.read(cartProvider);
      expect(cart.length, 2);
    });

    test('addItem creates separate entry for different variant', () {
      container.read(cartProvider.notifier).addItem(product, variant650, 'unit');
      container.read(cartProvider.notifier).addItem(product, variant330, 'unit');
      final cart = container.read(cartProvider);
      expect(cart.length, 2);
    });

    test('updateQuantity changes item quantity', () {
      container.read(cartProvider.notifier).addItem(product, variant650, 'unit');
      container.read(cartProvider.notifier).updateQuantity(0, 5);
      expect(container.read(cartProvider).first.quantity, 5);
    });

    test('updateQuantity to 0 removes item', () {
      container.read(cartProvider.notifier).addItem(product, variant650, 'unit');
      container.read(cartProvider.notifier).updateQuantity(0, 0);
      expect(container.read(cartProvider), isEmpty);
    });

    test('removeItem removes by index', () {
      container.read(cartProvider.notifier).addItem(product, variant650, 'unit');
      container.read(cartProvider.notifier).addItem(product, variant330, 'unit');
      container.read(cartProvider.notifier).removeItem(0);
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.variant.size, '330ml');
    });

    test('clear empties cart', () {
      container.read(cartProvider.notifier).addItem(product, variant650, 'unit', quantity: 3);
      container.read(cartProvider.notifier).addItem(product, variant330, 'case', quantity: 2);
      container.read(cartProvider.notifier).clear();
      expect(container.read(cartProvider), isEmpty);
    });

    test('cartTotalProvider sums all items', () {
      container.read(cartProvider.notifier).addItem(product, variant650, 'unit', quantity: 2); // 380 * 2 = 760
      container.read(cartProvider.notifier).addItem(product, variant330, 'case', quantity: 1); // 4600 * 1 = 4600
      expect(container.read(cartTotalProvider), 5360);
    });

    test('cartCountProvider counts items', () {
      container.read(cartProvider.notifier).addItem(product, variant650, 'unit');
      container.read(cartProvider.notifier).addItem(product, variant330, 'unit');
      expect(container.read(cartCountProvider), 2);
    });
  });
}
