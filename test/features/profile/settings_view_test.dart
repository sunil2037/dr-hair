import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dr_hair/features/auth/domain/models/user_model.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/profile/presentation/views/settings_view.dart';

import '../auth/fake_auth_repository.dart';

void main() {
  group('SettingsView Widget Tests', () {
    late FakeAuthRepository repository;
    late AuthCubit authCubit;

    setUp(() async {
      repository = FakeAuthRepository(
        initialUser: const UserModel(
          id: 'user_123',
          patientId: 'DHP-9999',
          name: 'Vikram Mehta',
          email: 'vikram@example.com',
          emailOrPhone: '9876543210',
          phone: '9876543210',
          photoUrl: '',
        ),
      );
      authCubit = AuthCubit(repository: repository);
      await authCubit.restoreSession();
    });

    tearDown(() {
      authCubit.close();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const SettingsView(),
        ),
      );
    }

    testWidgets(
      'renders patient details, push notification switch, and danger zone',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Settings & Preferences'), findsOneWidget);
        expect(find.text('Push Notifications'), findsOneWidget);
        expect(find.text('Vikram Mehta'), findsOneWidget);
        expect(find.text('DHP-9999'), findsOneWidget);
        expect(find.text('vikram@example.com'), findsOneWidget);
        expect(find.text('9876543210'), findsOneWidget);

        // Verify Policies
        expect(find.text('LEGAL & POLICIES'), findsOneWidget);
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.text('Terms of Service'), findsOneWidget);

        // Verify Danger Zone
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(find.text('DANGER ZONE'), findsOneWidget);
        expect(find.text('Permanently Delete Account'), findsOneWidget);
        expect(find.text('Delete My Account'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Delete Account opens modal with reasons and confirmation',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Scroll down to danger zone
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete My Account'));
        await tester.pumpAndSettle();

        // Check modal content
        expect(find.text('Permanently Delete Account?'), findsOneWidget);
        expect(find.text('Completed my hair treatment'), findsOneWidget);
        expect(find.text('Privacy or data concerns'), findsOneWidget);
        expect(find.text('Permanently Delete Account'), findsWidgets);
      },
    );
  });
}
