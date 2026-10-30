import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';
import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'package:dr_hair/features/home/presentation/views/home_view.dart';
import 'package:dr_hair/core/theme/app_theme.dart';

void main() {
  Widget buildHomeView({VoidCallback? onStartHairTest}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CareCubit>(create: (_) => CareCubit()),
        BlocProvider<HairTestCubit>(create: (_) => HairTestCubit()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: HomeView(onStartHairTest: onStartHairTest ?? () {}),
        ),
      ),
    );
  }

  testWidgets(
    'HomeView prioritizes products and care access before optional information',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildHomeView());
      await tester.pumpAndSettle();

      // Verify the presence of key sections
      expect(find.byType(HomeView), findsOneWidget);
      expect(find.text('Essential Products'), findsOneWidget);
      expect(find.text('Prefer expert guidance?'), findsNothing);
      expect(find.text('Visit Dr. Jai Bansal'), findsOneWidget);
      expect(find.text('URGENT CARE'), findsOneWidget);
      expect(find.text('Explore Dr.Hair'), findsOneWidget);
      expect(find.text('Free Hair Test'), findsOneWidget);

      // Verify vertical positioning order:
      final productsTop = tester.getTopLeft(find.text('Essential Products')).dy;
      final urgentCareTop = tester.getTopLeft(find.text('URGENT CARE')).dy;
      final moreContentTop = tester.getTopLeft(find.text('Explore Dr.Hair')).dy;
      expect(productsTop, lessThan(urgentCareTop));
      expect(urgentCareTop, lessThan(moreContentTop));
    },
  );

  testWidgets('HomeView scrolls to reveal Reviews and Video Stories below', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildHomeView());
    await tester.pumpAndSettle();

    // Optional editorial content stays collapsed until requested.
    await tester.ensureVisible(find.text('Explore Dr.Hair'));
    await tester.tap(find.text('Explore Dr.Hair'));
    await tester.pumpAndSettle();

    expect(find.text('Voices of Success'), findsOneWidget);
    expect(find.text('Real Patient Stories'), findsOneWidget);

    // Reviews is above Video Stories
    final reviewsTop = tester.getTopLeft(find.text('Voices of Success')).dy;
    final videosTop = tester.getTopLeft(find.text('Real Patient Stories')).dy;
    expect(reviewsTop, lessThan(videosTop));
  });
}
