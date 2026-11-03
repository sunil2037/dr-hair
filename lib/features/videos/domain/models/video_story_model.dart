class VideoComment {
  final String id;
  final String user;
  final String time;
  final String text;
  final int likes;

  const VideoComment({
    required this.id,
    required this.user,
    required this.time,
    required this.text,
    this.likes = 0,
  });

  VideoComment copyWith({
    String? id,
    String? user,
    String? time,
    String? text,
    int? likes,
  }) {
    return VideoComment(
      id: id ?? this.id,
      user: user ?? this.user,
      time: time ?? this.time,
      text: text ?? this.text,
      likes: likes ?? this.likes,
    );
  }
}

class VideoStoryModel {
  final String id;
  final String? publicId;
  final String name;
  final String handle;
  final String category;
  final String tag;
  final String duration;
  final int views;
  final int likes;
  final int commentsCount;
  final int shares;
  final bool isLiked;
  final bool isSaved;
  final bool isPlaying;
  final String caption;
  final String treatment;
  final String thumbnail;
  final String avatar;
  final String videoUrl;
  final List<VideoComment> comments;

  const VideoStoryModel({
    required this.id,
    this.publicId,
    required this.name,
    required this.handle,
    required this.category,
    required this.tag,
    required this.duration,
    required this.views,
    required this.likes,
    required this.commentsCount,
    required this.shares,
    required this.caption,
    required this.treatment,
    required this.thumbnail,
    required this.avatar,
    this.videoUrl = '',
    this.isLiked = false,
    this.isSaved = false,
    this.isPlaying = true,
    this.comments = const [],
  });

  factory VideoStoryModel.fromJson(Map<String, dynamic> json) {
    final publicId =
        json['public_id']?.toString() ?? json['publicId']?.toString();
    final id = json['id']?.toString() ?? publicId ?? '';
    final name =
        json['author_name']?.toString() ??
        json['name']?.toString() ??
        'Dr. Hair Patient';
    final handle =
        json['author_handle']?.toString() ??
        json['handle']?.toString() ??
        '@drhair.patient';
    final category = json['category']?.toString() ?? 'Hair Care';
    final tag = json['tag']?.toString() ?? category;
    final duration = json['duration']?.toString() ?? '1:00';
    final views = (json['views'] is num)
        ? (json['views'] as num).toInt()
        : int.tryParse(json['views']?.toString() ?? '0') ?? 0;
    final likes = (json['likes'] is num)
        ? (json['likes'] as num).toInt()
        : int.tryParse(json['likes']?.toString() ?? '0') ?? 0;
    final commentsCount = (json['comments_count'] is num)
        ? (json['comments_count'] as num).toInt()
        : (json['commentsCount'] is num)
        ? (json['commentsCount'] as num).toInt()
        : 0;
    final shares = (json['shares'] is num)
        ? (json['shares'] as num).toInt()
        : int.tryParse(json['shares']?.toString() ?? '0') ?? 0;
    final caption =
        json['description']?.toString() ?? json['caption']?.toString() ?? '';
    final treatment =
        json['treatment']?.toString() ?? 'Clinical Hair Care Protocol';
    final rawThumbnail =
        json['thumbnail_url']?.toString() ??
        json['thumbnail']?.toString() ??
        '';
    final avatar =
        json['avatar_url']?.toString() ?? json['avatar']?.toString() ?? '';
    final videoUrl =
        json['secure_url']?.toString() ??
        json['video_url']?.toString() ??
        json['videoUrl']?.toString() ??
        '';

    final explicitYtId = json['youtube_video_id']?.toString();
    final resolvedYtId = (explicitYtId != null && explicitYtId.isNotEmpty)
        ? explicitYtId
        : extractYouTubeVideoId(publicId) ?? extractYouTubeVideoId(videoUrl);

    final thumbnail = rawThumbnail.isNotEmpty
        ? rawThumbnail
        : (resolvedYtId != null && resolvedYtId.isNotEmpty)
        ? 'https://i.ytimg.com/vi/$resolvedYtId/hqdefault.jpg'
        : '';

    return VideoStoryModel(
      id: id,
      publicId: publicId,
      name: name,
      handle: handle,
      category: category,
      tag: tag,
      duration: duration,
      views: views,
      likes: likes,
      commentsCount: commentsCount,
      shares: shares,
      caption: caption,
      treatment: treatment,
      thumbnail: thumbnail,
      avatar: avatar,
      videoUrl: videoUrl,
      isLiked: json['is_liked'] == true || json['isLiked'] == true,
      isSaved: json['is_saved'] == true || json['isSaved'] == true,
      isPlaying: true,
      comments: const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'public_id': publicId,
      'name': name,
      'handle': handle,
      'category': category,
      'tag': tag,
      'duration': duration,
      'views': views,
      'likes': likes,
      'comments_count': commentsCount,
      'shares': shares,
      'caption': caption,
      'treatment': treatment,
      'thumbnail': thumbnail,
      'avatar': avatar,
      'video_url': videoUrl,
      'is_liked': isLiked,
      'is_saved': isSaved,
    };
  }

