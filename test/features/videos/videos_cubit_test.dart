import 'package:dr_hair/features/videos/domain/models/video_story_model.dart';
import 'package:dr_hair/features/videos/domain/repositories/video_repository.dart';
import 'package:dr_hair/features/videos/presentation/viewmodels/videos_cubit.dart';
import 'package:dr_hair/features/videos/presentation/viewmodels/videos_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideosCubit', () {
    late VideosCubit cubit;

    final sampleVideo = VideoStoryModel.fromJson({
      'id': 'vid-test-1',
      'public_id': 'cloud-test-1',
      'author_name': 'Test Patient',
      'author_handle': '@test.patient',
      'category': 'Hair Fall',
      'tag': 'Hair Fall',
      'views': 100,
      'likes': 10,
      'comments_count': 5,
      'shares': 2,
      'secure_url': 'https://res.cloudinary.com/demo/video/upload/so_0/sample.mp4',
      'thumbnail_url': 'https://images.unsplash.com/photo-1',
    });

    final dandruffVideo = VideoStoryModel.fromJson({
      'id': 'vid-test-2',
      'public_id': 'cloud-test-2',
      'author_name': 'Dandruff Patient',
      'author_handle': '@dandruff.p',
      'category': 'Dandruff',
      'tag': 'Dandruff',
      'views': 200,
      'likes': 25,
      'comments_count': 8,
      'shares': 4,
      'secure_url': 'https://res.cloudinary.com/demo/video/upload/so_0/dog.mp4',
      'thumbnail_url': 'https://images.unsplash.com/photo-2',
    });

    setUp(() {
      cubit = VideosCubit(
        repository: _FakeVideoRepository(),
        initialState: VideosState(
          videos: [sampleVideo, dandruffVideo],
          isLoading: false,
          hasMore: true,
          currentPage: 1,
        ),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has empty video list and isLoading true by default', () {
      final defaultCubit = VideosCubit();
      expect(defaultCubit.state.videos.isEmpty, true);
      expect(defaultCubit.state.selectedFilterIndex, 0);
      expect(defaultCubit.state.isLoading, true);
      defaultCubit.close();
    });

    test('filteredVideos filters stories by category index', () {
      // Dandruff is index 3
      cubit.changeFilter(3);
      expect(cubit.state.selectedFilterIndex, 3);

      // Hair Fall is index 1
      cubit.changeFilter(1);
      expect(cubit.state.selectedFilterIndex, 1);
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

    test('toggleMute toggles isMuted flag', () {
      expect(cubit.state.isMuted, false);
      cubit.toggleMute();
      expect(cubit.state.isMuted, true);
      cubit.toggleMute();
      expect(cubit.state.isMuted, false);
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

    test('loadInitialVideos loads chunk 1 dynamically from repository', () async {
      final fakeRepo = _FakeVideoRepository();
      final testCubit = VideosCubit(repository: fakeRepo);

      await testCubit.loadInitialVideos();

      expect(fakeRepo.fetchCallCount, 1);
      expect(fakeRepo.lastRequestedPage, 1);
      expect(testCubit.state.videos.length, 1);
      expect(testCubit.state.videos.first.name, 'Chunk Patient 1');
      expect(testCubit.state.hasMore, true);
      expect(testCubit.state.isLoading, false);

      testCubit.close();
    });

    test('loadNextChunk appends second chunk and updates hasMore to false',
        () async {
      final fakeRepo = _FakeVideoRepository();
      final testCubit = VideosCubit(repository: fakeRepo);

      await testCubit.loadInitialVideos();
      expect(testCubit.state.videos.length, 1);
      expect(testCubit.state.hasMore, true);

      await testCubit.loadNextChunk();
      expect(fakeRepo.lastRequestedPage, 2);
      expect(testCubit.state.videos.length, 2);
      expect(testCubit.state.videos[1].name, 'Chunk Patient 2');
      expect(testCubit.state.hasMore, false);
      expect(testCubit.state.isLoadingMore, false);

      testCubit.close();
    });

    test('changeFilter queries chunk for category', () async {
      final fakeRepo = _FakeVideoRepository();
      final testCubit = VideosCubit(repository: fakeRepo);

      await testCubit.changeFilter(2); // Regrowth
      expect(fakeRepo.lastCategory, 'Regrowth');
      expect(testCubit.state.selectedFilterIndex, 2);
      expect(testCubit.state.videos.first.category, 'Regrowth');

      testCubit.close();
    });
  });
}

class _FakeVideoRepository implements VideoRepository {
  int fetchCallCount = 0;
  int lastRequestedPage = 0;
  String? lastCategory;

  @override
  Future<({List<VideoStoryModel> items, bool hasMore, int total, int page})>
      getVideos({
    int page = 1,
    int limit = 10,
    String? category,
    String? placement = 'reels',
  }) async {
    fetchCallCount++;
    lastRequestedPage = page;
    lastCategory = category;

    if (page == 1) {
      return (
        items: [
          VideoStoryModel.fromJson({
            'id': 'vid-chunk-1',
            'public_id': 'cloud-chunk-1',
            'author_name': 'Chunk Patient 1',
            'category': category ?? 'Hair Fall',
            'tag': category ?? 'Hair Fall',
            'secure_url':
                'https://res.cloudinary.com/demo/video/upload/so_0/sample.mp4',
            'thumbnail_url': 'https://images.unsplash.com/photo-1',
          }),
        ],
        hasMore: true,
        total: 2,
        page: 1,
      );
    } else {
      return (
        items: [
          VideoStoryModel.fromJson({
            'id': 'vid-chunk-2',
            'public_id': 'cloud-chunk-2',
            'author_name': 'Chunk Patient 2',
            'category': category ?? 'Hair Fall',
            'tag': category ?? 'Hair Fall',
            'secure_url':
                'https://res.cloudinary.com/demo/video/upload/so_0/dog.mp4',
            'thumbnail_url': 'https://images.unsplash.com/photo-2',
          }),
        ],
        hasMore: false,
        total: 2,
        page: 2,
      );
    }
  }

  @override
  Future<List<String>> getVideoCategories() async {
    return const [
      'All',
      'Hair Fall',
      'Regrowth',
      'Dandruff',
      'Doctor Advice',
      'Scalp Care',
    ];
  }
}
