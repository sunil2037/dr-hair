import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/video_story_model.dart';
import 'videos_state.dart';

class VideosCubit extends Cubit<VideosState> {
  VideosCubit({VideosState? initialState})
      : super(initialState ?? VideosState.initial());

  void changeFilter(int index) {
    if (index < 0 || index >= state.filters.length) return;
    emit(state.copyWith(
      selectedFilterIndex: index,
      activeIndex: 0,
    ));
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
      final video = updatedVideos.firstWhere((v) => v.id == videoId);
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
