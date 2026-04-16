import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/estimation_rule.dart';

void main() {
  group('EstimationRule', () {
    test('fromJson creates EstimationRule with all fields', () {
      final json = {
        'id': 'rule-1',
        'subcategory_slug': 'whiskey',
        'label': 'Whiskey',
        'icon_name': 'local_bar',
        'drinks_per_guest': 2.5,
        'servings_per_bottle': 16.0,
        'event_multipliers': {'wedding': 1.2, 'party': 1.0, 'corporate': 0.8},
        'children_factor': 0.0,
        'sort_order': 1,
      };

      final rule = EstimationRule.fromJson(json);

      expect(rule.id, 'rule-1');
      expect(rule.subcategorySlug, 'whiskey');
      expect(rule.label, 'Whiskey');
      expect(rule.iconName, 'local_bar');
      expect(rule.drinksPerGuest, 2.5);
      expect(rule.servingsPerBottle, 16.0);
      expect(rule.eventMultipliers, hasLength(3));
      expect(rule.eventMultipliers['wedding'], 1.2);
      expect(rule.childrenFactor, 0.0);
      expect(rule.sortOrder, 1);
    });

    test('fromJson handles null iconName', () {
      final json = {
        'id': 'rule-2',
        'subcategory_slug': 'beer',
        'label': 'Beer',
        'icon_name': null,
        'drinks_per_guest': 3.0,
        'servings_per_bottle': 1.0,
        'event_multipliers': <String, dynamic>{},
        'children_factor': 0.0,
        'sort_order': 2,
      };

      final rule = EstimationRule.fromJson(json);

      expect(rule.iconName, isNull);
    });

    test('fromJson handles missing event_multipliers', () {
      final json = {
        'id': 'rule-3',
        'subcategory_slug': 'wine',
        'label': 'Wine',
        'drinks_per_guest': 2.0,
        'servings_per_bottle': 5.0,
        'children_factor': 0.0,
        'sort_order': 3,
      };

      final rule = EstimationRule.fromJson(json);

      expect(rule.eventMultipliers, isEmpty);
    });

    test('fromJson handles int values via num.toDouble()', () {
      final json = {
        'id': 'rule-4',
        'subcategory_slug': 'vodka',
        'label': 'Vodka',
        'drinks_per_guest': 2,
        'servings_per_bottle': 16,
        'event_multipliers': {'party': 1},
        'children_factor': 0,
        'sort_order': 4,
      };

      final rule = EstimationRule.fromJson(json);

      expect(rule.drinksPerGuest, 2.0);
      expect(rule.drinksPerGuest, isA<double>());
      expect(rule.servingsPerBottle, 16.0);
      expect(rule.eventMultipliers['party'], 1.0);
    });

    test('unit returns cases for beer', () {
      final rule = EstimationRule(
        id: 'r1',
        subcategorySlug: 'beer-bottle-can',
        label: 'Beer',
        drinksPerGuest: 3,
        servingsPerBottle: 1,
        eventMultipliers: {},
        childrenFactor: 0,
        sortOrder: 1,
      );

      expect(rule.unit, 'cases');
    });

    test('unit returns litres for non-beer', () {
      final rule = EstimationRule(
        id: 'r2',
        subcategorySlug: 'whiskey',
        label: 'Whiskey',
        drinksPerGuest: 2,
        servingsPerBottle: 16,
        eventMultipliers: {},
        childrenFactor: 0,
        sortOrder: 1,
      );

      expect(rule.unit, 'litres');
    });

    test('estimateBottles basic calculation', () {
      final rule = EstimationRule(
        id: 'r1',
        subcategorySlug: 'whiskey',
        label: 'Whiskey',
        drinksPerGuest: 2.0,
        servingsPerBottle: 16.0,
        eventMultipliers: {'wedding': 1.0},
        childrenFactor: 0.0,
        sortOrder: 1,
      );

      // 100 guests, 0 children, wedding multiplier 1.0
      // effectiveGuests = (100-0) + (0*0) = 100
      // totalServings = 100 * 2.0 * 1.0 = 200
      // bottles = ceil(200/16) = 13
      final result = rule.estimateBottles(
        totalPax: 100,
        children: 0,
        eventType: 'wedding',
      );

      expect(result, 13);
    });

    test('estimateBottles accounts for children factor', () {
      final rule = EstimationRule(
        id: 'r2',
        subcategorySlug: 'wine',
        label: 'Wine',
        drinksPerGuest: 2.0,
        servingsPerBottle: 5.0,
        eventMultipliers: {'party': 1.0},
        childrenFactor: 0.5,
        sortOrder: 1,
      );

      // 100 total, 20 children
      // effectiveGuests = (100-20) + (20*0.5) = 80 + 10 = 90
      // totalServings = 90 * 2.0 * 1.0 = 180
      // bottles = ceil(180/5) = 36
      final result = rule.estimateBottles(
        totalPax: 100,
        children: 20,
        eventType: 'party',
      );

      expect(result, 36);
    });

    test('estimateBottles applies event multiplier', () {
      final rule = EstimationRule(
        id: 'r3',
        subcategorySlug: 'beer',
        label: 'Beer',
        drinksPerGuest: 3.0,
        servingsPerBottle: 1.0,
        eventMultipliers: {'corporate': 0.5},
        childrenFactor: 0.0,
        sortOrder: 1,
      );

      // 50 guests, 0 children, corporate multiplier 0.5
      // totalServings = 50 * 3.0 * 0.5 = 75
      // bottles = ceil(75/1) = 75
      final result = rule.estimateBottles(
        totalPax: 50,
        children: 0,
        eventType: 'corporate',
      );

      expect(result, 75);
    });

    test('estimateBottles uses default multiplier for unknown event', () {
      final rule = EstimationRule(
        id: 'r4',
        subcategorySlug: 'rum',
        label: 'Rum',
        drinksPerGuest: 2.0,
        servingsPerBottle: 16.0,
        eventMultipliers: {'wedding': 1.5},
        childrenFactor: 0.0,
        sortOrder: 1,
      );

      // Unknown event -> multiplier defaults to 1.0
      // 50 guests, totalServings = 50 * 2.0 * 1.0 = 100
      // bottles = ceil(100/16) = 7
      final result = rule.estimateBottles(
        totalPax: 50,
        children: 0,
        eventType: 'unknown_event',
      );

      expect(result, 7);
    });

    test('estimateBottles returns 0 for 0 guests', () {
      final rule = EstimationRule(
        id: 'r5',
        subcategorySlug: 'whiskey',
        label: 'Whiskey',
        drinksPerGuest: 2.0,
        servingsPerBottle: 16.0,
        eventMultipliers: {'party': 1.0},
        childrenFactor: 0.0,
        sortOrder: 1,
      );

      final result = rule.estimateBottles(
        totalPax: 0,
        children: 0,
        eventType: 'party',
      );

      expect(result, 0);
    });
  });
}
