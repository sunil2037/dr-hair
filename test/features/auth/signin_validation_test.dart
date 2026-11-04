import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/views/signin_view.dart';

import 'fake_auth_repository.dart';

void main() {
  group('SigninView Validation Tests', () {
    late AuthCubit authCubit;

    setUp(() {
      authCubit = AuthCubit(repository: FakeAuthRepository(testOtp: null));
    });

    tearDown(() {
      authCubit.close();
    });

    Widget createTestApp() {
      return MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const Scaffold(body: SigninView()),
        ),
      );
    }

    testWidgets('shows validation errors on empty email and password submission', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);

      // Submit empty credentials
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In').first);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('does not show local codes and renders legal links', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.textContaining('Local test code:'), findsNothing);
    });

    testWidgets('sign up validates phone number and moves to OTP step', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Switch to Sign Up
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      expect(find.text('Create Patient Chart'), findsOneWidget);

      // Enter details
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Ramesh Kumar');
      await tester.enterText(textFields.at(1), 'ramesh@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), '9876543210');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();

      // In OTP step
      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.textContaining('9876543210'), findsWidgets);

      // Tap Change Number / Back
      await tester.tap(find.text('Change Number'));
      await tester.pumpAndSettle();

      // Back in registration form with phone preserved
      expect(find.text('9876543210'), findsOneWidget);
    });
  });
}
