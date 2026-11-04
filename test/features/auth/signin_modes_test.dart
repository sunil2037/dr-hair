import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/views/signin_view.dart';

import 'fake_auth_repository.dart';

void main() {
  group('SigninView Modes & Social Auth Tests', () {
    late FakeAuthRepository repository;
    late AuthCubit authCubit;

    setUp(() {
      repository = FakeAuthRepository();
      authCubit = AuthCubit(repository: repository);
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

    testWidgets(
      'renders tab switcher, email/password fields, and social buttons on Sign In tab',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Main tab switcher
        expect(find.text('Sign In'), findsWidgets);
        expect(find.text('Sign Up'), findsWidgets);

        // Social Auth Buttons
        expect(find.text('Google'), findsOneWidget);
        expect(find.text('Apple'), findsOneWidget);

        // Sign In mode has Email & Password directly
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Forgot Password?'), findsOneWidget);
      },
    );

    testWidgets(
      'switching to Sign Up tab displays registration fields with mobile verification',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap Sign Up tab
        await tester.tap(find.text('Sign Up').first);
        await tester.pumpAndSettle();

        expect(find.text('Create Patient Chart'), findsOneWidget);
        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Mobile Number'), findsOneWidget);
        expect(find.text('Send Verification OTP'), findsOneWidget);
      },
    );
  });
}
