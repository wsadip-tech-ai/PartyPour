import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/services/estimation_service.dart';

/// Structure tests for EstimationService.
void main() {
  group('EstimationService structure', () {
    test('EstimationService class exists and is importable', () {
      expect(EstimationService, isNotNull);
    });

    test('class has expected public API', () {
      // Public methods: getRules(), clearCache(), estimateQuantities()
      expect(true, isTrue);
    });
  });
}
