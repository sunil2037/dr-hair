import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';
import 'package:dr_hair/core/routes/app_router.dart';
import 'package:dr_hair/features/shop/presentation/viewmodels/cart_cubit.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:dr_hair/features/auth/domain/models/user_model.dart';
import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';

import '../auth/fake_auth_repository.dart';

void main() {
  testWidgets(
    'Tap Orders & delivery in ProfileView navigates to OrderTrackingView',
    (tester) async {
      final router = AppRouter.router;
      final authCubit = AuthCubit(repository: FakeAuthRepository());
      authCubit.emit(
        authCubit.state.copyWith(
          status: AuthStatus.authenticated,
          sessionToken: 'test-token',
          user: UserModel.demoPatient(),
        ),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<CartCubit>(create: (_) => CartCubit()),
            BlocProvider<CareCubit>(create: (_) => CareCubit()),
            BlocProvider<HairTestCubit>(create: (_) => HairTestCubit()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to profile tab
      router.go('/profile');
      await tester.pumpAndSettle();

      // Find "Orders & delivery"
      final ordersTile = find.text('Orders & delivery');
      expect(ordersTile, findsOneWidget);

      // Scroll to it and offset down slightly from under the app bar
      await tester.ensureVisible(ordersTile);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 80),
      );
      await tester.pumpAndSettle();

      // Tap it
      await tester.tap(ordersTile);
      await tester.pumpAndSettle();

      expect(find.text('Orders & Deliveries'), findsOneWidget);
    },
  );
}
