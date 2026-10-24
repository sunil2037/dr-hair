import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'package:dr_hair/features/hair_test/presentation/views/hair_test_view.dart';

void main() {
  group('HairTest Completion & Disclaimer Tests', () {
    late HairTestCubit cubit;

    setUp(() {
      cubit = HairTestCubit();
    });

    tearDown(() {
      cubit.close();
    });

    Widget createTestApp() {
      return MaterialApp(home: HairTestView(cubit: cubit));
    }

    testWidgets(
    'renders the assessment summary and clear screening note when submitted',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Step 0: Select gender
        await tester.tap(find.text('Male'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Step 1: Primary concern
        await tester.tap(find.text('Receding Hairline (Temples)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Step 2: Duration
        await tester.tap(find.text('6 - 12 months'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Step 3: Stress level
        await tester.tap(find.text('Moderate'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        // Step 4: Add required scalp photos
        cubit.setPhoto('Front Hairline', 'mock_front.jpg');
        cubit.setPhoto('Crown / Top', 'mock_top.jpg');
        cubit.setPhoto('Side Profile / Temples', 'mock_side.jpg');
        await tester.pumpAndSettle();

        // Tap Submit Assessment
        await tester.tap(find.text('Submit Assessment'));
        await tester.pumpAndSettle();

        // Completion screen checks
        expect(find.text('Assessment complete'), findsOneWidget);
        expect(find.text('WHAT YOU SHARED'), findsOneWidget);
        expect(find.text('Receding Hairline (Temples)'), findsOneWidget);
        expect(find.text('6 - 12 months'), findsOneWidget);
        expect(find.text('Moderate'), findsOneWidget);

        // Honest clinical disclaimer checks
        expect(
          find.text('How to use this result'),
          findsOneWidget,
        );
        expect(
          find.textContaining('is not a medical diagnosis'),
          findsOneWidget,
        );
        expect(
          find.textContaining('/api/v1/assessment/submit'),
          findsNothing,
        );

        // Reset on Done
        expect(find.text('Done'), findsOneWidget);
      },
    );
  });
}
