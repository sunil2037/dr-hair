import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
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

  testWidgets(
    'HairTestView opens questionnaire on app start even when previous test was completed (report not shown repeatedly)',
    (tester) async {
      final cubit = HairTestCubit();
      // Simulate previously completed test saved state
      cubit.selectGender('Male');
      cubit.selectPrimaryConcern('Stage 1 - Receding hairline at temples');
      await cubit.skipPhotosAndSubmit();
      expect(cubit.state.isCompleted, isTrue);

      // Dismiss report as would happen after user views it
      cubit.dismissReport();
      expect(cubit.state.isSubmitted, isFalse);

      await tester.pumpWidget(MaterialApp(home: HairTestView(cubit: cubit)));
      await tester.pumpAndSettle();

      // Should show Step 1 Questionnaire, NOT Assessment Report
      expect(find.text('Clinical Hair Analysis'), findsOneWidget);
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Assessment complete'), findsNothing);
      expect(find.text('Your Hair Loss Root Causes'), findsNothing);

      cubit.close();
    },
  );

  testWidgets(
    'Assessment Report has no bottom price bar and shows practical clinical actions',
    (tester) async {
      final cubit = HairTestCubit();
      cubit.selectGender('Male');
      cubit.selectPrimaryConcern('Stage 1 - Receding hairline at temples');
      await cubit.skipPhotosAndSubmit();
      expect(cubit.state.isSubmitted, isTrue);

      await tester.pumpWidget(MaterialApp(home: HairTestView(cubit: cubit)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Report is displayed once submitted
      expect(find.text('Assessment Report'), findsOneWidget);
      expect(find.text('Assessment complete'), findsOneWidget);
      expect(find.text('Browse Recommended Regimen'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Bottom price bar elements must NOT exist
      expect(find.text('₹1445'), findsNothing);
      expect(find.text('₹2044'), findsNothing);
      expect(find.text('Inclusive of all taxes'), findsNothing);
      expect(find.text('Buy Now'), findsNothing);
      expect(find.textContaining('GMP & ISO'), findsNothing);

      cubit.close();
    },
  );

  testWidgets(
    'Assessment Report renders cleanly without overflow on small 320x568 screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cubit = HairTestCubit();
      cubit.selectGender('Male');
      cubit.selectPrimaryConcern('Stage 1 - Receding hairline at temples');
      await cubit.skipPhotosAndSubmit();

      await tester.pumpWidget(MaterialApp(home: HairTestView(cubit: cubit)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Assessment Report'), findsOneWidget);
      expect(find.text('Dandruff'), findsOneWidget);
      expect(find.text('Nutrition'), findsOneWidget);
      expect(find.text('Lifestyle'), findsOneWidget);
      expect(tester.takeException(), isNull);

      cubit.close();
    },
  );
}
