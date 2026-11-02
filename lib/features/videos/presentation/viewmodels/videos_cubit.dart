import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/video_repository_impl.dart';
import '../../domain/models/video_story_model.dart';
import '../../domain/repositories/video_repository.dart';
import 'videos_state.dart';

class VideosCubit extends Cubit<VideosState> {
  final VideoRepository _repository;

  VideosCubit({
    VideoRepository? repository,
    VideosState? initialState,
  })  : _repository = repository ?? VideoRepositoryImpl(),
        super(initialState ?? VideosState.initial());

  String? _categoryForIndex(int index) {
    if (index <= 0 || index >= state.filters.length) return null;
    return state.filters[index];
  }

  Future<void> loadInitialVideos() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final category = _categoryForIndex(state.selectedFilterIndex);
      final result = await _repository.getVideos(
        page: 1,
        limit: 10,
        category: category,
        placement: 'reels',
      );

      emit(state.copyWith(
        videos: result.items,
        hasMore: result.hasMore,
        currentPage: result.page,
        isLoading: false,
        activeIndex: 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load videos: $e',
      ));
    }
  }

  Future<void> loadNextChunk() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.currentPage + 1;
      final category = _categoryForIndex(state.selectedFilterIndex);
      final result = await _repository.getVideos(
        page: nextPage,
        limit: 10,
        category: category,
        placement: 'reels',
      );

      final existingIds = state.videos.map((v) => v.id).toSet();
      final newItems = result.items.where((v) => !existingIds.contains(v.id)).toList();

      emit(state.copyWith(
        videos: [...state.videos, ...newItems],
        hasMore: result.hasMore,
        currentPage: result.page,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() async {
    await loadInitialVideos();
  }

  Future<void> changeFilter(int index) async {
    if (index < 0 || index >= state.filters.length) return;

    emit(state.copyWith(
      selectedFilterIndex: index,
      activeIndex: 0,
      isLoading: true,
      currentPage: 1,
    ));

    try {
      final category = _categoryForIndex(index);
      final result = await _repository.getVideos(
        page: 1,
        limit: 10,
        category: category,
        placement: 'reels',
      );

      emit(state.copyWith(
        videos: result.items,
        hasMore: result.hasMore,
        currentPage: result.page,
        isLoading: false,
        activeIndex: 0,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void onPageChanged(int index) {
    final filtered = state.filteredVideos;
    if (index < 0 || index >= filtered.length) return;

    final targetId = filtered[index].id;
    final updatedVideos = state.videos.map((v) {
      if (v.id == targetId) {
        return v.copyWith(isPlaying: true);
      } else {
        return v.copyWith(isPlaying: false);
      }
    }).toList();

    emit(state.copyWith(
      videos: updatedVideos,
      activeIndex: index,
    ));

    // Trigger chunk loading when approaching end of reels
    if (index >= filtered.length - 2 && state.hasMore && !state.isLoadingMore) {
      loadNextChunk();
    }
  }

  void togglePlayPause(String videoId) {
    final updatedVideos = state.videos.map((v) {
      if (v.id == videoId) {
        return v.copyWith(isPlaying: !v.isPlaying);
      }
      return v;
    }).toList();

    emit(state.copyWith(videos: updatedVideos));
  }

  void toggleLike(String videoId) {
    final updatedVideos = state.videos.map((v) {
      if (v.id == videoId) {
        final newIsLiked = !v.isLiked;
        final newLikes = newIsLiked ? v.likes + 1 : v.likes - 1;
        return v.copyWith(
          isLiked: newIsLiked,
          likes: newLikes < 0 ? 0 : newLikes,
        );
      }
      return v;
    }).toList();

    emit(state.copyWith(videos: updatedVideos));
  }

  void toggleSave(String videoId) {
    final updatedVideos = state.videos.map((v) {
      if (v.id == videoId) {
        return v.copyWith(isSaved: !v.isSaved);
      }
      return v;
    }).toList();

    emit(state.copyWith(videos: updatedVideos));
  }

  void toggleMute() {
    emit(state.copyWith(isMuted: !state.isMuted));
  }

  void incrementShare(String videoId) {
    final updatedVideos = state.videos.map((v) {
      if (v.id == videoId) {
        return v.copyWith(shares: v.shares + 1);
      }
      return v;
    }).toList();

    emit(state.copyWith(videos: updatedVideos));
  }

  void addComment(String videoId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final newComment = VideoComment(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      user: 'You',
      time: 'Just now',
      text: trimmed,
      likes: 0,
    );

    final updatedVideos = state.videos.map((v) {
      if (v.id == videoId) {
        final updatedComments = [newComment, ...v.comments];
        return v.copyWith(
          comments: updatedComments,
          commentsCount: v.commentsCount + 1,
        );
      }
      return v;
    }).toList();

    emit(state.copyWith(videos: updatedVideos));
  }

  /// Triggered by VisibilityDetector when a reel's visible percentage changes.
  /// - Automatically increments views on first viewport intersection (>= 50%).
  /// - Auto-pauses when scrolled out of view (< 20%).
  void onVisibilityChanged(String videoId, double visibleFraction) {
    bool hasChanges = false;
    Set<String> updatedViewed = state.viewedVideoIds;
    List<VideoStoryModel> updatedVideos = state.videos;

    // View detection: Count as viewed when at least 50% visible and not viewed yet
    if (visibleFraction >= 0.5 && !state.viewedVideoIds.contains(videoId)) {
      updatedViewed = {...state.viewedVideoIds, videoId};
      updatedVideos = updatedVideos.map((v) {
        if (v.id == videoId) {
          return v.copyWith(views: v.views + 1);
        }
        return v;
      }).toList();
      hasChanges = true;
    }

    // Auto-pause if video scrolls far out of view
    if (visibleFraction < 0.2) {
      final video = updatedVideos.firstWhere(
        (v) => v.id == videoId,
        orElse: () => updatedVideos.first,
      );
      if (video.isPlaying) {
        updatedVideos = updatedVideos.map((v) {
          if (v.id == videoId) return v.copyWith(isPlaying: false);
          return v;
        }).toList();
        hasChanges = true;
      }
    }

    if (hasChanges) {
      emit(state.copyWith(
        videos: updatedVideos,
        viewedVideoIds: updatedViewed,
      ));
    }
  }
}
