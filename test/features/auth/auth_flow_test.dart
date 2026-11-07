import 'package:dr_hair/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/views/splash_view.dart';
import 'package:dr_hair/features/auth/presentation/views/signin_view.dart';
import 'package:dr_hair/features/auth/presentation/views/complete_profile_view.dart';
import 'package:dr_hair/features/hair_test/presentation/views/hair_test_view.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';
import 'package:dr_hair/features/shop/presentation/viewmodels/cart_cubit.dart';
import 'package:dr_hair/core/routes/app_router.dart';
import 'package:dr_hair/core/routes/route_names.dart';
import 'package:dr_hair/core/constants/app_strings.dart';
import 'package:dr_hair/core/theme/app_theme.dart';
import 'package:dr_hair/features/home/presentation/views/home_view.dart';
import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';

import 'fake_auth_repository.dart';

void main() {
  group('Auth Flow Widget Tests', () {
    testWidgets('SplashView renders branding and animated emblem', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(),
            child: const SplashView(),
          ),
        ),
      );

      // Verify SplashView is mounted and contains branding image
      expect(find.byType(SplashView), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets(
      'SigninView renders bottom card, validates email and password, and signs in',
      (tester) async {
        final repository = FakeAuthRepository();
        final authCubit = AuthCubit(repository: repository);
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>(
              create: (_) => authCubit,
              child: const SigninView(),
            ),
          ),
        );

        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Forgot Password?'), findsOneWidget);
        expect(find.text('Sign In'), findsWidgets);

        // Test validation on empty credentials
        await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In').first);
        await tester.pumpAndSettle();
        expect(find.text('Please enter a valid email address'), findsOneWidget);
        expect(find.text('Password must be at least 6 characters'), findsOneWidget);

        // Enter valid credentials
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'patient@example.com');
        await tester.enterText(textFields.at(1), 'password123');
        await tester.pumpAndSettle();

        // Tap Sign In to trigger login
        await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In').first);
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(authCubit.state.isAuthenticated, isTrue);
      },
    );

    testWidgets('SigninView switches to Sign Up, validates inputs, and sends verification OTP', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      final authCubit = AuthCubit(repository: repository);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const SigninView(),
          ),
        ),
      );

      // Switch to Sign Up tab
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      expect(find.text('Create Patient Chart'), findsOneWidget);
      expect(find.text('Send Verification OTP'), findsOneWidget);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Ramesh Kumar');
      await tester.enterText(textFields.at(1), 'ramesh@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), '9876543210');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.textContaining('9876543210'), findsWidgets);
      expect(find.text('Verify & Proceed'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pumpAndSettle();

      // Tap Verify & Proceed
      await tester.tap(find.text('Verify & Proceed'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(authCubit.state.isAuthenticated, isTrue);
    });

    testWidgets('End-to-end Splash -> Login -> Home routing flow works', (
      tester,
    ) async {
      AppRouter.router.go(RouteNames.splash);
      final authCubit = AuthCubit(repository: FakeAuthRepository());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<CartCubit>(create: (_) => CartCubit()),
            BlocProvider<CareCubit>(create: (_) => CareCubit()),
            BlocProvider<HairTestCubit>(create: (_) => HairTestCubit()),
          ],
          child: MaterialApp.router(
            title: AppStrings.appName,
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
          ),
        ),
      );

      // 1. Initial screen is SplashView
      expect(find.byType(SplashView), findsOneWidget);

      // Tap screen to proceed to login screen
      await tester.tap(find.byType(SplashView));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 2. Now on SigninView with bottom card
      expect(find.byType(SigninView), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'patient@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In').first);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // 3. User is now authenticated and lands on Home Screen
      expect(authCubit.state.isAuthenticated, isTrue);
      expect(find.text('Login'), findsNothing);
      expect(find.byType(HomeView), findsOneWidget);
      expect(find.text('Personal Care'), findsOneWidget);
    });

    testWidgets(
      'New user signs up, completes profile, and lands on Assessment Screen (not Home)',
      (tester) async {
        AppRouter.router.go(RouteNames.splash);
        final authCubit = AuthCubit(
          repository: FakeAuthRepository(registered: false),
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<CartCubit>(create: (_) => CartCubit()),
              BlocProvider<CareCubit>(create: (_) => CareCubit()),
              BlocProvider<HairTestCubit>(create: (_) => HairTestCubit()),
            ],
            child: MaterialApp.router(
              title: AppStrings.appName,
              theme: AppTheme.lightTheme,
              routerConfig: AppRouter.router,
            ),
          ),
        );

        // 1. Initial screen is SplashView -> Proceed to SigninView
        await tester.tap(find.byType(SplashView));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 2. SigninView: switch to Sign Up
        await tester.tap(find.text('Sign Up').first);
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'New Patient');
        await tester.enterText(textFields.at(1), 'newpatient@example.com');
        await tester.enterText(textFields.at(2), 'password123');
        await tester.enterText(textFields.at(3), '9876543210');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Send Verification OTP'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, '123456');
        await tester.tap(find.text('Verify & Proceed'));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // 3. User requires profile completion (CompleteProfileView)
        expect(find.byType(CompleteProfileView), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Full name *'),
          'New Patient',
        );
        await tester.tap(find.text('Save & Continue'));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // 4. Lands on Assessment Screen (HairTestView), NOT HomeView
        expect(find.byType(HairTestView), findsOneWidget);
        expect(find.text('Hair & Scalp Assessment'), findsOneWidget);
        expect(find.byType(HomeView), findsNothing);
      },
    );

    test(
      'AuthCubit deleteAccount calls repository and resets to unauthenticated',
      () async {
        final repository = FakeAuthRepository();
        final authCubit = AuthCubit(repository: repository);
        final success = await authCubit.deleteAccount();
        expect(success, true);
        expect(authCubit.state.status, AuthStatus.unauthenticated);
        expect(repository.sessionCleared, true);
      },
    );

    test(
      'AuthCubit deleteAccount calls repository and resets to unauthenticated',
      () async {
        final repository = FakeAuthRepository();
        final authCubit = AuthCubit(repository: repository);
        final success = await authCubit.deleteAccount();
        expect(success, true);
        expect(authCubit.state.status, AuthStatus.unauthenticated);
        expect(repository.sessionCleared, true);
      },
    );
  });
}
