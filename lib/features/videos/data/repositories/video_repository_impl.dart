import '../../domain/models/video_story_model.dart';
import '../../domain/repositories/video_repository.dart';
import '../datasources/video_remote_data_source.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoRemoteDataSource _remoteDataSource;

  VideoRepositoryImpl({VideoRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? VideoRemoteDataSource();

  @override
  Future<({List<VideoStoryModel> items, bool hasMore, int total, int page})>
  getVideos({
    int page = 1,
    int limit = 10,
    String? category,
    String? placement = 'reels',
  }) async {
    try {
      final result = await _remoteDataSource.fetchVideos(
        page: page,
        limit: limit,
        category: category,
        placement: placement,
      );
      return result;
    } catch (_) {
      // Never hide an API outage with local stories.
      rethrow;
    }
  }
}
