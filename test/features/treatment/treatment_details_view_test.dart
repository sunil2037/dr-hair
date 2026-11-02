import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dr_hair/features/auth/domain/models/user_model.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:dr_hair/features/treatment/data/patient_clinical_api.dart';
import 'package:dr_hair/features/treatment/presentation/views/treatment_details_view.dart';

import '../auth/fake_auth_repository.dart';

class _FakePatientClinicalApi extends PatientClinicalApi {
  @override
  Future<Map<String, dynamic>> getClinicalRecord(String accessToken) async {
    return {
      'care_plans': [
        {
          'id': 'cp_101',
          'treatment_name': 'Custom Regrowth Protocol',
          'doctor_name': 'Dr. Jai Bansal',
          'diagnosis': 'Stage 2 androgenetic thinning with mild scalp flaking.',
          'stage': 'Stage 2',
          'duration': '6 Months',
          'medications': [
            {
              'name': 'Dr.Hair 5% Topical Regrowth Booster',
              'category': 'Clinical Topical',
              'form': 'Solution',
              'dose': '1ml',
              'frequency': 'Evening',
              'instructions': 'Apply evenly with dropper',
            },
          ],
        },
      ],
      'reports': [
        {
          'id': 'rep_201',
          'title': 'High-Resolution Scalp Trichoscopy Scan',
          'format': 'pdf',
          'file_name': 'trichoscopy_scan.pdf',
          'bytes': 2048000,
          'uploaded_by': 'Dr. Jai Bansal',
          'created_at': '2026-10-25T10:00:00Z',
        },
      ],
    };
  }
}

void main() {
  testWidgets(
    'TreatmentDetailsView shows sign-in guidance when unauthenticated',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TreatmentDetailsView()));
      await tester.pumpAndSettle();

      expect(find.text('Medical Reports & Prescription'), findsOneWidget);
      expect(
        find.text(
          'Sign in to view care plans and reports shared by your clinic.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'TreatmentDetailsView renders tabs, prescription details and medical reports when authenticated',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authCubit = AuthCubit(repository: FakeAuthRepository());
      authCubit.emit(
        authCubit.state.copyWith(
          status: AuthStatus.authenticated,
          sessionToken: 'test-token',
          user: UserModel.demoPatient(),
        ),
      );

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: MaterialApp(
            home: TreatmentDetailsView(clinicalApi: _FakePatientClinicalApi()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AppBar Title & Tabs
      expect(find.text('Medical Reports & Prescription'), findsOneWidget);
      expect(find.text('Prescription Details'), findsOneWidget);
      expect(find.text('Medical Reports'), findsOneWidget);

      // Verify Plan details
      expect(find.text('YOUR CLINIC CARE PLAN'), findsOneWidget);
      expect(find.text('Custom Regrowth Protocol'), findsOneWidget);
      expect(find.text('Prepared by Dr. Jai Bansal'), findsOneWidget);
      expect(find.text('Dr.Hair 5% Topical Regrowth Booster'), findsOneWidget);

      // Switch to Medical Reports tab
      await tester.tap(find.text('Medical Reports'));
      await tester.pumpAndSettle();

      expect(
        find.text('High-Resolution Scalp Trichoscopy Scan'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.download), findsOneWidget);
    },
  );
}
