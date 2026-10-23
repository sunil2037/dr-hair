import 'package:dr_hair/features/profile/presentation/views/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProfileView renders patient details and available care flows', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileView()));

    // Patient info
    expect(find.text('Yashveer Soni'), findsOneWidget);
    expect(find.text('Patient ID: DRH-2024-8849'), findsOneWidget);
    expect(find.text('The tools for your hair health journey'), findsOneWidget);

    // Key drawer sections present in profile
    expect(find.text('Treatment plan'), findsOneWidget);
    expect(find.text('Daily routine'), findsOneWidget);
    expect(find.text('Progress journal'), findsOneWidget);
    expect(find.text('Nutrition guide'), findsOneWidget);
    expect(find.text('Care reminders'), findsOneWidget);
    expect(find.text('Appointments'), findsOneWidget);
    expect(find.text('My cart'), findsOneWidget);
    expect(find.text('Orders & delivery'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
