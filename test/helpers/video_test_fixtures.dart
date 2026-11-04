import 'package:dr_hair/features/videos/domain/models/video_story_model.dart';

/// Test fixtures for video unit and widget tests.
/// Kept isolated in test/ to ensure production code contains zero hardcoded data.
abstract class VideoTestFixtures {
  static List<VideoStoryModel> get testStories => const [
        VideoStoryModel(
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
              'Dr. Hair protocol helped regain crown density naturally. Noticeable reduction in shedding within 6 weeks.',
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
              text: 'Did you experience any initial shedding?',
              likes: 24,
            ),
          ],
        ),
        VideoStoryModel(
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
              'My follicle density noticeably improved in just 3 months! Genetic hair fall halted.',
          treatment: 'DHT Blocker Kit + Redensyl',
          videoUrl: 'https://www.youtube.com/watch?v=kJQP7kiw5Fk',
          thumbnail: 'https://i.ytimg.com/vi/kJQP7kiw5Fk/hqdefault.jpg',
          avatar:
              'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=200',
        ),
        VideoStoryModel(
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
              'Severe flakes and itching cleared within 3 weeks of the kit. Scalp feels clean.',
          treatment: 'Ketoconazole 2% + Salicylic Wash',
          videoUrl: 'https://www.youtube.com/watch?v=L_LUpnjgPso',
          thumbnail: 'https://i.ytimg.com/vi/L_LUpnjgPso/hqdefault.jpg',
          avatar:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200',
        ),
        VideoStoryModel(
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
              'Doctor consultation was transparent and totally tailored. Hairline has started filling in.',
          treatment: 'Scalp Peptide + Biotin Booster',
          videoUrl: 'https://www.youtube.com/watch?v=fJ9rUzIMcZQ',
          thumbnail: 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
          avatar:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200',
        ),
      ];
}

