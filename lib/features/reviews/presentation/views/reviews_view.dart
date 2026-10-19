import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/category_filter_bar.dart';

class ReviewsView extends StatefulWidget {
  const ReviewsView({super.key});

  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Hair Fall', 'Regrowth', 'Dandruff'];

  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Yashveer Soni',
      'rating': 5,
      'category': 'Hair Fall',
      'treatment': 'Stage 3 Receding Hairline',
      'duration': 'Used for 5 months',
      'comment':
          'DrHair completely reversed my hairline thinning. Following the customized routine faithfully with the topical booster made a night and day difference.',
      'verified': true,
      'avatar':
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=300',
    },
    {
      'name': 'Rahul Sharma',
      'rating': 5,
      'category': 'Regrowth',
      'treatment': 'Crown Thinning & Density Loss',
      'duration': 'Used for 4 months',
      'comment':
          'I was skeptical after trying various store shampoos. But having a doctor analyze my scalp photos and formulate specific serums stopped my daily hair shed by week 4.',
      'verified': true,
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300',
    },
    {
      'name': 'Ananya Mehra',
      'rating': 4,
      'category': 'Dandruff',
      'treatment': 'Dry Flaking & Follicle Weakness',
      'duration': 'Used for 2 months',
      'comment':
          'Cleared stubborn scalp buildup and dandruff within 3 weeks. Hair roots feel significantly cleaner and thicker now.',
      'verified': true,
      'avatar':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=300',
    },
    {
      'name': 'Vikram Malhotra',
      'rating': 5,
      'category': 'Regrowth',
      'treatment': 'Crown Thinning & DHT Regimen',
      'duration': 'Used for 6 months',
      'comment':
          'Visible follicular regrowth and thicker hair shaft. My dermatological check showed a 38% increase in active follicular density.',
      'verified': true,
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300',
    },
    {
      'name': 'Sneha Kapoor',
      'rating': 5,
      'category': 'Hair Fall',
      'treatment': 'Post-Stress Hair Shedding',
      'duration': 'Used for 3 months',
      'comment':
          'Reduced daily hair fall by over 70% within the first 6 weeks. The customized clinical serum is lightweight and non-greasy.',
      'verified': true,
      'avatar':
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=300',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> filteredReviews = _selectedFilterIndex == 0
        ? _reviews
        : _reviews
            .where((r) => r['category'] == _filters[_selectedFilterIndex])
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // Header Title and Rating Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clinical Reviews',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Genuine feedback from verified DrHair patients',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rating Summary Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary5,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.primary100),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primary100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    LucideIcons.star,
                                    color: AppColors.starGold,
                                    size: 20,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    '4.8',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '10,000+ Verified Stories',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '93% reported clinical reduction in shedding',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.secondaryDark,
                                      fontWeight: FontWeight.w500,
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
                  selectedIndex: _selectedFilterIndex,
                  onSelected: (index) =>
                      setState(() => _selectedFilterIndex = index),
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
            child: filteredReviews.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    key: ValueKey<int>(_selectedFilterIndex),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: filteredReviews.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final r = filteredReviews[index];
                      return _ReviewCard(review: r);
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('empty_reviews'),
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
                LucideIcons.messageSquareDashed,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No reviews found in this category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try selecting another filter or view all reviews.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.secondaryDark,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _selectedFilterIndex = 0),
              child: const Text('Show All Reviews'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.review;

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary100, width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        r['avatar'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.primary5,
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
                                r['name'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              LucideIcons.circleCheck,
                              color: AppColors.success,
                              size: 15,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r['duration'] as String,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.secondaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                      r['rating'] as int,
                      (i) => const Icon(
                        LucideIcons.star,
                        color: AppColors.starGold,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category tag pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary5,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r['treatment'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Testimonial comment
              Text(
                r['comment'] as String,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryDark,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
