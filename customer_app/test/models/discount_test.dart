import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/discount.dart';

void main() {
  group('Discount', () {
    test('fromJson creates Discount with all fields', () {
      final json = {
        'id': 'disc-1',
        'variant_id': 'var-1',
        'type': 'percentage',
        'value': 10.0,
        'valid_from': '2026-01-01T00:00:00Z',
        'valid_until': '2026-12-31T23:59:59Z',
      };

      final discount = Discount.fromJson(json);

      expect(discount.id, 'disc-1');
      expect(discount.variantId, 'var-1');
      expect(discount.type, 'percentage');
      expect(discount.value, 10.0);
      expect(discount.validFrom.year, 2026);
      expect(discount.validUntil.month, 12);
    });

    test('fromJson handles null variantId', () {
      final json = {
        'id': 'disc-2',
        'variant_id': null,
        'type': 'fixed',
        'value': 500,
        'valid_from': '2026-04-01T00:00:00Z',
        'valid_until': '2026-04-30T23:59:59Z',
      };

      final discount = Discount.fromJson(json);

      expect(discount.variantId, isNull);
      expect(discount.value, 500.0);
      expect(discount.value, isA<double>());
    });

    test('apply calculates percentage discount correctly', () {
      final discount = Discount(
        id: 'd1',
        type: 'percentage',
        value: 10,
        validFrom: DateTime(2026, 1, 1),
        validUntil: DateTime(2026, 12, 31),
      );

      expect(discount.apply(1000), 900.0);
    });

    test('apply calculates percentage discount for 50 percent', () {
      final discount = Discount(
        id: 'd2',
        type: 'percentage',
        value: 50,
        validFrom: DateTime(2026, 1, 1),
        validUntil: DateTime(2026, 12, 31),
      );

      expect(discount.apply(2000), 1000.0);
    });

    test('apply calculates fixed discount correctly', () {
      final discount = Discount(
        id: 'd3',
        type: 'fixed',
        value: 200,
        validFrom: DateTime(2026, 1, 1),
        validUntil: DateTime(2026, 12, 31),
      );

      expect(discount.apply(1000), 800.0);
    });

    test('apply with zero value returns original price', () {
      final discount = Discount(
        id: 'd4',
        type: 'percentage',
        value: 0,
        validFrom: DateTime(2026, 1, 1),
        validUntil: DateTime(2026, 12, 31),
      );

      expect(discount.apply(1000), 1000.0);
    });
  });
}
