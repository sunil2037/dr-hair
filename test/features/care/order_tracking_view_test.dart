import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';
import 'package:dr_hair/core/routes/app_router.dart';
import 'package:dr_hair/features/shop/presentation/viewmodels/cart_cubit.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';

void main() {
  testWidgets('Tap Orders & delivery in ProfileView navigates to OrderTrackingView', (tester) async {
    final router = AppRouter.router;
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(create: (_) => AuthCubit()..checkAuthStatus()),
          BlocProvider<CartCubit>(create: (_) => CartCubit()),
          BlocProvider<CareCubit>(create: (_) => CareCubit()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to profile tab
    router.go('/profile');
    await tester.pumpAndSettle();

    // Find "Orders & delivery"
    final ordersTile = find.text('Orders & delivery');
    expect(ordersTile, findsOneWidget);

    // Scroll to it if needed
    await tester.scrollUntilVisible(ordersTile, 100);
    await tester.pumpAndSettle();

    // Tap it
    await tester.tap(ordersTile);
    await tester.pumpAndSettle();

    expect(find.text('Orders & Deliveries'), findsOneWidget);
  });
}
