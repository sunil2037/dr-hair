import 'package:dr_hair/features/profile/presentation/views/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProfileView renders patient card, clinical stats and drawer tabs',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileView(),
      ),
    );

    // Patient info
    expect(find.text('Yashveer Soni'), findsOneWidget);
    expect(find.text('Patient ID: DRH-2024-8849'), findsOneWidget);
    expect(find.text('Month 3 / 6'), findsOneWidget);
    expect(find.text('+38% Follicles'), findsOneWidget);

    // Key drawer sections present in profile
    expect(find.text('Hair Test (AI Diagnostic Scan)'), findsOneWidget);
    expect(find.text('Treatment Details & Regimen'), findsOneWidget);
    expect(find.text('My Cart & Custom Formulations'), findsOneWidget);
    expect(find.text('Patient Reviews & Clinical Proof'), findsOneWidget);
    expect(find.text('About Dr.Hair Medical Practice'), findsOneWidget);
    expect(find.text('Contact Us & Clinic Locations'), findsOneWidget);
    expect(find.text('WhatsApp Clinical Concierge'), findsOneWidget);
    expect(find.text('Edit Personal Information'), findsOneWidget);
    expect(find.text('Sign In / Register New Patient'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });
}
