import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';
import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'package:dr_hair/features/treatment/presentation/views/treatment_details_view.dart';

void main() {
  testWidgets('TreatmentDetailsView renders tabs, prescription details and medical reports',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CareCubit()),
          BlocProvider(create: (_) => HairTestCubit()),
        ],
        child: const MaterialApp(
          home: TreatmentDetailsView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar Title & Tabs
    expect(find.text('Medical Reports & Prescription'), findsOneWidget);
    expect(find.text('Prescription Details'), findsOneWidget);
    expect(find.text('Medical Reports'), findsOneWidget);

    // Verify Super Admin Doctor Card in Prescription tab
    expect(find.text('Dr. Jai Bansal'), findsOneWidget);
    expect(find.text('PRESCRIBED BY SUPER ADMIN'), findsOneWidget);
    expect(find.text('Download Signed Prescription (PDF)'), findsOneWidget);

    // Switch to Medical Reports tab
    await tester.tap(find.text('Medical Reports'));
    await tester.pumpAndSettle();

    // Verify Reports with Uploaded by Admin / Super Admin
    expect(find.text('Verified Clinical Vault'), findsOneWidget);
    expect(find.text('High-Resolution Scalp Trichoscopy Scan'), findsOneWidget);
    expect(find.text('Uploaded by Super Admin'), findsWidgets);
    expect(find.text('View in Sheet'), findsWidgets);
    expect(find.text('Download'), findsWidgets);

    // Tap on 'View in Sheet' for the first report
    await tester.tap(find.text('View in Sheet').first);
    await tester.pumpAndSettle();

    // Verify that bottom sheet opens with title and uploaded by admin badge
    expect(find.text('UPLOADED BY SUPER ADMIN'), findsWidgets);
    expect(find.text('Clinical Parameters & Readings'), findsOneWidget);
    expect(find.textContaining('Download ('), findsOneWidget);
  });
}
