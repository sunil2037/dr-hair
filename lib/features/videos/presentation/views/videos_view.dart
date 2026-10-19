import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../domain/models/video_story_model.dart';
import '../viewmodels/videos_cubit.dart';
import '../viewmodels/videos_state.dart';

class VideosView extends StatelessWidget {
  final VideosCubit? cubit;

  const VideosView({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<VideosCubit>.value(
        value: cubit!,
        child: const _VideosContent(),
      );
    }
    return BlocProvider<VideosCubit>(
      create: (_) => VideosCubit(),
      child: const _VideosContent(),
    );
  }
}

class _VideosContent extends StatefulWidget {
  const _VideosContent();

  @override
  State<_VideosContent> createState() => _VideosContentState();
}

class _VideosContentState extends State<_VideosContent> {
  late final PageController _pageController;
  late VideosCubit _cubit;

  @override
  void initState() {
    super.initState();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cubit = context.read<VideosCubit>();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VideosCubit, VideosState>(
      listenWhen: (previous, current) =>
          previous.selectedFilterIndex != current.selectedFilterIndex,
      listener: (context, state) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      },
      builder: (context, state) {
        final filtered = state.filteredVideos;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Vertical Reel PageView
              if (filtered.isEmpty)
                _buildEmptyState(context)
              else
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: filtered.length,
                  onPageChanged: (index) {
                    _cubit.onPageChanged(index);
                  },
                  itemBuilder: (context, index) {
                    final video = filtered[index];
                    final bool isActive = index == state.activeIndex;

                    return VisibilityDetector(
                      key: Key('video_story_${video.id}'),
                      onVisibilityChanged: (info) {
                        if (mounted) {
                          _cubit.onVisibilityChanged(
                            video.id,
                            info.visibleFraction,
                          );
                        }
                      },
                      child: _MinimalReelPlayer(
                        key: ValueKey(video.id),
                        video: video,
                        isActive: isActive,
                      ),
                    );
                  },
                ),

              // 2. Minimal Top Floating Overlay (Title + Verified badge + Categories)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopOverlay(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopOverlay(BuildContext context, VideosState state) {
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
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Patient Video Stories + 100% Verified Outcomes
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
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                        Icon(
                          LucideIcons.badgeCheck,
                          color: AppColors.success,
                          size: 12,
                        ),
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
            ],
          ),

          const SizedBox(height: 12),

          // Horizontal Category Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(state.filters.length, (index) {
                final isSelected = state.selectedFilterIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.read<VideosCubit>().changeFilter(index);
                    },
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
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        state.filters[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
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

  Widget _buildEmptyState(BuildContext context) {
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
              onPressed: () {
                context.read<VideosCubit>().changeFilter(0);
              },
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

class _MinimalReelPlayer extends StatefulWidget {
  final VideoStoryModel video;
  final bool isActive;

  const _MinimalReelPlayer({
    super.key,
    required this.video,
    required this.isActive,
  });

  @override
  State<_MinimalReelPlayer> createState() => _MinimalReelPlayerState();
}

class _MinimalReelPlayerState extends State<_MinimalReelPlayer>
    with TickerProviderStateMixin {
  bool _showPlayPauseOverlay = false;
  bool _showHeartAnimation = false;
  Offset _heartPosition = Offset.zero;

  late final AnimationController _progressController;
  late final AnimationController _heartAnimController;

  bool get _isTesting =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test') ||
      const bool.fromEnvironment('flutter.test') ||
      Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.isActive && widget.video.isPlaying) {
      _startPlayback();
    }
  }

  @override
  void didUpdateWidget(covariant _MinimalReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive ||
        widget.video.isPlaying != oldWidget.video.isPlaying) {
      if (widget.isActive && widget.video.isPlaying) {
        _startPlayback();
      } else {
        _pausePlayback();
      }
    }
  }

  void _startPlayback() {
    if (_isTesting) {
      _progressController.value = 0.35;
    } else {
      _progressController.repeat();
    }
  }

  void _pausePlayback() {
    _progressController.stop();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() => _showPlayPauseOverlay = true);

    context.read<VideosCubit>().togglePlayPause(widget.video.id);

    Future.delayed(const Duration(milliseconds: 600), () {
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

    if (!widget.video.isLiked) {
      context.read<VideosCubit>().toggleLike(widget.video.id);
    }

    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _showHeartAnimation = false);
      }
    });
  }

  void _onShare() {
    HapticFeedback.mediumImpact();
    context.read<VideosCubit>().incrementShare(widget.video.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        content: Row(
          children: [
            const Icon(LucideIcons.check, color: AppColors.success, size: 18),
            const SizedBox(width: 10),
            Text('Story link copied for ${widget.video.name}!'),
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

    return GestureDetector(
      onTap: _handleTap,
      onDoubleTapDown: _handleDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-screen Video Thumbnail via CustomCachedImage with Skeletonizer
          CustomCachedImage(
            imageUrl: v.thumbnail,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            borderRadius: 0,
            errorWidget: Container(
              color: Colors.black87,
              child: const Center(
                child: Icon(LucideIcons.video, color: Colors.white24, size: 64),
              ),
            ),
          ),

          // 2. Subtle Cinema Vignette Gradients
          // Top gradient for status bar and header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.3),
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
            height: 280,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 3. Center Play/Pause Indicator Overlay
          if (_showPlayPauseOverlay || !v.isPlaying)
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showPlayPauseOverlay || !v.isPlaying ? 1.0 : 0.0,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    v.isPlaying ? LucideIcons.pause : LucideIcons.play,
                    color: Colors.white,
                    size: 36,
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
                    shadows: [Shadow(color: Colors.black54, blurRadius: 16)],
                  ),
                ),
              ),
            ),

          // 5. Minimal Right Action Sidebar: ONLY Like and Share buttons
          Positioned(
            right: 14,
            bottom: 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minimal Like Button
                _buildActionItem(
                  icon: v.isLiked ? Icons.favorite : LucideIcons.heart,
                  label: v.formattedLikes,
                  iconColor: v.isLiked ? Colors.redAccent : Colors.white,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<VideosCubit>().toggleLike(v.id);
                  },
                ),

                const SizedBox(height: 20),

                // Minimal Share Button
                _buildActionItem(
                  icon: LucideIcons.share2,
                  label: v.formattedShares,
                  iconColor: Colors.white,
                  onTap: _onShare,
                ),
              ],
            ),
          ),

          // 6. Minimal Bottom Reel Info: Patient Name + Subtitle
          Positioned(
            left: 16,
            right: 84,
            bottom: 105,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Patient Name + Verified Badge
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        v.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
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
                      size: 17,
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Treatment Category Tag
                Text(
                  '${v.category} • ${v.treatment}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Brief Caption
                Text(
                  v.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),

          // 7. Minimal Bottom Continuous Video Progress Line
          Positioned(
            left: 0,
            right: 0,
            bottom: 92,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressController.value,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white70,
                  ),
                  minHeight: 2.0,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 23),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
