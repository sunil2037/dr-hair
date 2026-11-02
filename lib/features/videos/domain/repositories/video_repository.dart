import '../models/video_story_model.dart';

abstract class VideoRepository {
  Future<({List<VideoStoryModel> items, bool hasMore, int total, int page})>
      getVideos({
    int page = 1,
    int limit = 10,
    String? category,
    String? placement = 'reels',
  });
}
