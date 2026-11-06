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

  Future<void> loadInitialVideos({String? initialVideoId}) async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final category = _categoryForIndex(state.selectedFilterIndex);
      final videosFuture = _repository.getVideos(
        page: 1,
        limit: 10,
        category: category,
        placement: 'reels',
      );
      final categoriesFuture = _repository.getVideoCategories();

      final results = await Future.wait([
        videosFuture,
        categoriesFuture,
      ]);

      if (isClosed) return;

      final result = results[0] as ({
        List<VideoStoryModel> items,
        bool hasMore,
        int total,
        int page
      });
      final categories = results[1] as List<String>;

      int targetIndex = 0;
      if (initialVideoId != null && initialVideoId.isNotEmpty) {
        final found = result.items.indexWhere((v) =>
            v.id == initialVideoId ||
            v.publicId == initialVideoId ||
            v.youtubeVideoId == initialVideoId);
        if (found != -1) {
          targetIndex = found;
        }
      }

      final updatedVideos = result.items.asMap().entries.map((entry) {
        final idx = entry.key;
        final v = entry.value;
        return v.copyWith(isPlaying: idx == targetIndex);
      }).toList();

      emit(state.copyWith(
        videos: updatedVideos,
        filters: categories.isNotEmpty ? categories : state.filters,
        hasMore: result.hasMore,
        currentPage: result.page,
        isLoading: false,
        activeIndex: targetIndex,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load videos: $e',
      ));
    }
  }

  Future<void> loadCategories() async {
    if (isClosed) return;
    try {
      final categories = await _repository.getVideoCategories();
      if (!isClosed && categories.isNotEmpty) {
        emit(state.copyWith(filters: categories));
      }
    } catch (_) {}
  }

  Future<void> loadNextChunk() async {
    if (isClosed || state.isLoadingMore || !state.hasMore || state.isLoading) return;

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

      if (isClosed) return;

      final existingIds = state.videos.map((v) => v.id).toSet();
      final newItems = result.items.where((v) => !existingIds.contains(v.id)).toList();

      emit(state.copyWith(
        videos: [...state.videos, ...newItems],
        hasMore: result.hasMore,
        currentPage: result.page,
        isLoadingMore: false,
      ));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> refresh() async {
    await loadInitialVideos();
  }

  Future<void> changeFilter(int index) async {
    if (isClosed || index < 0 || index >= state.filters.length) return;

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

      if (isClosed) return;

      final updatedVideos = result.items.asMap().entries.map((entry) {
        return entry.value.copyWith(isPlaying: entry.key == 0);
      }).toList();

      emit(state.copyWith(
        videos: updatedVideos,
        hasMore: result.hasMore,
        currentPage: result.page,
        isLoading: false,
        activeIndex: 0,
      ));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false));
      }
    }
  }

  int selectVideoById(String targetId) {
    if (isClosed) return -1;
    final filtered = state.filteredVideos;
    final index = filtered.indexWhere((v) =>
        v.id == targetId ||
        v.publicId == targetId ||
        v.youtubeVideoId == targetId);
    if (index != -1) {
      onPageChanged(index);
      return index;
    }
    return -1;
  }

  void onPageChanged(int index) {
    if (isClosed) return;
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
    if (isClosed) return;
    final updatedVideos = state.videos.map((v) {
      if (v.id == videoId) {
        return v.copyWith(isPlaying: !v.isPlaying);
      }
      return v;
    }).toList();

    emit(state.copyWith(videos: updatedVideos));
  }

  void toggleLike(String videoId) {
    if (isClosed) return;
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
    if (isClosed) return;
    final updatedVideos = state.videos.map((v) {
      if (v.id == videoId) {
        return v.copyWith(isSaved: !v.isSaved);
      }
      return v;
    }).toList();

    emit(state.copyWith(videos: updatedVideos));
  }

  void toggleMute() {
    if (isClosed) return;
    emit(state.copyWith(isMuted: !state.isMuted));
  }

  void incrementShare(String videoId) {
    if (isClosed) return;
    final updatedVideos = state.videos.map((v) {
      if (v.id == videoId) {
        return v.copyWith(shares: v.shares + 1);
      }
      return v;
    }).toList();

    emit(state.copyWith(videos: updatedVideos));
  }

  void addComment(String videoId, String text) {
    if (isClosed) return;
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
  /// Counts as viewed when at least 50% visible and not viewed yet.
  /// Auto-pauses when scrolled out of view (< 20%).
  void onVisibilityChanged(String videoId, double visibleFraction) {
    if (isClosed) return;
    bool hasChanges = false;
    Set<String> updatedViewed = state.viewedVideoIds;
    List<VideoStoryModel> updatedVideos = state.videos;

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

    if (visibleFraction < 0.2) {
      final index = updatedVideos.indexWhere((v) => v.id == videoId);
      if (index != -1 && updatedVideos[index].isPlaying) {
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

  /// Pauses all video playback immediately (e.g. app sent to background, screen disposed).
  void pauseAll() {
    if (isClosed) return;
    final updatedVideos = state.videos.map((v) => v.copyWith(isPlaying: false)).toList();
    emit(state.copyWith(videos: updatedVideos));
  }
}
