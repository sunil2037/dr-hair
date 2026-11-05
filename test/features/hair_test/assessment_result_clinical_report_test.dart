import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'package:dr_hair/features/hair_test/presentation/views/assessment_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'AssessmentResultView renders Doctor Clinical Report when shared by clinician',
    (tester) async {
      final cubit = HairTestCubit();
      cubit.emit(
        cubit.state.copyWith(
          isCompleted: true,
          isSubmitted: true,
          name: 'Ananya Sharma',
          age: '28',
          clinicalReports: [
            {
              'id': 'REP-2026-001',
              'title': 'Scalp Trichoscopy & Follicular Assessment',
              'file_name': 'trichoscopy_report.pdf',
              'bytes': 245760, // ~240 KB
              'visibility': 'Shared',
            },
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AssessmentResultView(cubit: cubit),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Assert doctor's clinical report section
      expect(find.text("Doctor's Clinical Report"), findsOneWidget);
      expect(find.text('Verified by Dr. Jai Bansal'), findsOneWidget);
      expect(
        find.text('Scalp Trichoscopy & Follicular Assessment'),
        findsOneWidget,
      );
      expect(find.text('trichoscopy_report.pdf'), findsOneWidget);
      expect(find.text('240 KB'), findsOneWidget);
      expect(find.text('View PDF'), findsOneWidget);
      expect(find.text('Order Kit'), findsOneWidget);

      cubit.close();
    },
  );
}

