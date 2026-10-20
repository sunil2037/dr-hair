import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/views/splash_view.dart';
import 'package:dr_hair/features/auth/presentation/views/signin_view.dart';
import 'package:dr_hair/core/routes/app_router.dart';
import 'package:dr_hair/core/constants/app_strings.dart';
import 'package:dr_hair/core/theme/app_theme.dart';
import 'package:dr_hair/features/home/presentation/views/home_view.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  group('Auth Flow Widget Tests', () {
    testWidgets('SplashView renders branding and animated emblem', (tester) async {
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

    testWidgets('SigninView renders bottom card, validates 10-digit phone, and transitions to OTP', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(),
            child: const SigninView(),
          ),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);
      expect(find.text('Send Verification OTP'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);

      // Test validation on invalid input (less than 10 digits)
      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid 10-digit mobile number.'), findsOneWidget);

      // Enter valid 10-digit mobile number
      await tester.enterText(find.byType(TextField).first, '9876543210');
      await tester.pumpAndSettle();

      // Tap Send OTP to trigger animated transition inside the bottom card
      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();

      // Ensure card animated to OTP step
      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.text('Verify & Proceed'), findsOneWidget);
      expect(find.text('Auto-fill'), findsOneWidget);

      // Top back button should be visible when OTP field is active
      expect(find.byIcon(LucideIcons.arrowLeft), findsWidgets);

      // Tap the top back button to return to phone step
      await tester.tap(find.byIcon(LucideIcons.arrowLeft).first);
      await tester.pumpAndSettle();

      // Should be back on phone step
      expect(find.text('Send Verification OTP'), findsOneWidget);
    });

    testWidgets('SigninView allows auto-filling demo OTP code and logging in', (tester) async {
      final authCubit = AuthCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const SigninView(),
          ),
        ),
      );

      // Enter valid phone number and proceed to OTP step
      await tester.enterText(find.byType(TextField).first, '9876543210');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.text('Auto-fill'), findsOneWidget);
      expect(find.text('Verify & Proceed'), findsOneWidget);

      // Tap Auto-fill
      await tester.tap(find.text('Auto-fill'));
      await tester.pumpAndSettle();

      // Ensure digits are auto-filled
      expect(find.text('1'), findsOneWidget);

      // Tap Verify & Proceed
      await tester.tap(find.text('Verify & Proceed'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Ensure authenticated in cubit
      expect(authCubit.state.isAuthenticated, isTrue);
    });

    testWidgets('End-to-end Splash -> Login -> Home routing flow works', (tester) async {
      final authCubit = AuthCubit();

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: MaterialApp.router(
            title: AppStrings.appName,
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
          ),
        ),
      );

      // 1. Initial screen is SplashView
      expect(find.byType(SplashView), findsOneWidget);

      // Tap screen (or let splash timer fire) to proceed to login screen
      await tester.tap(find.byType(SplashView));
      await tester.pumpAndSettle();

      // 2. Now on SigninView (Login Screen) with bottom card
      expect(find.byType(SigninView), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);

      // Tap 'Continue as Guest' to authenticate
      await tester.tap(find.text('Continue as Guest'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // 3. User is now authenticated and lands on Home Screen
      expect(authCubit.state.isAuthenticated, isTrue);
      expect(find.text('Login'), findsNothing);
      expect(find.byType(HomeView), findsOneWidget);
      expect(find.text('Clinically Approved'), findsOneWidget);
    });
  });
}
