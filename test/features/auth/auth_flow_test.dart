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
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      'SigninView renders bottom card, validates 10-digit phone, and transitions to OTP',
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
        expect(find.text('Mobile Number'), findsOneWidget);
        expect(find.text('+91'), findsOneWidget);
        expect(find.text('Send Verification OTP'), findsOneWidget);
        expect(find.text('Continue as Guest'), findsNothing);

        // Test validation on invalid input (less than 10 digits)
        await tester.tap(find.text('Send Verification OTP'));
        await tester.pumpAndSettle();
        expect(
          find.text('Please enter a valid 10-digit mobile number'),
          findsOneWidget,
        );
        expect(find.byType(SnackBar), findsNothing);

        // Enter valid 10-digit mobile number
        await tester.enterText(find.byType(TextField).first, '9876543210');
        await tester.pumpAndSettle();

        // Tap Send OTP to trigger animated transition inside the bottom card
        await tester.tap(find.text('Send Verification OTP'));
        await tester.pumpAndSettle();

        // Ensure card animated to OTP step
        expect(find.text('Enter Verification Code'), findsOneWidget);
        expect(find.text('Verify & Proceed'), findsOneWidget);
        expect(find.textContaining('Local test code:'), findsNothing);
        expect(repository.lastRequestedLogin, '9876543210');

        // Top back button should be visible when OTP field is active
        expect(find.byIcon(LucideIcons.arrowLeft), findsWidgets);

        // Tap the top back button to return to phone step
        await tester.tap(find.byIcon(LucideIcons.arrowLeft).first);
        await tester.pumpAndSettle();

        // Should be back on phone step
        expect(find.text('Send Verification OTP'), findsOneWidget);
      },
    );

    testWidgets('SigninView accepts the six-digit SMS code and verifies it', (
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

      // Enter valid phone number and proceed to OTP step
      await tester.enterText(find.byType(TextField).first, '9876543210');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.textContaining('Local test code:'), findsNothing);
      expect(find.text('Verify & Proceed'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pumpAndSettle();

      // Ensure digits are auto-filled
      expect(find.byType(TextField), findsNWidgets(6));

      // Tap Verify & Proceed
      await tester.tap(find.text('Verify & Proceed'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Ensure authenticated in cubit
      expect(authCubit.state.isAuthenticated, isTrue);
      expect(repository.requestCount, 1);
      expect(repository.verifyCount, 1);
      expect(repository.lastVerifiedLogin, '9876543210');
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

      // Tap screen (or let splash timer fire) to proceed to login screen
      await tester.tap(find.byType(SplashView));
      await tester.pumpAndSettle();

      // 2. Now on SigninView (Login Screen) with bottom card
      expect(find.byType(SigninView), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '9876543210');
      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.tap(find.text('Verify & Proceed'));
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
        await tester.pumpAndSettle();

        // 2. SigninView
        await tester.enterText(find.byType(TextField).first, '9876543210');
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
