import 'package:dr_hair/features/videos/domain/models/video_story_model.dart';
import 'package:dr_hair/features/videos/presentation/viewmodels/videos_cubit.dart';
import 'package:dr_hair/features/videos/presentation/viewmodels/videos_state.dart';
import 'package:dr_hair/features/videos/presentation/views/videos_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  testWidgets('VideosView renders header and filters with dynamic video stories',
      (tester) async {
    final story1 = VideoStoryModel.fromJson({
      'id': 'vid-1',
      'public_id': 'cloud-1',
      'author_name': 'Yashveer Soni',
      'author_handle': '@yashveer.soni',
      'category': 'Hair Fall',
      'tag': 'Hair Fall',
      'secure_url': 'https://res.cloudinary.com/demo/video/upload/so_0/sample.mp4',
      'thumbnail_url': 'https://images.unsplash.com/photo-1',
    });
    final story2 = VideoStoryModel.fromJson({
      'id': 'vid-2',
      'public_id': 'cloud-2',
      'author_name': 'Ananya Mehra',
      'author_handle': '@ananya.mehra',
      'category': 'Dandruff',
      'tag': 'Dandruff',
      'secure_url': 'https://res.cloudinary.com/demo/video/upload/so_0/dog.mp4',
      'thumbnail_url': 'https://images.unsplash.com/photo-2',
    });

    final cubit = VideosCubit(
      initialState: VideosState(
        videos: [story1, story2],
        isLoading: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VideosView(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    // Category filter chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Hair Fall'), findsOneWidget);
    expect(find.text('Regrowth'), findsOneWidget);
    expect(find.text('Dandruff'), findsOneWidget);

    // Initial state shows Yashveer Soni
    expect(find.text('Yashveer Soni'), findsOneWidget);

    // Switch filter to Dandruff
    await tester.tap(find.text('Dandruff'));
    await tester.pumpAndSettle();

    // Now Ananya Mehra is visible
    expect(find.text('Ananya Mehra'), findsOneWidget);
    expect(find.text('Yashveer Soni'), findsNothing);

    cubit.close();
  });

  testWidgets(
      'VideosView uses Skeletonizer during loading without CircularProgressIndicator',
      (tester) async {
    final loadingCubit = VideosCubit(
      initialState: const VideosState(
        isLoading: true,
        videos: [],
        filters: ['All', 'Hair Fall', 'Regrowth', 'Dandruff'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VideosView(cubit: loadingCubit),
      ),
    );
    await tester.pump();

    // Verifies Skeletonizer is actively rendered
    expect(
      find.byWidgetPredicate((widget) => widget is Skeletonizer),
      findsAtLeastNWidgets(1),
    );

    // Verifies NO CircularProgressIndicator is rendered on screen
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    loadingCubit.close();
  });

  testWidgets('VideosView parses and renders Cloudinary video model',
      (tester) async {
    final cloudinaryVideo = VideoStoryModel.fromJson({
      'id': 'vid-cloud-1',
      'public_id': 'drhair/videos/sample_reel',
      'author_name': 'Kavita Chawla',
      'author_handle': '@kavita.c',
      'category': 'Hair Fall',
      'tag': 'Hair Fall',
      'duration': '0:45',
      'views': 12000,
      'likes': 850,
      'comments_count': 64,
      'shares': 42,
      'description': 'Regrowth journey using Cloudinary hosted video streams.',
      'treatment': 'Scalp Redensyl Protocol',
      'thumbnail_url': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
      'avatar_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      'secure_url': 'https://res.cloudinary.com/demo/video/upload/so_0/sample.mp4',
    });

    final testCubit = VideosCubit(
      initialState: VideosState(
        videos: [cloudinaryVideo],
        isLoading: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VideosView(cubit: testCubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kavita Chawla'), findsOneWidget);
    expect(
      find.text('Hair Fall • Scalp Redensyl Protocol'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);

    testCubit.close();
  });

  testWidgets('VideosView renders Sound/Muted toggle button and toggles state',
      (tester) async {
    final story = VideoStoryModel.fromJson({
      'id': 'vid-mute-1',
      'public_id': 'cloud-mute-1',
      'author_name': 'Audio Test Patient',
      'author_handle': '@audio.patient',
      'category': 'Hair Fall',
      'tag': 'Hair Fall',
      'secure_url': 'https://res.cloudinary.com/demo/video/upload/so_0/sample.mp4',
      'thumbnail_url': 'https://images.unsplash.com/photo-1',
    });

    final cubit = VideosCubit(
      initialState: VideosState(
        videos: [story],
        isLoading: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VideosView(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sound'), findsOneWidget);
    await tester.tap(find.text('Sound'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Muted'), findsOneWidget);
    cubit.close();
  });

  testWidgets(
      'VideosView opens and displays target video when initialVideoId is passed',
      (tester) async {
    final story1 = VideoStoryModel.fromJson({
      'id': 'vid-1',
      'public_id': 'cloud-1',
      'author_name': 'Yashveer Soni',
      'author_handle': '@yashveer.soni',
      'category': 'Hair Fall',
      'tag': 'Hair Fall',
      'secure_url': 'https://res.cloudinary.com/demo/video/upload/so_0/sample.mp4',
      'thumbnail_url': 'https://images.unsplash.com/photo-1',
    });
    final story2 = VideoStoryModel.fromJson({
      'id': 'vid-2',
      'public_id': 'cloud-2',
      'author_name': 'Ananya Mehra',
      'author_handle': '@ananya.mehra',
      'category': 'Dandruff',
      'tag': 'Dandruff',
      'secure_url': 'https://res.cloudinary.com/demo/video/upload/so_0/dog.mp4',
      'thumbnail_url': 'https://images.unsplash.com/photo-2',
    });

    final cubit = VideosCubit(
      initialState: VideosState(
        videos: [story1, story2],
        isLoading: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VideosView(
          cubit: cubit,
          initialVideoId: 'vid-2',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(cubit.state.activeIndex, 1);
    expect(find.text('Ananya Mehra'), findsOneWidget);
    cubit.close();
  });
}
