import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';
import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'package:dr_hair/features/home/presentation/views/home_view.dart';
import 'package:dr_hair/core/theme/app_theme.dart';
import 'package:dr_hair/features/shop/data/models/category_model.dart';
import 'package:dr_hair/features/shop/data/models/product_model.dart';
import 'package:dr_hair/features/shop/domain/repositories/product_repository.dart';
import 'package:dr_hair/features/videos/domain/models/video_story_model.dart';
import 'package:dr_hair/features/videos/domain/repositories/video_repository.dart';
import '../../helpers/video_test_fixtures.dart';

class _FakeHomeProductRepository implements ProductRepository {
  @override
  Future<({List<ProductItem> items, bool hasMore, int total})> getProducts({
    String? category,
    String? rootCause,
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    final items = ProductItem.demoCatalog.take(limit).toList();
    return (items: items, hasMore: false, total: items.length);
  }

  @override
  Future<ProductItem?> getProductById(String id) async {
    for (final product in ProductItem.demoCatalog) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<List<CategoryItem>> getCategories({String? type}) async {
    return CategoryItem.defaultProductCategories();
  }
}

class _FakeHomeVideoRepository implements VideoRepository {
  @override
  Future<({List<VideoStoryModel> items, bool hasMore, int total, int page})>
  getVideos({
    int page = 1,
    int limit = 10,
    String? category,
    String? placement = 'reels',
  }) async {
    final items = VideoTestFixtures.testStories.take(limit).toList();
    return (items: items, hasMore: false, total: items.length, page: 1);
  }
}

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
            productRepository: _FakeHomeProductRepository(),
            videoRepository: _FakeHomeVideoRepository(),
          ),
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
      expect(find.text('Voices of Success'), findsOneWidget);
      expect(find.text('Free Hair Test'), findsOneWidget);

      // Verify vertical positioning order:
      final productsTop = tester.getTopLeft(find.text('Essential Products')).dy;
      final urgentCareTop = tester.getTopLeft(find.text('URGENT CARE')).dy;
      final reviewsTop = tester.getTopLeft(find.text('Voices of Success')).dy;
      expect(productsTop, lessThan(urgentCareTop));
      expect(urgentCareTop, lessThan(reviewsTop));
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

    await tester.ensureVisible(find.text('Voices of Success'));
    await tester.pumpAndSettle();

    expect(find.text('Voices of Success'), findsOneWidget);
    expect(find.text('Real Patient Stories'), findsOneWidget);

    // Reviews is above Video Stories
    final reviewsTop = tester.getTopLeft(find.text('Voices of Success')).dy;
    final videosTop = tester.getTopLeft(find.text('Real Patient Stories')).dy;
    expect(reviewsTop, lessThan(videosTop));
  });

  testWidgets('HomeView displays Pending Assessment Stepper and triggers onStartHairTest', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool started = false;
    await tester.pumpWidget(
      buildHomeView(
        onStartHairTest: () {
          started = true;
        },
      ),
    );
    await tester.pumpAndSettle();

    // Verify Stepper Header and Milestone labels
    expect(find.text('Hair & Scalp Assessment'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('Pattern'), findsOneWidget);
    expect(find.text('Scalp'), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);

    // Verify Stepper CTA button and interaction
    final ctaButton = find.text('Start Free Hair Assessment');
    expect(ctaButton, findsOneWidget);

    await tester.ensureVisible(ctaButton);
    await tester.tap(ctaButton);
    await tester.pumpAndSettle();

    expect(started, isTrue);
  });
}
