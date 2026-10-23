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
          body: HomeView(
            onStartHairTest: onStartHairTest ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets(
    'HomeView renders sections in the requested hierarchy: Hero -> Products -> Restoration Journey -> Book Appointment -> Care Journey -> Urgent Care',
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
      expect(find.text('Your Restoration Journey'), findsOneWidget);
      expect(find.text('Prefer expert guidance?'), findsOneWidget);
      expect(find.text('YOUR CARE JOURNEY'), findsOneWidget);
      expect(find.text('URGENT CARE'), findsOneWidget);

      // Verify vertical positioning order:
      // Products (top content) is above Restoration Journey
      final productsTop = tester.getTopLeft(find.text('Essential Products')).dy;
      final restorationTop =
          tester.getTopLeft(find.text('Your Restoration Journey')).dy;
      expect(productsTop, lessThan(restorationTop));

      // Restoration Journey is above Book Appointment
      final appointmentTop =
          tester.getTopLeft(find.text('Prefer expert guidance?')).dy;
      expect(restorationTop, lessThan(appointmentTop));

      // Book Appointment is above Care Journey
      final careJourneyTop =
          tester.getTopLeft(find.text('YOUR CARE JOURNEY')).dy;
      expect(appointmentTop, lessThan(careJourneyTop));

      // Care Journey is above Urgent Care
      final urgentCareTop = tester.getTopLeft(find.text('URGENT CARE')).dy;
      expect(careJourneyTop, lessThan(urgentCareTop));
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

    // Scroll down to reveal reviews and video stories
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Voices of Success'), findsOneWidget);
    expect(find.text('Real Patient Stories'), findsOneWidget);

    // Reviews is above Video Stories
    final reviewsTop = tester.getTopLeft(find.text('Voices of Success')).dy;
    final videosTop = tester.getTopLeft(find.text('Real Patient Stories')).dy;
    expect(reviewsTop, lessThan(videosTop));
  });
}
