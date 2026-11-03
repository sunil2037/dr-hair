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
    final publicId = json['public_id']?.toString() ?? json['publicId']?.toString();
    final id = json['id']?.toString() ?? publicId ?? '';
    final name = json['author_name']?.toString() ?? json['name']?.toString() ?? 'Dr. Hair Patient';
    final handle = json['author_handle']?.toString() ?? json['handle']?.toString() ?? '@drhair.patient';
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
    final caption = json['description']?.toString() ?? json['caption']?.toString() ?? '';
    final treatment = json['treatment']?.toString() ?? 'Clinical Hair Care Protocol';
    final rawThumbnail = json['thumbnail_url']?.toString() ?? json['thumbnail']?.toString() ?? '';
    final avatar = json['avatar_url']?.toString() ?? json['avatar']?.toString() ?? '';
    final videoUrl = json['secure_url']?.toString() ??
        json['video_url']?.toString() ??
        json['videoUrl']?.toString() ??
        '';

    final explicitYtId = json['youtube_video_id']?.toString();
    String? resolvedYtId = explicitYtId;
    if (resolvedYtId == null || resolvedYtId.isEmpty) {
      if (publicId != null && publicId.startsWith('youtube-')) {
        resolvedYtId = publicId.substring(8);
      } else if (videoUrl.isNotEmpty) {
        final match = RegExp(r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|shorts\/))([a-zA-Z0-9_-]{11})').firstMatch(videoUrl);
        if (match != null) resolvedYtId = match.group(1);
      }
    }

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

  String? get youtubeVideoId {
    if (publicId != null && publicId!.startsWith('youtube-')) {
      final candidate = publicId!.substring(8);
      if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(candidate)) {
        return candidate;
      }
    }
    if (videoUrl.isNotEmpty) {
      final match = RegExp(r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|shorts\/))([a-zA-Z0-9_-]{11})').firstMatch(videoUrl);
      if (match != null) return match.group(1);
    }
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)) return id;
    return null;
  }

  bool get isYouTubeVideo => youtubeVideoId != null;

  String get effectiveThumbnail {
    if (thumbnail.isNotEmpty) return thumbnail;
    final ytid = youtubeVideoId;
    if (ytid != null) return 'https://i.ytimg.com/vi/$ytid/hqdefault.jpg';
    return '';
  }

  static List<VideoStoryModel> get initialStories => const [];

  /// Explicit test fixture for automated widget/unit test mocking.
  static List<VideoStoryModel> get testStories => [
        const VideoStoryModel(
          id: 'vid-yt-1',
          publicId: 'youtube-7uC1_O7kZ8I',
          name: 'Dr. Jai Bansal',
          handle: '@dr.jai.bansal',
          category: 'Hair Fall',
          tag: 'Hair Fall',
          duration: '1:00',
          views: 52400,
          likes: 3120,
          commentsCount: 248,
          shares: 120,
          caption:
              'Dr. Hair protocol helped regain crown density naturally. Noticeable reduction in shedding within 6 weeks, and density improved dramatically in 4 months.',
          treatment: 'Scalp Serum + Minoxidil 5%',
          videoUrl: 'https://www.youtube.com/watch?v=7uC1_O7kZ8I',
          thumbnail: 'https://i.ytimg.com/vi/7uC1_O7kZ8I/hqdefault.jpg',
          avatar:
              'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=200',
          comments: [
            VideoComment(
              id: 'c1',
              user: 'Vikram Rathore',
              time: '2h ago',
              text:
                  'Did you experience any initial shedding when starting minoxidil?',
              likes: 24,
            ),
            VideoComment(
              id: 'c2',
              user: 'Dr. Jai Bansal',
              time: '1h ago',
              text:
                  'Great adherence! Follicular miniaturization has clearly halted.',
              likes: 68,
            ),
          ],
        ),
        const VideoStoryModel(
          id: 'vid-yt-2',
          publicId: 'youtube-kJQP7kiw5Fk',
          name: 'Rahul Sharma',
          handle: '@rahul.sharma',
          category: 'Regrowth',
          tag: 'Regrowth',
          duration: '0:45',
          views: 41200,
          likes: 2890,
          commentsCount: 312,
          shares: 175,
          caption:
              'My follicle density noticeably improved in just 3 months! Genetic hair fall completely halted without surgery.',
          treatment: 'DHT Blocker Kit + Redensyl',
          videoUrl: 'https://www.youtube.com/watch?v=kJQP7kiw5Fk',
          thumbnail: 'https://i.ytimg.com/vi/kJQP7kiw5Fk/hqdefault.jpg',
          avatar:
              'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=200',
          comments: [
            VideoComment(
              id: 'c4',
              user: 'Sameer Sen',
              time: '4h ago',
              text: 'How long until you saw baby hairs around the temples?',
              likes: 19,
            ),
          ],
        ),
        const VideoStoryModel(
          id: 'vid-yt-3',
          publicId: 'youtube-L_LUpnjgPso',
          name: 'Ananya Mehra',
          handle: '@ananya.mehra',
          category: 'Dandruff',
          tag: 'Dandruff',
          duration: '0:55',
          views: 35400,
          likes: 3420,
          commentsCount: 420,
          shares: 210,
          caption:
              'Severe flakes and itching cleared within 3 weeks of the kit. Scalp feels clean and refreshed every single day.',
          treatment: 'Ketoconazole 2% + Salicylic Wash',
          videoUrl: 'https://www.youtube.com/watch?v=L_LUpnjgPso',
          thumbnail: 'https://i.ytimg.com/vi/L_LUpnjgPso/hqdefault.jpg',
          avatar:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200',
          comments: [
            VideoComment(
              id: 'c7',
              user: 'Rhea Kapoor',
              time: '5h ago',
              text: 'Does it dry out the hair shaft after washing?',
              likes: 45,
            ),
          ],
        ),
        const VideoStoryModel(
          id: 'vid-yt-4',
          publicId: 'youtube-fJ9rUzIMcZQ',
          name: 'Aarav Patel',
          handle: '@aarav.patel',
          category: 'Regrowth',
          tag: 'Regrowth',
          duration: '0:50',
          views: 18900,
          likes: 980,
          commentsCount: 86,
          shares: 45,
          caption:
              'Doctor consultation was transparent and totally tailored. Hairline has started filling in with thick baby hairs.',
          treatment: 'Scalp Peptide + Biotin Booster',
          videoUrl: 'https://www.youtube.com/watch?v=fJ9rUzIMcZQ',
          thumbnail: 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
          avatar:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200',
          comments: [
            VideoComment(
              id: 'c6',
              user: 'Harsh Gupta',
              time: '1d ago',
              text: 'Biotin booster worked like magic for me too!',
              likes: 8,
            ),
          ],
        ),
      ];
}
