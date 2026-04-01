import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/services/planner_service.dart';
import 'package:customer_app/models/product.dart';

void main() {
  late PlannerService service;
  late List<Product> products;

  setUp(() {
    service = PlannerService();
    products = [
      Product(
        id: 'p1', subcategoryId: 's1', name: 'Khukuri', origin: 'local',
        tags: ['popular'],
        variants: [Variant(id: 'v1', productId: 'p1', size: '750ml', unitPrice: 550, caseSize: 12, casePrice: 6000)],
      ),
      Product(
        id: 'p2', subcategoryId: 's2', name: 'Gorkha', origin: 'local',
        tags: ['popular'],
        variants: [Variant(id: 'v2', productId: 'p2', size: '650ml', unitPrice: 400, caseSize: 12, casePrice: 4400)],
      ),
      Product(
        id: 'p3', subcategoryId: 's3', name: 'Coca-Cola', origin: 'imported',
        tags: ['popular'],
        variants: [Variant(id: 'v3', productId: 'p3', size: '2.25L', unitPrice: 180, caseSize: 6, casePrice: 1000)],
      ),
      Product(
        id: 'p4', subcategoryId: 's4', name: 'Aqua Nepal', origin: 'local',
        variants: [Variant(id: 'v4', productId: 'p4', size: '1L', unitPrice: 30, caseSize: 12, casePrice: 320)],
      ),
      Product(
        id: 'p5', subcategoryId: 's5', name: 'Ice', origin: 'local',
        variants: [Variant(id: 'v5', productId: 'p5', size: '5kg bag', unitPrice: 150)],
      ),
    ];
  });

  group('PlannerService', () {
    test('returns suggestions for a wedding', () {
      final suggestions = service.estimateBeverages(
        guestCount: 100,
        eventType: 'wedding',
        availableProducts: products,
      );

      expect(suggestions, isNotEmpty);
    });

    test('returns empty when no products match', () {
      final suggestions = service.estimateBeverages(
        guestCount: 100,
        eventType: 'wedding',
        availableProducts: [],
      );

      expect(suggestions, isEmpty);
    });

    test('suggestions scale with guest count', () {
      final small = service.estimateBeverages(guestCount: 50, eventType: 'wedding', availableProducts: products);
      final large = service.estimateBeverages(guestCount: 200, eventType: 'wedding', availableProducts: products);

      // Find matching suggestion types and compare quantities
      for (final smallSuggestion in small) {
        final largeSuggestion = large.where((s) => s.variantId == smallSuggestion.variantId).firstOrNull;
        if (largeSuggestion != null) {
          expect(largeSuggestion.quantity, greaterThan(smallSuggestion.quantity));
        }
      }
    });

    test('corporate events suggest less alcohol', () {
      final wedding = service.estimateBeverages(guestCount: 100, eventType: 'wedding', availableProducts: products);
      final corporate = service.estimateBeverages(guestCount: 100, eventType: 'corporate', availableProducts: products);

      // Find whiskey suggestions (750ml) — corporate should have fewer
      final weddingWhiskey = wedding.where((s) => s.variantId == 'v1').firstOrNull;
      final corporateWhiskey = corporate.where((s) => s.variantId == 'v1').firstOrNull;

      if (weddingWhiskey != null && corporateWhiskey != null) {
        expect(corporateWhiskey.quantity, lessThan(weddingWhiskey.quantity));
      }
    });

    test('all suggestions have valid data', () {
      final suggestions = service.estimateBeverages(guestCount: 100, eventType: 'wedding', availableProducts: products);

      for (final s in suggestions) {
        expect(s.quantity, greaterThan(0));
        expect(s.unitType, isIn(['unit', 'case']));
        expect(s.reason, isNotEmpty);
        expect(s.product.name, isNotEmpty);
      }
    });
  });
}
