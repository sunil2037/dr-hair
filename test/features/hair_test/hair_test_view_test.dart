import 'package:dr_hair/core/storage/app_local_cache.dart';
import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'package:dr_hair/features/hair_test/presentation/views/hair_test_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      expect(find.text('Step 1 of 8'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Stage 1'));
      await tester.tap(find.text('Stage 1'));
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
      cubit.selectPrimaryConcern('Stage 1 - Receding hairline at temples');
      await cubit.skipPhotosAndSubmit();
      expect(cubit.state.isCompleted, isTrue);

      // Dismiss report as would happen after user views it
      cubit.dismissReport();
      expect(cubit.state.isSubmitted, isFalse);

      await tester.pumpWidget(MaterialApp(home: HairTestView(cubit: cubit)));
      await tester.pumpAndSettle();

      // Should show Step 1 Questionnaire, NOT Assessment Report
      expect(find.text('Hair & Scalp Assessment'), findsOneWidget);
      expect(find.text('Step 1 of 8'), findsOneWidget);
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
      expect(find.text('Explore recommended products'), findsOneWidget);
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
    'Assessment Report displays AI Scalp & Hair Detection with biomarkers and overlay toggle',
    (tester) async {
      final cubit = HairTestCubit();
      cubit.selectGender('Male');
      cubit.selectPrimaryConcern('Stage 1 - Receding hairline at temples');
      await cubit.skipPhotosAndSubmit();
      expect(cubit.state.isSubmitted, isTrue);

      await tester.pumpWidget(MaterialApp(home: HairTestView(cubit: cubit)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AI Scalp & Hair Detection'), findsOneWidget);
      expect(find.text('Follicular Density'), findsOneWidget);
      expect(find.text('Detected Biomarkers'), findsOneWidget);
      expect(find.text('AI DETECTION ACTIVE'), findsOneWidget);

      // Toggle AI Detection off
      await tester.tap(find.bySemanticsLabel('Toggle AI detection overlay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('RAW IMAGE'), findsOneWidget);

      cubit.close();
    },
  );

  testWidgets(
    'Assessment Report renders cleanly without overflow on small 320x568 screen',
    (tester) async {
      FlutterErrorDetails? caughtDetails;
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
        prevOnError?.call(details);
      };

      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        FlutterError.onError = prevOnError;
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
      expect(find.text('WHAT YOU SHARED'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(caughtDetails, isNull);

      cubit.close();
    },
  );

  testWidgets(
    'HairTestView displays detection badge and contextual message for hair vs non-hair images',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cubit = HairTestCubit();
      // Fast forward to step 7 (Upload Scalp Photos)
      cubit.selectPrimaryConcern('Stage 1 - Receding hairline at temples');
      cubit.selectDuration('1 - 3 years');
      cubit.selectDandruff('Occasional flakes or itching');
      cubit.selectStressLevel('Moderate');
      cubit.selectGutHealth('Normal');
      cubit.selectFamilyHistory("Mother's side");
      cubit.setAllergyStatus('No known allergies');
      cubit.setCurrentMedicationsStatus('No');

      // 1. Set a valid hair photo for Front Hairline
      await cubit.setPhoto('Front Hairline', '/tmp/front_scalp.jpg');

      // 2. Set a non-hair photo for Crown / Top
      await cubit.setPhoto('Crown / Top', '/tmp/non_hair_car.jpg');

      // Advance to step 7
      while (cubit.state.currentStep < 7) {
        cubit.nextStep();
      }
      expect(cubit.state.currentStep, 7);

      await tester.pumpWidget(MaterialApp(home: HairTestView(cubit: cubit)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step header
      expect(find.text('Upload Scalp Photos'), findsOneWidget);

      // Warning banner for flagged non-hair photo
      expect(
        find.text(
          'One or more uploaded photos do not appear to be hair or scalp photos. Please retake flagged photos.',
        ),
        findsOneWidget,
      );

      // Front Hairline (Hair detected)
      expect(find.text('Hair Detected (92%)'), findsOneWidget);
      expect(
        find.textContaining('Hair & scalp detected successfully'),
        findsOneWidget,
      );

      // Crown / Top (Non-hair image)
      expect(find.text('No Hair Detected'), findsOneWidget);
      expect(
        find.text(
          'No hair or scalp detected. Please upload a clear photo of your hair or scalp.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Retake Photo'),
        findsOneWidget,
      );

      cubit.close();
    },
  );

  testWidgets(
    'HairTestView skip button marks assessment as skipped in local cache',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AppLocalCache.instance.clearAll();

      final cubit = HairTestCubit();
      await tester.pumpWidget(MaterialApp(home: HairTestView(cubit: cubit)));
      await tester.pumpAndSettle();

      final skipFinder = find.text('Skip');
      expect(skipFinder, findsOneWidget);

      await tester.tap(skipFinder);
      await tester.pumpAndSettle();

      expect(
        AppLocalCache.instance.getBool('has_skipped_hair_test'),
        isTrue,
      );

      cubit.close();
    },
  );
}
