import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'package:dr_hair/features/hair_test/presentation/views/assessment_report_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssessmentReportView Doctor Review Flow', () {
    testWidgets(
      'renders expert review notice and 3-step timeline when report is submitted',
      (tester) async {
        final cubit = HairTestCubit();
        cubit.emit(
          cubit.state.copyWith(
            isCompleted: true,
            isSubmitted: true,
            assessmentStatus: 'submitted',
            name: 'Rahul Sharma',
            age: '29',
            stage: 'Stage 2 - Receding Hairline',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: cubit,
              child: AssessmentReportView(state: cubit.state),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Reassurance card
        expect(
          find.text('Report Sent to Expert Clinic Team'),
          findsOneWidget,
        );
        expect(
          find.text('Assigned to Dr. Jai Bansal'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Your report has been sent to our expert clinic team (Dr. Jai Bansal)'),
          findsOneWidget,
        );

        // 3-step timeline
        expect(find.text('Intake Sent'), findsOneWidget);
        expect(find.text('Doctor Review'), findsOneWidget);
        expect(find.text('Regimen Prescribed'), findsOneWidget);

        cubit.close();
      },
    );

    testWidgets(
      'renders Stage 2 Care Protocol and Add Complete Kit to Cart button',
      (tester) async {
        final cubit = HairTestCubit();
        cubit.emit(
          cubit.state.copyWith(
            isCompleted: true,
            isSubmitted: true,
            assessmentStatus: 'submitted',
            name: 'Aarav Gupta',
            age: '26',
            stage: 'Stage 2 - Receding Hairline',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: cubit,
              child: AssessmentReportView(state: cubit.state),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('Stage 2 Care Protocol (Targeted Regrowth & DHT Defense)'),
          findsOneWidget,
        );
        expect(find.text('Add Complete Kit to Cart'), findsOneWidget);

        cubit.close();
      },
    );

    testWidgets(
      'renders hero in-person clinic consultation for Stage 5 severe hair thinning',
      (tester) async {
        final cubit = HairTestCubit();
        cubit.emit(
          cubit.state.copyWith(
            isCompleted: true,
            isSubmitted: true,
            assessmentStatus: 'submitted',
            name: 'Vikram Mehta',
            age: '42',
            stage: 'Stage 5 - Advanced Crown Thinning',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: cubit,
              child: AssessmentReportView(state: cubit.state),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('In-Person Clinical Consultation Recommended'),
          findsOneWidget,
        );
        expect(
          find.text('Book Consultation with Dr. Jai Bansal (₹500)'),
          findsOneWidget,
        );

        cubit.close();
      },
    );

    testWidgets(
      'renders verified doctor care plan when reviewed by doctor',
      (tester) async {
        final cubit = HairTestCubit();
        cubit.emit(
          cubit.state.copyWith(
            isCompleted: true,
            isSubmitted: true,
            assessmentStatus: 'reviewed',
            name: 'Neha Verma',
            age: '31',
            stage: 'Stage 1 - Mild Thinning',
            doctorCarePlan: {
              'id': 'plan_001',
              'status': 'active',
              'instructions': 'Apply 1ml solution nightly. Use shampoo twice weekly.',
              'next_review_date': '2026-12-01',
              'medications': [
                {
                  'name': 'Custom Clinical Solution',
                  'dosage': '1ml daily at bedtime',
                  'instructions': 'Do not wash for 4 hours',
                },
              ],
            },
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: cubit,
              child: AssessmentReportView(state: cubit.state),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text("Doctor's Verified Care Plan"), findsOneWidget);
        expect(find.text('Prescribed by Dr. Jai Bansal'), findsWidgets);
        expect(
          find.text('Apply 1ml solution nightly. Use shampoo twice weekly.'),
          findsOneWidget,
        );
        expect(find.text('Custom Clinical Solution'), findsOneWidget);

        cubit.close();
      },
    );
  });
}

