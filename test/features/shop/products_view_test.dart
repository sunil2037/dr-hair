import 'package:dr_hair/features/shop/presentation/viewmodels/cart_cubit.dart';
import 'package:dr_hair/features/shop/presentation/views/products_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget({CartCubit? cartCubit}) {
    return BlocProvider<CartCubit>.value(
      value: cartCubit ?? CartCubit(),
      child: const MaterialApp(
        home: ProductsView(),
      ),
    );
  }

  testWidgets(
    'renders title Medicines & Products, cart button, and search icon on right',
    (tester) async {
      final cartCubit = CartCubit();
      await tester.pumpWidget(buildTestableWidget(cartCubit: cartCubit));
      await tester.pumpAndSettle();

      // Check Title
      expect(find.text('Medicines & Products'), findsOneWidget);

      // Check Cart button
      expect(find.byTooltip('My Cart'), findsOneWidget);

      // Check Search icon on right side of Cart button
      expect(find.byKey(const ValueKey('appbar-search-button')), findsOneWidget);

      // Verify search icon is positioned to the right of the cart button
      final cartTopLeft = tester.getTopLeft(find.byTooltip('My Cart'));
      final searchTopLeft = tester.getTopLeft(
        find.byKey(const ValueKey('appbar-search-button')),
      );
      expect(searchTopLeft.dx, greaterThan(cartTopLeft.dx));
    },
  );

  testWidgets(
    'displays TabBar with categories All, Hair, Dandruff, Gut, Stress, Thyroid, PCOS, Hormone',
    (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final categories = [
        'All',
        'Hair',
        'Dandruff',
        'Gut',
        'Stress',
        'Thyroid',
        'PCOS',
        'Hormone',
      ];
      for (final cat in categories) {
        expect(
          find.descendant(of: find.byType(TabBar), matching: find.text(cat)),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets('switching tabs filters products by category', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Default 'All' shows all treatments
    expect(find.text('Follicle Booster Serum'), findsOneWidget);

    // Switch to Thyroid tab
    await tester.tap(find.text('Thyroid'));
    await tester.pumpAndSettle();

    expect(find.text('Thyro-Balance Metabolism Support'), findsOneWidget);
    expect(find.text('Follicle Booster Serum'), findsNothing);

    // Switch to Dandruff tab
    await tester.tap(find.text('Dandruff'));
    await tester.pumpAndSettle();

    expect(find.text('Clinical Scalp Detox Shampoo'), findsOneWidget);
    expect(find.text('Thyro-Balance Metabolism Support'), findsNothing);

    // Switch to PCOS tab
    await tester.tap(find.text('PCOS'));
    await tester.pumpAndSettle();

    expect(find.text('PCOS Care & Inositol Complex'), findsOneWidget);

    // Switch to Gut tab
    await tester.tap(find.text('Gut'));
    await tester.pumpAndSettle();

    expect(find.text('Gut Health Probiotics & Enzymes'), findsOneWidget);

    // Switch to Stress tab
    await tester.tap(find.text('Stress'));
    await tester.pumpAndSettle();

    expect(find.text('Calm & Sleep Ashwagandha KSM-66'), findsOneWidget);

    // Switch to Hormone tab
    await tester.tap(find.text('Hormone'));
    await tester.pumpAndSettle();

    expect(find.text('Max DHT Blocker & Saw Palmetto'), findsOneWidget);
  });

  testWidgets('search filters catalog by product and ingredient', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Medicines & Products'), findsOneWidget);
    expect(find.byKey(const ValueKey('product-search')), findsOneWidget);
    expect(find.text('Follicle Booster Serum'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('product-search')),
      'ketoconazole',
    );
    await tester.pumpAndSettle();

    expect(find.text('Clinical Scalp Detox Shampoo'), findsOneWidget);
    expect(find.text('Follicle Booster Serum'), findsNothing);
  });

  testWidgets('empty search state clears the query and filters', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('product-search')),
      'not-a-product',
    );
    await tester.pumpAndSettle();

    expect(find.text('No matching products'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('No matching products'), findsNothing);
    expect(find.text('Follicle Booster Serum'), findsOneWidget);
  });

  testWidgets('catalog remains usable on a narrow phone width without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Medicines & Products'), findsOneWidget);
    expect(find.byKey(const ValueKey('appbar-search-button')), findsOneWidget);
    expect(find.byTooltip('My Cart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
