import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/discount.dart';

void main() {
  group('Discount', () {
    test('apply percentage discount', () {
      final discount = Discount(
        id: 'd1', type: 'percentage', value: 10,
        validFrom: DateTime(2026, 1, 1), validUntil: DateTime(2026, 12, 31),
      );

      expect(discount.apply(1000), 900); // 10% off 1000
    });

    test('apply flat discount', () {
      final discount = Discount(
        id: 'd2', type: 'flat', value: 100,
        validFrom: DateTime(2026, 1, 1), validUntil: DateTime(2026, 12, 31),
      );

      expect(discount.apply(1000), 900); // 100 off 1000
    });

    test('fromJson parses correctly', () {
      final json = {
        'id': 'd1',
        'variant_id': 'v1',
        'type': 'percentage',
        'value': 15.0,
        'valid_from': '2026-01-01T00:00:00Z',
        'valid_until': '2026-12-31T23:59:59Z',
      };

      final discount = Discount.fromJson(json);

      expect(discount.type, 'percentage');
      expect(discount.value, 15.0);
      expect(discount.variantId, 'v1');
    });
  });
}
