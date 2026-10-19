import 'package:dr_hair/features/videos/presentation/viewmodels/videos_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideosCubit', () {
    late VideosCubit cubit;

    setUp(() {
      cubit = VideosCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has correct default stories and filter at 0', () {
      expect(cubit.state.videos.isNotEmpty, true);
      expect(cubit.state.selectedFilterIndex, 0);
      expect(cubit.state.filteredVideos.length, 4);
      expect(cubit.state.filteredVideos.first.name, 'Yashveer Soni');
    });

    test('changeFilter filters stories correctly', () {
      // Dandruff is index 3
      cubit.changeFilter(3);
      expect(cubit.state.selectedFilterIndex, 3);
      expect(cubit.state.filteredVideos.length, 1);
      expect(cubit.state.filteredVideos.first.name, 'Ananya Mehra');

      // Hair Fall is index 1
      cubit.changeFilter(1);
      expect(cubit.state.filteredVideos.first.name, 'Yashveer Soni');
    });

    test('toggleLike increments and decrements likes count', () {
      final initialLikes = cubit.state.videos.first.likes;
      final videoId = cubit.state.videos.first.id;

      cubit.toggleLike(videoId);
      final likedVideo =
          cubit.state.videos.firstWhere((v) => v.id == videoId);
      expect(likedVideo.isLiked, true);
      expect(likedVideo.likes, initialLikes + 1);

      cubit.toggleLike(videoId);
      final unlikedVideo =
          cubit.state.videos.firstWhere((v) => v.id == videoId);
      expect(unlikedVideo.isLiked, false);
      expect(unlikedVideo.likes, initialLikes);
    });

    test('togglePlayPause toggles isPlaying boolean', () {
      final videoId = cubit.state.videos.first.id;
      expect(cubit.state.videos.first.isPlaying, true);

      cubit.togglePlayPause(videoId);
      expect(cubit.state.videos.first.isPlaying, false);

      cubit.togglePlayPause(videoId);
      expect(cubit.state.videos.first.isPlaying, true);
    });

    test('incrementShare increments shares count', () {
      final videoId = cubit.state.videos.first.id;
      final initialShares = cubit.state.videos.first.shares;

      cubit.incrementShare(videoId);
      expect(cubit.state.videos.first.shares, initialShares + 1);
    });

    test('onVisibilityChanged tracks view once and auto-pauses when off-screen',
        () {
      final videoId = cubit.state.videos.first.id;
      final initialViews = cubit.state.videos.first.views;

      // When visible >= 0.5, views increment and videoId is marked as viewed
      cubit.onVisibilityChanged(videoId, 0.7);
      expect(cubit.state.videos.first.views, initialViews + 1);
      expect(cubit.state.viewedVideoIds.contains(videoId), true);

      // Subsequent visibility changes do not re-increment views
      cubit.onVisibilityChanged(videoId, 0.9);
      expect(cubit.state.videos.first.views, initialViews + 1);

      // When scrolled out (< 0.2), auto-pauses
      cubit.onVisibilityChanged(videoId, 0.1);
      expect(cubit.state.videos.first.isPlaying, false);
    });

    test('onPageChanged updates activeIndex and sets active video playing',
        () {
      cubit.onPageChanged(1);
      expect(cubit.state.activeIndex, 1);
      expect(cubit.state.videos[1].isPlaying, true);
      expect(cubit.state.videos[0].isPlaying, false);
    });
  });
}
