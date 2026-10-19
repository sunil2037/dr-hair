import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/category_filter_bar.dart';

class VideosView extends StatefulWidget {
  const VideosView({super.key});

  @override
  State<VideosView> createState() => _VideosViewState();
}

class _VideosViewState extends State<VideosView> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Hair Fall', 'Regrowth', 'Dandruff'];

  final List<Map<String, dynamic>> _videos = [
    {
      'id': '1',
      'name': 'Yashveer Soni',
      'category': 'Hair Fall Recovery',
      'tag': 'Hair Fall',
      'duration': '3:45',
      'caption': '"I finally found a clinical solution that actually works!"',
      'thumbnail':
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=800',
      'avatar':
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
    },
    {
      'id': '2',
      'name': 'Rahul Sharma',
      'category': 'Hair Regrowth Journey',
      'tag': 'Regrowth',
      'duration': '4:12',
      'caption': '"My follicle density noticeably improved in just 3 months!"',
      'thumbnail':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=800',
      'avatar':
          'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=200',
    },
    {
      'id': '3',
      'name': 'Aarav Patel',
      'category': 'DHT Blocker Regrowth',
      'tag': 'Regrowth',
      'duration': '2:58',
      'caption': '"Doctor consultation was transparent and totally tailored."',
      'thumbnail':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=800',
      'avatar':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200',
    },
    {
      'id': '4',
      'name': 'Ananya Mehra',
      'category': 'Dandruff Scalp Detox',
      'tag': 'Dandruff',
      'duration': '3:15',
      'caption': '"Severe flakes and itching cleared within 3 weeks of the kit."',
      'thumbnail':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=800',
      'avatar':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> filteredVideos = _selectedFilter == 0
        ? _videos
        : _videos.where((v) {
            final filter = _filters[_selectedFilter].toLowerCase();
            final tag = (v['tag'] ?? '').toString().toLowerCase();
            final category = (v['category'] ?? '').toString().toLowerCase();
            return tag.contains(filter) || category.contains(filter);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // Header Title and Intro Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient Video Stories',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'See how DrHair helped patients regain confidence & hair density',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Video Spotlight Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppColors.navyGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.circlePlay,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '100% Verified Outcomes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Unedited patient recovery journals & doctor reviews',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pinned Category Filter Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverCategoryFilterBarDelegate(
                  categories: _filters,
                  selectedIndex: _selectedFilter,
                  onSelected: (index) =>
                      setState(() => _selectedFilter = index),
                  backgroundColor: AppColors.background,
                  extent: 52.0,
                ),
              ),
            ];
          },
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.03),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: filteredVideos.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    key: ValueKey<int>(_selectedFilter),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: filteredVideos.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      final v = filteredVideos[index];
                      return _VideoCard(video: v);
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('empty_videos'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary5,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.videoOff,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No video stories in this category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try selecting another filter or watch all stories.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.secondaryDark,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _selectedFilter = 0),
              child: const Text('Show All Video Stories'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  final Map<String, dynamic> video;

  const _VideoCard({required this.video});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  bool _isPressed = false;

  void _handlePlayTap() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('Playing ${widget.video['name']}\'s Recovery Story'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _handlePlayTap,
        child: Container(
          height: 380,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Thumbnail with error fallback
                Image.network(
                  v['thumbnail'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.primary,
                    child: const Center(
                      child: Icon(
                        LucideIcons.image,
                        color: Colors.white30,
                        size: 54,
                      ),
                    ),
                  ),
                ),

                // Dark Cinema Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),

                // Duration Badge (Top Right)
                if (v['duration'] != null)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            color: Colors.white,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            v['duration'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Center Animated Play Button
                Center(
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.play,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                ),

                // Bottom Patient Details
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                v['avatar'] as String,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        Container(
                                  color: Colors.white,
                                  child: const Icon(
                                    LucideIcons.userRound,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        v['name'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      LucideIcons.badgeCheck,
                                      color: AppColors.starGold,
                                      size: 16,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    v['category'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        v['caption'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