  VideoStoryModel copyWith({
    String? id,
    String? publicId,
    String? name,
    String? handle,
    String? category,
    String? tag,
    String? duration,
    int? views,
    int? likes,
    int? commentsCount,
    int? shares,
    bool? isLiked,
    bool? isSaved,
    bool? isPlaying,
    String? caption,
    String? treatment,
    String? thumbnail,
    String? avatar,
    String? videoUrl,
    List<VideoComment>? comments,
  }) {
    return VideoStoryModel(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      category: category ?? this.category,
      tag: tag ?? this.tag,
      duration: duration ?? this.duration,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isPlaying: isPlaying ?? this.isPlaying,
      caption: caption ?? this.caption,
      treatment: treatment ?? this.treatment,
      thumbnail: thumbnail ?? this.thumbnail,
      avatar: avatar ?? this.avatar,
      videoUrl: videoUrl ?? this.videoUrl,
      comments: comments ?? this.comments,
    );
  }

  String get formattedViews {
    if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  String get formattedLikes {
    if (likes >= 1000) {
      return '${(likes / 1000).toStringAsFixed(1)}K';
    }
    return likes.toString();
  }

  String get formattedShares {
    if (shares >= 1000) {
      return '${(shares / 1000).toStringAsFixed(1)}K';
    }
    return shares.toString();
  }

  static String? extractYouTubeVideoId(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final trimmed = input.trim();
    if (trimmed.startsWith('youtube-')) {
      final candidate = trimmed.substring(8);
      if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(candidate)) {
        return candidate;
      }
    }
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }
    final match = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?(?:.*&)?v=|shorts\/|live\/))([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) return match.group(1);

    final paramMatch = RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})').firstMatch(trimmed);
    if (paramMatch != null) return paramMatch.group(1);

    return null;
  }

  String? get youtubeVideoId {
    return extractYouTubeVideoId(publicId) ??
        extractYouTubeVideoId(videoUrl) ??
        extractYouTubeVideoId(id);
  }

  bool get isYouTubeVideo => youtubeVideoId != null;

  String get effectiveThumbnail {
    if (thumbnail.isNotEmpty) return thumbnail;
    final ytid = youtubeVideoId;
    if (ytid != null) return 'https://i.ytimg.com/vi/$ytid/hqdefault.jpg';
    return '';
  }

  String get maxResThumbnail {
    if (thumbnail.isNotEmpty) return thumbnail;
    final ytid = youtubeVideoId;
    if (ytid != null) return 'https://i.ytimg.com/vi/$ytid/maxresdefault.jpg';
    return '';
  }

  static List<VideoStoryModel> get initialStories => const [];

  /// Explicit test fixture for automated widget/unit test mocking.
  static List<VideoStoryModel> get testStories => [];
}
