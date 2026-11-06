import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/category_filter_bar.dart';
import '../../data/datasources/review_remote_data_source.dart';
import '../../data/models/review_model.dart';

class ReviewsView extends StatefulWidget {
  final ReviewRemoteDataSource? remoteDataSource;

  const ReviewsView({super.key, this.remoteDataSource});

  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Hair Fall', 'Regrowth', 'Dandruff'];
  late final ReviewRemoteDataSource _dataSource;
  List<ReviewModel> _reviews = ReviewModel.defaultReviews;
  bool _isLoading = false;
  late final ScrollController _scrollController;
  bool _isScrolledPastHeader = false;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.remoteDataSource ?? ReviewRemoteDataSource();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadReviews();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // When the user has scrolled past the compact flexible space,
    // the category filter bar reaches and docks cleanly with the app bar.
    final bool past = _scrollController.offset >= 55.0;
    if (past != _isScrolledPastHeader) {
      setState(() => _isScrolledPastHeader = past);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final category = _selectedFilterIndex == 0
        ? null
        : _filters[_selectedFilterIndex];
    final items = await _dataSource.getReviews(category: category);
    if (!mounted) return;
    setState(() {
      _reviews = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    const double toolbarH = kToolbarHeight;
    const double categoryBarH = 46.0;
    final double collapsedHeight = topPadding + toolbarH + categoryBarH;
    final double expandedHeight = topPadding + 184.0;

    final List<ReviewModel> filteredReviews = _selectedFilterIndex == 0
        ? _reviews
        : _reviews
              .where(
                (r) =>
                    r.category.toLowerCase() ==
                        _filters[_selectedFilterIndex].toLowerCase() ||
                    r.treatment.toLowerCase().contains(
                      _filters[_selectedFilterIndex].toLowerCase(),
                    ),
              )
              .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: NestedScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            final bool isDocked = innerBoxIsScrolled || _isScrolledPastHeader;

            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverAppBar(
                  pinned: true,
                  floating: false,
                  centerTitle: false,
                  automaticallyImplyLeading: false,
                  elevation: isDocked ? 0.5 : 0.0,
                  shadowColor: Colors.black.withValues(alpha: 0.08),
                  backgroundColor: isDocked
                      ? Colors.white
                      : AppColors.background,
                  surfaceTintColor: Colors.transparent,
                  expandedHeight: expandedHeight,
                  toolbarHeight: toolbarH,
                  title: isDocked
                      ? const Text(
                          'Patient Stories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                            letterSpacing: -0.3,
                          ),
                        )
                      : null,
                  flexibleSpace: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final double currentHeight =
                              constraints.biggest.height;
                          final double t = expandedHeight > collapsedHeight
                              ? ((currentHeight - collapsedHeight) /
                                        (expandedHeight - collapsedHeight))
                                    .clamp(0.0, 1.0)
                              : 0.0;
                          final bool showExpanded = t > 0.15 && !isDocked;

                          return FlexibleSpaceBar(
                            collapseMode: CollapseMode.parallax,
                            background: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  categoryBarH,
                                ),
                                child: Opacity(
                                  opacity: t,
                                  child: showExpanded
                                      ? ClipRect(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'Patient Stories',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primaryDark,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'Real experiences from verified patients following customized routines',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.secondaryDark,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              _buildRatingCard(),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          );
                        },
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(categoryBarH),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      height: categoryBarH,
                      decoration: BoxDecoration(
                        color: isDocked ? Colors.white : AppColors.background,
                        border: Border(
                          bottom: BorderSide(
                            color: isDocked
                                ? AppColors.border
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        boxShadow: isDocked
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.centerLeft,
                      child: CategoryFilterBar(
                        categories: _filters,
                        selectedIndex: _selectedFilterIndex,
                        unselectedColor: isDocked
                            ? AppColors.neutral100
                            : Colors.white,
                        onSelected: (index) {
                          setState(() => _selectedFilterIndex = index);
                          _loadReviews();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Builder(
            builder: (BuildContext context) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: <Widget>[
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                  ),
                  if (_isLoading && _reviews.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (filteredReviews.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      sliver: SliverList.separated(
                        itemCount: filteredReviews.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final r = filteredReviews[index];
                          return _ReviewCard(review: r);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary5,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary100),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.star, color: AppColors.starGold, size: 17),
                SizedBox(width: 4),
                Text(
                  '4.8',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Patient satisfaction rating',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Verified outcomes across 12,000+ active care plans',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              decoration: const BoxDecoration(
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
              style: TextStyle(fontSize: 12.5, color: AppColors.secondaryDark),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() => _selectedFilterIndex = 0);
                _loadReviews();
              },
              child: const Text('Show All Reviews'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final ReviewModel review;

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
                      border: Border.all(
                        color: AppColors.primary100,
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: r.avatar.isNotEmpty
                          ? Image.network(
                              r.avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppColors.primary5,
                                    child: const Icon(
                                      LucideIcons.userRound,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                  ),
                            )
                          : Container(
                              color: AppColors.primary5,
                              child: const Icon(
                                LucideIcons.userRound,
                                color: AppColors.primary,
                                size: 22,
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
                                r.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (r.verified) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFA7F3D0),
                                  ),
                                ),
                                child: const Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (r.duration.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            r.duration,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.secondaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                      r.rating,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary5,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r.treatment,
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
                r.comment,
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
