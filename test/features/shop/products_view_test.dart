import 'package:dr_hair/features/shop/data/models/product_model.dart';
import 'package:dr_hair/features/shop/domain/repositories/product_repository.dart';
import 'package:dr_hair/features/shop/presentation/viewmodels/cart_cubit.dart';
import 'package:dr_hair/features/shop/presentation/viewmodels/products_cubit.dart';
import 'package:dr_hair/features/shop/presentation/viewmodels/products_state.dart';
import 'package:dr_hair/features/shop/presentation/views/products_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

class _FakeProductRepo implements ProductRepository {
  final bool shouldFail;
  final List<ProductItem> items;

  _FakeProductRepo({this.shouldFail = false, List<ProductItem>? items})
    : items = items ?? ProductItem.demoCatalog;

  @override
  Future<({List<ProductItem> items, bool hasMore, int total})> getProducts({
    String? category,
    String? rootCause,
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    if (shouldFail) {
      throw Exception('Network error');
    }
    return (items: items, hasMore: false, total: items.length);
  }

  @override
  Future<ProductItem?> getProductById(String id) async {
    return items.firstWhere((p) => p.id == id, orElse: () => items.first);
  }
}

void main() {
  Widget buildTestableWidget({CartCubit? cartCubit, ProductsCubit? cubit}) {
    final productsCubit =
        cubit ??
        (ProductsCubit(repository: _FakeProductRepo())..loadProducts());
    return BlocProvider<CartCubit>.value(
      value: cartCubit ?? CartCubit(),
      child: BlocProvider<ProductsCubit>.value(
        value: productsCubit,
        child: MaterialApp(home: ProductsView(cubit: productsCubit)),
      ),
    );
  }

  group('ProductsCubit Unit Tests', () {
    test('loads products successfully from repository', () async {
      final repo = _FakeProductRepo();
      final cubit = ProductsCubit(repository: repo);

      expect(cubit.state.products, isEmpty);
      await cubit.loadProducts();
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.products.length, repo.items.length);
    });

    test('handles error state gracefully on fetch failure', () async {
      final repo = _FakeProductRepo(shouldFail: true);
      final cubit = ProductsCubit(repository: repo);

      await cubit.loadProducts();
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, isNotNull);
    });

    test('updates category selection and search query', () async {
      final cubit = ProductsCubit(repository: _FakeProductRepo());
      await cubit.selectCategory(2);
      expect(cubit.state.selectedCategoryIndex, 2);

      await cubit.search('serum');
      expect(cubit.state.searchQuery, 'serum');

      await cubit.clearSearch();
      expect(cubit.state.searchQuery, '');
      cubit.close();
    });
  });

  group('ProductsView UI Tests', () {
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
        expect(
          find.byKey(const ValueKey('appbar-search-button')),
          findsOneWidget,
        );

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

    testWidgets(
      'catalog remains usable on a narrow phone width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.text('Medicines & Products'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('appbar-search-button')),
          findsOneWidget,
        );
        expect(find.byTooltip('My Cart'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'uses Skeletonizer during loading without fabricated products',
      (tester) async {
        final cubit = ProductsCubit(
          initialState: const ProductsState(isLoading: true, products: []),
        );
        await tester.pumpWidget(buildTestableWidget(cubit: cubit));
        await tester.pump();

        expect(
          find.byWidgetPredicate((widget) => widget is Skeletonizer),
          findsWidgets,
        );
        expect(find.text('Follicle Booster Serum'), findsNothing);
      },
    );

    testWidgets(
      'displays error state with retry button when products fail to load',
      (tester) async {
        final cubit = ProductsCubit(
          initialState: const ProductsState(
            isLoading: false,
            errorMessage: 'Unable to connect to server',
            products: [],
          ),
        );
        await tester.pumpWidget(buildTestableWidget(cubit: cubit));
        await tester.pumpAndSettle();

        expect(find.text('Unable to load products'), findsOneWidget);
        expect(find.text('Unable to connect to server'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('products-retry-button')),
          findsOneWidget,
        );
      },
    );
  });
}
