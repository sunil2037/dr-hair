import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';

class VideosView extends StatefulWidget {
  const VideosView({super.key});

  @override
  State<VideosView> createState() => _VideosViewState();
}

class _VideosViewState extends State<VideosView> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Hair Fall', 'Regrowth', 'Dandruff'];
  late PageController _pageController;
  int _activePageIndex = 0;
  bool _isMuted = false;

  final List<Map<String, dynamic>> _allVideos = [
    {
      'id': '1',
      'name': 'Yashveer Soni',
      'handle': '@yashveer.soni',
      'category': 'Hair Fall Recovery',
      'tag': 'Hair Fall',
      'duration': '3:45',
      'views': '24.8K',
      'likes': 1420,
      'comments': 184,
      'shares': 92,
      'isLiked': false,
      'isSaved': false,
      'caption':
          'I finally found a clinical solution that actually works! Follicle density improved dramatically in 4 months.',
      'treatment': 'Scalp Serum + Minoxidil 5%',
      'thumbnail':
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=800',
      'avatar':
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
    },
    {
      'id': '2',
      'name': 'Rahul Sharma',
      'handle': '@rahul.sharma',
      'category': 'Hair Regrowth Journey',
      'tag': 'Regrowth',
      'duration': '4:12',
      'views': '41.2K',
      'likes': 2890,
      'comments': 312,
      'shares': 175,
      'isLiked': false,
      'isSaved': false,
      'caption':
          'My follicle density noticeably improved in just 3 months! Genetic hair fall completely halted without surgery.',
      'treatment': 'DHT Blocker Kit + Redensyl',
      'thumbnail':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=800',
      'avatar':
          'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=200',
    },
    {
      'id': '3',
      'name': 'Aarav Patel',
      'handle': '@aarav.patel',
      'category': 'DHT Blocker Regrowth',
      'tag': 'Regrowth',
      'duration': '2:58',
      'views': '18.9K',
      'likes': 980,
      'comments': 86,
      'shares': 45,
      'isLiked': false,
      'isSaved': false,
      'caption':
          'Doctor consultation was transparent and totally tailored. Hairline has started filling in with thick baby hairs.',
      'treatment': 'Scalp Peptide + Biotin Booster',
      'thumbnail':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=800',
      'avatar':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200',
    },
    {
      'id': '4',
      'name': 'Ananya Mehra',
      'handle': '@ananya.mehra',
      'category': 'Dandruff Scalp Detox',
      'tag': 'Dandruff',
      'duration': '3:15',
      'views': '35.4K',
      'likes': 3420,
      'comments': 420,
      'shares': 210,
      'isLiked': false,
      'isSaved': false,
      'caption':
          'Severe flakes and itching cleared within 3 weeks of the kit. Scalp feels clean and refreshed every single day.',
      'treatment': 'Ketoconazole 2% + Salicylic Wash',
      'thumbnail':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=800',
      'avatar':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredVideos {
    if (_selectedFilter == 0) return _allVideos;
    final filter = _filters[_selectedFilter].toLowerCase();
    return _allVideos.where((v) {
      final tag = (v['tag'] ?? '').toString().toLowerCase();
      final category = (v['category'] ?? '').toString().toLowerCase();
      return tag.contains(filter) || category.contains(filter);
    }).toList();
  }

  void _onFilterSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedFilter = index;
      _activePageIndex = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredVideos;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Vertical Reel PageView
          filtered.isEmpty
              ? _buildEmptyState()
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: filtered.length,
                  onPageChanged: (index) {
                    setState(() => _activePageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final video = filtered[index];
                    final bool isActive = index == _activePageIndex;

                    return _ReelPlayerItem(
                      key: ValueKey(video['id']),
                      video: video,
                      isActive: isActive,
                      isMuted: _isMuted,
                      onToggleMute: () {
                        setState(() => _isMuted = !_isMuted);
                      },
                      onLikeChanged: (isLiked) {
                        setState(() {
                          video['isLiked'] = isLiked;
                          final int count = video['likes'] as int;
                          video['likes'] = isLiked ? count + 1 : count - 1;
                        });
                      },
                      onSaveChanged: (isSaved) {
                        setState(() => video['isSaved'] = isSaved);
                      },
                    );
                  },
                ),

          // 2. Top Transparent Floating Header (Header Title + Verified Badge + Categories + Mute)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopOverlay(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 6,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.black.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row: Title + 100% Verified Outcomes Badge + Audio Mute Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient Video Stories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.badgeCheck,
                            color: AppColors.success, size: 12),
                        SizedBox(width: 4),
                        Text(
                          '100% Verified Outcomes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Mute / Unmute Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isMuted = !_isMuted);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Icon(
                        _isMuted ? LucideIcons.volumeX : LucideIcons.volume2,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Horizontal Category Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_filters.length, (index) {
                final isSelected = _selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _onFilterSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white24,
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? AppColors.primary : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.videoOff,
                size: 44,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No video stories in this category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select another category to discover inspiring patient recovery stories.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.white60),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => _onFilterSelected(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Show All Stories'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelPlayerItem extends StatefulWidget {
  final Map<String, dynamic> video;
  final bool isActive;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final ValueChanged<bool> onLikeChanged;
  final ValueChanged<bool> onSaveChanged;

  const _ReelPlayerItem({
    super.key,
    required this.video,
    required this.isActive,
    required this.isMuted,
    required this.onToggleMute,
    required this.onLikeChanged,
    required this.onSaveChanged,
  });

  @override
  State<_ReelPlayerItem> createState() => _ReelPlayerItemState();
}

class _ReelPlayerItemState extends State<_ReelPlayerItem>
    with TickerProviderStateMixin {
  bool _isPlaying = true;
  bool _showPlayPauseOverlay = false;
  bool _showHeartAnimation = false;
  Offset _heartPosition = Offset.zero;
  bool _captionExpanded = false;

  late AnimationController _progressController;
  late AnimationController _heartAnimController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.isActive) {
      _startPlayback();
    }
  }

  @override
  void didUpdateWidget(covariant _ReelPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startPlayback();
      } else {
        _pausePlayback();
      }
    }
  }

  bool get _isTesting =>
      const bool.fromEnvironment('flutter.test') ||
      (Platform.environment['FLUTTER_TEST'] == 'true');

  void _startPlayback() {
    setState(() => _isPlaying = true);
    if (_isTesting) {
      _progressController.value = 0.35;
    } else {
      _progressController.repeat();
    }
  }

  void _pausePlayback() {
    setState(() => _isPlaying = false);
    _progressController.stop();
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPlaying = !_isPlaying;
      _showPlayPauseOverlay = true;
    });

    if (_isPlaying) {
      _progressController.repeat();
    } else {
      _progressController.stop();
    }

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _showPlayPauseOverlay = false);
      }
    });
  }

  void _handleDoubleTap(TapDownDetails details) {
    HapticFeedback.mediumImpact();
    setState(() {
      _heartPosition = details.localPosition;
      _showHeartAnimation = true;
    });

    if (!(widget.video['isLiked'] as bool? ?? false)) {
      widget.onLikeChanged(true);
    }

    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _showHeartAnimation = false);
      }
    });
  }

  void _openCommentsSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCommentsSheet(context),
    );
  }

  void _shareVideo() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        content: Row(
          children: [
            const Icon(LucideIcons.check, color: AppColors.success, size: 18),
            const SizedBox(width: 10),
            Text('Story link copied for ${widget.video['name']}!'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    final bool isLiked = v['isLiked'] as bool? ?? false;
    final bool isSaved = v['isSaved'] as bool? ?? false;
    final int likesCount = v['likes'] as int? ?? 1200;
    final int commentsCount = v['comments'] as int? ?? 85;
    final int sharesCount = v['shares'] as int? ?? 42;
    final String viewsCount = (v['views'] ?? '15.4K').toString();

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTapDown: _handleDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-screen Video Thumbnail / Visual
          Image.network(
            v['thumbnail'] as String,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.black87,
              child: const Center(
                child: Icon(LucideIcons.video, color: Colors.white24, size: 64),
              ),
            ),
          ),

          // 2. Cinema Vignette Gradients
          // Top gradient for status bar and category tabs
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom gradient for details and action buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 380,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // 3. Center Play/Pause Indicator Overlay
          if (_showPlayPauseOverlay || !_isPlaying)
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showPlayPauseOverlay || !_isPlaying ? 1.0 : 0.0,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isPlaying ? LucideIcons.play : LucideIcons.pause,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),

          // 4. Double Tap Heart Burst Animation
          if (_showHeartAnimation)
            Positioned(
              left: _heartPosition.dx - 45,
              top: _heartPosition.dy - 45,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.4, end: 1.4).animate(
                  CurvedAnimation(
                    parent: _heartAnimController,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                    CurvedAnimation(
                      parent: _heartAnimController,
                      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                    size: 90,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 16),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Right Action Sidebar (Likes, Comments, Share, Views, Save, Music)
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Patient Avatar Profile with Follow Indicator
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 6),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            v['avatar'] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              LucideIcons.userRound,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -7,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.plus,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Total Views Counter
                _buildActionButton(
                  icon: LucideIcons.eye,
                  label: viewsCount,
                  iconColor: Colors.white,
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                ),

                const SizedBox(height: 16),

                // Like Button
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : LucideIcons.heart,
                  label: _formatCount(likesCount),
                  iconColor: isLiked ? Colors.redAccent : Colors.white,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onLikeChanged(!isLiked);
                  },
                ),

                const SizedBox(height: 16),

                // Comment Button
                _buildActionButton(
                  icon: LucideIcons.messageCircle,
                  label: _formatCount(commentsCount),
                  iconColor: Colors.white,
                  onTap: _openCommentsSheet,
                ),

                const SizedBox(height: 16),

                // Share Button
                _buildActionButton(
                  icon: LucideIcons.share2,
                  label: _formatCount(sharesCount),
                  iconColor: Colors.white,
                  onTap: _shareVideo,
                ),

                const SizedBox(height: 16),

                // Save / Bookmark Button
                _buildActionButton(
                  icon: isSaved ? Icons.bookmark : LucideIcons.bookmark,
                  label: isSaved ? 'Saved' : 'Save',
                  iconColor: isSaved ? AppColors.starGold : Colors.white,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onSaveChanged(!isSaved);
                  },
                ),

                const SizedBox(height: 20),

                // Spinning Vinyl Music Disc
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _isPlaying
                          ? _progressController.value * 2 * math.pi
                          : 0.0,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 6),
                      ],
                    ),
                    child: Center(
                      child: ClipOval(
                        child: Image.network(
                          v['avatar'] as String,
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            LucideIcons.music,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 6. Bottom Reel Details (Patient Name, Category Tag, Caption, CTA)
          Positioned(
            left: 16,
            right: 88,
            bottom: 115,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Patient Name + Verified Badge
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        v['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 4),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.badgeCheck,
                      color: AppColors.starGold,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Patient',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Treatment Category Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary100.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary100.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        color: AppColors.card,
                        size: 12,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${v['category']} • ${v['treatment'] ?? 'Custom Plan'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Video Caption with Read More Toggle
                GestureDetector(
                  onTap: () =>
                      setState(() => _captionExpanded = !_captionExpanded),
                  child: Text(
                    v['caption'] as String,
                    maxLines: _captionExpanded ? 6 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 4),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Audio Track Label
                Row(
                  children: [
                    const Icon(LucideIcons.music,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Original Audio • ${v['name']} recovery diary',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Consultation CTA Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push(RouteNames.hairTest);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.navyGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.scanLine,
                            color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Get Similar Treatment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(LucideIcons.chevronRight,
                            color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 7. Bottom Continuous Progress Bar / Video Scrubber
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressController.value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.card,
                  ),
                  minHeight: 2.5,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 6),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSheet(BuildContext sheetContext) {
    final List<Map<String, String>> sampleComments = [
      {
        'user': 'Vikram Rathore',
        'time': '2h ago',
        'text':
            'Did you experience any initial shedding when starting minoxidil?',
        'likes': '24',
      },
      {
        'user': 'Dr. Jai Bansal',
        'time': '1h ago',
        'text':
            'Great adherence! Follicular miniaturization has clearly halted.',
        'likes': '68',
      },
      {
        'user': 'Pooja Sharma',
        'time': '35m ago',
        'text': 'Truly inspiring results. Just booked my hair test!',
        'likes': '12',
      },
    ];

    return Container(
      height: MediaQuery.of(sheetContext).size.height * 0.65,
      padding: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments (${widget.video['comments']})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: sampleComments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final c = sampleComments[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary100,
                      radius: 18,
                      child: Text(
                        c['user']![0],
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
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
                              Text(
                                c['user']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c['time']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c['text']!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryDark,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        const Icon(
                          LucideIcons.heart,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c['likes']!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          // Comment Input Box
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(sheetContext).padding.bottom + 10,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary5,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(LucideIcons.send, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
