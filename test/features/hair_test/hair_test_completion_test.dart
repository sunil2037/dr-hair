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
        // Set completed answers directly on cubit
        cubit.selectGender('Male');
        cubit.selectPrimaryConcern('Receding Hairline (Temples)');
        cubit.selectDuration('6 - 12 months');
        cubit.selectDandruff('Occasional flakes or itching');
        cubit.selectStressLevel('Moderate');
        cubit.selectGutHealth('Normal');
        cubit.selectFamilyHistory("Mother's side");
        cubit.setAllergyStatus('No known allergies');
        cubit.setCurrentMedicationsStatus('No');
        cubit.setPhoto('Front Hairline', 'mock_front.jpg');
        cubit.setPhoto('Crown / Top', 'mock_top.jpg');
        cubit.setPhoto('Side Profile / Temples', 'mock_side.jpg');
        await cubit.submitTest();

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Completion screen checks
        expect(find.text('Assessment complete'), findsOneWidget);
        expect(find.text('WHAT YOU SHARED'), findsOneWidget);
        expect(find.text('Receding Hairline (Temples)'), findsWidgets);
        expect(find.text('6 - 12 months'), findsOneWidget);
        expect(find.text('Moderate'), findsOneWidget);

        // Honest clinical disclaimer checks
        expect(find.text('How to use this result'), findsOneWidget);
        expect(
          find.textContaining('is not a medical diagnosis'),
          findsOneWidget,
        );
        expect(find.textContaining('/api/v1/assessment/submit'), findsNothing);

        // Reset on Done
        expect(find.text('Done'), findsOneWidget);
      },
    );
  });
}
