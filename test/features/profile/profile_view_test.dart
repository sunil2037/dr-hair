import 'package:dr_hair/core/constants/app_strings.dart';
import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_state.dart';
import 'package:dr_hair/features/hair_test/presentation/views/assessment_result_view.dart';
import 'package:dr_hair/features/profile/presentation/views/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockCompletedHairTestCubit extends HairTestCubit {
  _MockCompletedHairTestCubit() : super() {
    emit(
      const HairTestState(
        isCompleted: true,
        name: 'Sahil',
        age: '23',
        stage: 'Stage 2 - Receding Hairline',
        dandruff: 'Severe Dandruff & Flakes',
      ),
    );
  }
}

void main() {
  testWidgets('ProfileView renders patient details and available care flows', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileView()));

    // Patient info
    expect(find.text('Yashveer Soni'), findsOneWidget);
    expect(find.text('Patient ID: DRH-2024-8849'), findsOneWidget);
    expect(find.text('The tools for your hair health journey'), findsOneWidget);

    // Key drawer sections present in profile, including Assessment result
    expect(find.text('Assessment result'), findsOneWidget);
    expect(
      find.text('View your clinical hair diagnosis report'),
      findsOneWidget,
    );
    expect(find.text('Treatment plan'), findsOneWidget);
    expect(find.text('Daily routine'), findsOneWidget);
    expect(find.text('Progress journal'), findsOneWidget);
    expect(find.text('Nutrition guide'), findsOneWidget);
    expect(find.text('Care reminders'), findsOneWidget);
    expect(find.text('Clinic appointments'), findsOneWidget);
    expect(find.text('My cart'), findsOneWidget);
    expect(find.text('Orders & delivery'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('App Version ${AppStrings.appVersion}'), findsOneWidget);
  });

  testWidgets(
    'AssessmentResultView renders clinical report when assessment completed',
    (tester) async {
      final cubit = _MockCompletedHairTestCubit();
      await tester.pumpWidget(
        BlocProvider<HairTestCubit>.value(
          value: cubit,
          child: const MaterialApp(home: AssessmentResultView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assessment Report'), findsOneWidget);
      expect(find.text('Your Hair Loss Root Causes'), findsOneWidget);
      expect(find.text('Dandruff'), findsWidgets);
    },
  );

  testWidgets(
    'AssessmentResultView renders prompt and allows preview when not yet completed',
    (tester) async {
      final cubit = HairTestCubit();
      await tester.pumpWidget(
        BlocProvider<HairTestCubit>.value(
          value: cubit,
          child: const MaterialApp(home: AssessmentResultView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Assessment Result Yet'), findsOneWidget);
      expect(find.text('Take Hair Assessment'), findsOneWidget);
      expect(find.text('Preview Sample Report'), findsOneWidget);

      await tester.tap(find.text('Preview Sample Report'));
      await tester.pumpAndSettle();

      expect(find.text('Assessment Report'), findsOneWidget);
    },
  );
}
