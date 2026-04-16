import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/widgets/product_card.dart';
import 'package:customer_app/models/product.dart';

void main() {
  group('ProductCard', () {
    testWidgets('displays product name and price', (tester) async {
      final product = Product(
        id: 'p1', subcategoryId: 's1', name: 'Khukuri', origin: 'local',
        variants: [Variant(id: 'v1', productId: 'p1', size: '750ml', unitPrice: 550)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300, height: 300,
              child: ProductCard(product: product, onTap: () {}),
            ),
          ),
        ),
      );

      expect(find.text('Khukuri'), findsOneWidget);
      expect(find.text('NPR 550'), findsOneWidget);
      expect(find.text('Domestic'), findsOneWidget);
    });

    testWidgets('shows Imported badge for imported products', (tester) async {
      final product = Product(
        id: 'p2', subcategoryId: 's1', name: 'Absolut', origin: 'imported',
        variants: [Variant(id: 'v2', productId: 'p2', size: '750ml', unitPrice: 3500)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300, height: 300,
              child: ProductCard(product: product, onTap: () {}),
            ),
          ),
        ),
      );

      expect(find.text('Imported'), findsOneWidget);
      expect(find.text('NPR 3500'), findsOneWidget);
    });

    testWidgets('calls onTap when pressed', (tester) async {
      bool tapped = false;
      final product = Product(
        id: 'p1', subcategoryId: 's1', name: 'Test', origin: 'local',
        variants: [Variant(id: 'v1', productId: 'p1', size: '750ml', unitPrice: 100)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300, height: 300,
              child: ProductCard(product: product, onTap: () => tapped = true),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProductCard));
      expect(tapped, isTrue);
    });
  });
}
