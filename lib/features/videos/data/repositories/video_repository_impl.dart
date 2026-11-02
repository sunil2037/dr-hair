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
      if (result.items.isNotEmpty) {
        return result;
      }
    } catch (_) {
      // Gracefully fall back to local seed stories if backend is unreachable
    }

    final all = VideoStoryModel.initialStories;
    final filtered = (category == null || category == 'All')
        ? all
        : all.where((v) {
            final tag = v.tag.toLowerCase();
            final cat = v.category.toLowerCase();
            final query = category.toLowerCase();
            return tag.contains(query) || cat.contains(query);
          }).toList();

    return (
      items: filtered,
      hasMore: false,
      total: filtered.length,
      page: 1,
    );
  }
}
