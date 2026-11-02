import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dr_hair/core/widgets/auth_gate.dart';
import 'package:dr_hair/core/routes/route_names.dart';
import 'package:dr_hair/features/auth/domain/models/user_model.dart';
import 'package:dr_hair/features/auth/domain/repositories/auth_repository.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_state.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthRequiredRoute Tests', () {
    testWidgets('renders child widget when user is authenticated', (tester) async {
      final repo = _FakeAuthRepository();
      final cubit = AuthCubit(repository: repo);
      cubit.emit(AuthState(
        status: AuthStatus.authenticated,
        user: const UserModel(
          id: 'user_1',
          name: 'Patient One',
          emailOrPhone: '9876543210',
          patientId: 'DHP001',
        ),
        sessionToken: 'token_123',
      ));

      final router = GoRouter(
        initialLocation: '/protected',
        routes: [
          GoRoute(
            path: '/protected',
            builder: (context, state) => const AuthRequiredRoute(
              routePath: '/protected',
              child: Text('Protected Clinical Content'),
            ),
          ),
          GoRoute(
            path: RouteNames.signin,
            builder: (context, state) => const Text('Sign-in Screen'),
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: cubit,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Protected Clinical Content'), findsOneWidget);
      expect(find.text('Sign-in Screen'), findsNothing);
    });

    testWidgets('does NOT redirect to signin when status is loading with an authenticated user', (tester) async {
      final repo = _FakeAuthRepository();
      final cubit = AuthCubit(repository: repo);
      const user = UserModel(
        id: 'user_1',
        name: 'Patient One',
        emailOrPhone: '9876543210',
        patientId: 'DHP001',
      );
      cubit.emit(AuthState(
        status: AuthStatus.authenticated,
        user: user,
        sessionToken: 'token_123',
      ));

      final router = GoRouter(
        initialLocation: '/protected',
        routes: [
          GoRoute(
            path: '/protected',
            builder: (context, state) => const AuthRequiredRoute(
              routePath: '/protected',
              child: Text('Protected Clinical Content'),
            ),
          ),
          GoRoute(
            path: RouteNames.signin,
            builder: (context, state) => const Text('Sign-in Screen'),
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: cubit,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Protected Clinical Content'), findsOneWidget);

      // Now simulate a profile update or in-flight loading event
      cubit.emit(cubit.state.copyWith(status: AuthStatus.loading));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Must remain on protected screen, never redirect to sign-in!
      expect(find.text('Protected Clinical Content'), findsOneWidget);
      expect(find.text('Sign-in Screen'), findsNothing);
    });

    testWidgets('redirects to signin when user is unauthenticated', (tester) async {
      final repo = _FakeAuthRepository();
      final cubit = AuthCubit(repository: repo);
      cubit.emit(const AuthState(status: AuthStatus.unauthenticated));

      final router = GoRouter(
        initialLocation: '/protected',
        routes: [
          GoRoute(
            path: '/protected',
            builder: (context, state) => const AuthRequiredRoute(
              routePath: '/protected',
              child: Text('Protected Clinical Content'),
            ),
          ),
          GoRoute(
            path: RouteNames.signin,
            builder: (context, state) => const Text('Sign-in Screen'),
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: cubit,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign-in Screen'), findsOneWidget);
      expect(find.text('Protected Clinical Content'), findsNothing);
    });
  });
}

