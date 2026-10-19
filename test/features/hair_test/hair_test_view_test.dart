import 'package:dr_hair/features/hair_test/presentation/views/hair_test_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'HairTestView navigation buttons smoothly animate and allow step transitions',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HairTestView()));

      // Initial step 0: Continue is present, Back button is not displayed
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Back'), findsNothing);

      // The first question is required before the assessment can continue.
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 5'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Male'));
      await tester.tap(find.text('Male'));
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Now on step 2: Back button should be visible
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap Back to return to step 0
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Back on step 0: Back button is smoothly hidden again
      expect(find.text('Back'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);
    },
  );
}
