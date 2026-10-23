import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/views/signin_view.dart';

void main() {
  group('SigninView Validation and Demo Mode Tests', () {
    late AuthCubit authCubit;

    setUp(() {
      authCubit = AuthCubit();
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

    testWidgets('shows inline validation error on invalid phone number submission', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Send Verification OTP'), findsOneWidget);

      // Submit empty phone
      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid 10-digit mobile number'), findsOneWidget);

      // Enter 4 digits (still invalid)
      await tester.enterText(find.byType(TextField).first, '9876');
      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid 10-digit mobile number'), findsOneWidget);
    });

    testWidgets('renders demo authentication note and policy links', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Preview / Demo Authentication Active'), findsOneWidget);
      expect(find.textContaining('Use demo code 123456'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('valid phone moves to OTP step and back preserves phone', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '9876543210');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();

      // In OTP step
      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.textContaining('9876543210'), findsWidgets);

      // Tap Change Number / Back
      await tester.tap(find.text('Change Number'));
      await tester.pumpAndSettle();

      // Back in phone step with phone preserved
      expect(find.text('9876543210'), findsOneWidget);
    });
  });
}
