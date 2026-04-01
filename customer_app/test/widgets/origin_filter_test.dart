import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/widgets/origin_filter.dart';

void main() {
  group('OriginFilter', () {
    testWidgets('displays All, Local, Imported options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OriginFilter(selectedOrigin: null, onChanged: (_) {}),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.text('Imported'), findsOneWidget);
    });

    testWidgets('calls onChanged with selected value', (tester) async {
      String? selectedValue = 'not_called';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OriginFilter(
              selectedOrigin: null,
              onChanged: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Local'));
      expect(selectedValue, 'local');
    });
  });
}
