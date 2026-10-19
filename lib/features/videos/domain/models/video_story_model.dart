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
  final List<VideoComment> comments;

  const VideoStoryModel({
    required this.id,
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
    this.isLiked = false,
    this.isSaved = false,
    this.isPlaying = true,
    this.comments = const [],
  });

  VideoStoryModel copyWith({
    String? id,
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
    List<VideoComment>? comments,
  }) {
    return VideoStoryModel(
      id: id ?? this.id,
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

  static List<VideoStoryModel> get initialStories => const [
        VideoStoryModel(
          id: '1',
          name: 'Yashveer Soni',
          handle: '@yashveer.soni',
          category: 'Hair Fall Recovery',
          tag: 'Hair Fall',
          duration: '3:45',
          views: 24800,
          likes: 1420,
          commentsCount: 184,
          shares: 92,
          caption:
              'I finally found a clinical solution that actually works! Follicle density improved dramatically in 4 months.',
          treatment: 'Scalp Serum + Minoxidil 5%',
          thumbnail:
              'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=800',
          avatar:
              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
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
            VideoComment(
              id: 'c3',
              user: 'Pooja Sharma',
              time: '35m ago',
              text: 'Truly inspiring results. Just booked my hair test!',
              likes: 12,
            ),
          ],
        ),
        VideoStoryModel(
          id: '2',
          name: 'Rahul Sharma',
          handle: '@rahul.sharma',
          category: 'Hair Regrowth Journey',
          tag: 'Regrowth',
          duration: '4:12',
          views: 41200,
          likes: 2890,
          commentsCount: 312,
          shares: 175,
          caption:
              'My follicle density noticeably improved in just 3 months! Genetic hair fall completely halted without surgery.',
          treatment: 'DHT Blocker Kit + Redensyl',
          thumbnail:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=800',
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
            VideoComment(
              id: 'c5',
              user: 'Kunal Verma',
              time: '2h ago',
              text: 'Consistency is truly key. Awesome density recovery!',
              likes: 31,
            ),
          ],
        ),
        VideoStoryModel(
          id: '3',
          name: 'Aarav Patel',
          handle: '@aarav.patel',
          category: 'DHT Blocker Regrowth',
          tag: 'Regrowth',
          duration: '2:58',
          views: 18900,
          likes: 980,
          commentsCount: 86,
          shares: 45,
          caption:
              'Doctor consultation was transparent and totally tailored. Hairline has started filling in with thick baby hairs.',
          treatment: 'Scalp Peptide + Biotin Booster',
          thumbnail:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=800',
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
        VideoStoryModel(
          id: '4',
          name: 'Ananya Mehra',
          handle: '@ananya.mehra',
          category: 'Dandruff Scalp Detox',
          tag: 'Dandruff',
          duration: '3:15',
          views: 35400,
          likes: 3420,
          commentsCount: 420,
          shares: 210,
          caption:
              'Severe flakes and itching cleared within 3 weeks of the kit. Scalp feels clean and refreshed every single day.',
          treatment: 'Ketoconazole 2% + Salicylic Wash',
          thumbnail:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=800',
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
            VideoComment(
              id: 'c8',
              user: 'Sneha Jain',
              time: '3h ago',
              text:
                  'No, paired with the hydrating conditioner it leaves hair super soft!',
              likes: 28,
            ),
          ],
        ),
      ];
}
