import '../../domain/models/video_story_model.dart';

class VideosState {
  final List<VideoStoryModel> videos;
  final int selectedFilterIndex;
  final List<String> filters;
  final int activeIndex;
  final bool isMuted;
  final Set<String> viewedVideoIds;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  const VideosState({
    this.videos = const [],
    this.selectedFilterIndex = 0,
    this.filters = const ['All', 'Hair Fall', 'Regrowth', 'Dandruff'],
    this.activeIndex = 0,
    this.isMuted = false,
    this.viewedVideoIds = const {},
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.errorMessage,
  });

  factory VideosState.initial() => const VideosState(
        videos: [],
        isLoading: true,
        hasMore: true,
        currentPage: 1,
      );

  List<VideoStoryModel> get filteredVideos {
    if (selectedFilterIndex == 0) return videos;
    final filter = filters[selectedFilterIndex].toLowerCase();
    return videos.where((v) {
      final tag = v.tag.toLowerCase();
      final category = v.category.toLowerCase();
      return tag.contains(filter) || category.contains(filter);
    }).toList();
  }

  VideosState copyWith({
    List<VideoStoryModel>? videos,
    int? selectedFilterIndex,
    List<String>? filters,
    int? activeIndex,
    bool? isMuted,
    Set<String>? viewedVideoIds,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
  }) {
    return VideosState(
      videos: videos ?? this.videos,
      selectedFilterIndex: selectedFilterIndex ?? this.selectedFilterIndex,
      filters: filters ?? this.filters,
      activeIndex: activeIndex ?? this.activeIndex,
      isMuted: isMuted ?? this.isMuted,
      viewedVideoIds: viewedVideoIds ?? this.viewedVideoIds,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
