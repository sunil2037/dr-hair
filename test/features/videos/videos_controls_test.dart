import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/features/videos/presentation/views/videos_view.dart';
import 'package:dr_hair/features/videos/presentation/viewmodels/videos_cubit.dart';
import 'package:dr_hair/features/videos/presentation/viewmodels/videos_state.dart';
import 'package:dr_hair/features/videos/domain/models/video_story_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('VideosView supports play/pause tap, mute toggle, and vertical page swipe',
      (tester) async {
    final testVideos = VideoStoryModel.testStories;
    final cubit = VideosCubit(
      initialState: VideosState(
        videos: testVideos,
        filters: const ['All Stories', 'PRP Therapy'],
        isLoading: false,
        activeIndex: 0,
        isMuted: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VideosView(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial active video is playing
    expect(cubit.state.videos.first.isPlaying, true);
    expect(cubit.state.isMuted, false);

    // Tap to pause the video
    await tester.tap(find.byKey(const Key('reel_gesture_detector')).first);
    await tester.pump(const Duration(milliseconds: 350));

    // Cubit should reflect paused state
    expect(cubit.state.videos.first.isPlaying, false);

    // Tap Mute action button
    final muteButton = find.byIcon(LucideIcons.volume2);
    expect(muteButton, findsOneWidget);
    await tester.tap(muteButton);
    await tester.pump();

    // Cubit should reflect muted state
    expect(cubit.state.isMuted, true);
    expect(find.byIcon(LucideIcons.volumeX), findsOneWidget);

    // Unmute
    await tester.tap(find.byIcon(LucideIcons.volumeX));
    await tester.pump();
    expect(cubit.state.isMuted, false);

    // Slide bottom to top (drag up) to change video
    await tester.drag(find.byType(PageView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // Active index should now be 1 and second video should be playing
    expect(cubit.state.activeIndex, 1);
    expect(cubit.state.videos[1].isPlaying, true);
    expect(cubit.state.videos[0].isPlaying, false);
  });
}
