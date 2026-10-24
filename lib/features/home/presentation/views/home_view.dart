import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/assessment_gate.dart';
import '../../../care/presentation/viewmodels/care_cubit.dart';
import '../../../care/presentation/viewmodels/care_state.dart';
import '../../../hair_test/presentation/viewmodels/hair_test_cubit.dart';
import '../../../hair_test/presentation/viewmodels/hair_test_state.dart';
import '../../../shop/data/models/product_model.dart';
import '../viewmodels/home_journey_selector.dart';
import '../widgets/medicine_card.dart';

class HomeView extends StatefulWidget {
  final VoidCallback onStartHairTest;
  const HomeView({super.key, required this.onStartHairTest});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  static const int _sectionCount = 13;
  late final AnimationController _entranceController;
  late final List<Animation<double>> _sectionOpacity;
  late final List<Animation<Offset>> _sectionPosition;
  bool _motionConfigured = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );

    _sectionOpacity = List.generate(_sectionCount, (index) {
      final start = (index * 0.04).clamp(0.0, 0.55);
      final end = (start + 0.30).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _sectionPosition = _sectionOpacity
        .map(
          (opacity) => Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(opacity),
        )
        .toList(growable: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
    } else {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _revealSection(int index, Widget child) {
    return FadeTransition(
      opacity: _sectionOpacity[index],
      child: SlideTransition(position: _sectionPosition[index], child: child),
    );
  }

  Future<void> _launchWhatsapp() async {
    const phoneNumber = '918058056789';
    const message =
        'Hello! I’m seeking a professional consultation for my hair. Do you provide digital or in-person consultations?';
    final uri = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch WhatsApp');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HairTestCubit, HairTestState>(
      builder: (context, hairState) {
        final completed = hairState.isCompleted && !hairState.isRetesting;
        final first = completed
            ? _buildRestorationJourney(assessmentComplete: true)
            : _buildEssentialProducts(context);
        final second = completed
            ? _buildEssentialProducts(context)
            : _buildRestorationJourney(assessmentComplete: false);
        return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HERO SECTION
          _revealSection(0, _buildHeroSection(context)),

          const SizedBox(height: 24),

          // 2. ESSENTIAL PRODUCTS (on top)
          _revealSection(1, first),

          const SizedBox(height: 24),

          // 3. RESTORATION JOURNEY
          _revealSection(2, second),

          const SizedBox(height: 24),

          // 4. BOOK APPOINTMENT
          _revealSection(3, _buildAppointmentCard(context)),

          const SizedBox(height: 24),

          // 5. OTHER JOURNEY & CARE ACTIVITY
          _revealSection(4, _buildJourneyCard()),

          const SizedBox(height: 24),

          _revealSection(5, _buildUrgentCareCard()),

          const SizedBox(height: 24),

          // 6. REVIEWS & VIDEO STORIES
          _revealSection(6, _buildReviewsSection(context)),

          const SizedBox(height: 24),

          _revealSection(7, _buildVideoStories(context)),

          const SizedBox(height: 24),

          // 7. REMAINING SECTIONS ACCORDING TO NEED (Tips, Trust, Analytics, FAQ, Certifications)
          _revealSection(8, _buildExpertTips()),

          const SizedBox(height: 24),

          _revealSection(9, _buildWhyTrustDrHair()),

          const SizedBox(height: 24),

          _revealSection(10, _buildAnalyticsSection()),

          const SizedBox(height: 24),

          _revealSection(11, _buildFaqSection()),

          const SizedBox(height: 24),

          _revealSection(12, _buildCertifications()),

          const SizedBox(height: 24),
        ],
      ),
        );
      },
    );
  }

  // --- SECTION 1: HERO SECTION ---
  Widget _buildHeroSection(BuildContext context) {
    final hairState = context.watch<HairTestCubit>().state;
    final mediaQuery = MediaQuery.of(context);
    final double screenHeight = mediaQuery.size.height;
    final double screenWidth = mediaQuery.size.width;
    final double topPadding = mediaQuery.padding.top + kToolbarHeight;
    final double bannerHeight = (screenHeight * 0.4).clamp(
      topPadding + 160.0,
      380.0,
    );

    return Column(
      children: [
        // Hero Image with Rounded Bottom using CustomCachedImage + Skeletonizer
        Container(
          height: bannerHeight,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF7ED), Color(0xFFFEF3E2)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            child: Stack(
              children: [
                // Right-aligned model banner image
                Positioned(
                  bottom: 0,
                  right: -80,
                  child: Image.asset(
                    'assets/images/hair_bennar.png',
                    height: (bannerHeight - topPadding).clamp(190.0, 250.0),
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),

                // Left-aligned content (Badge, Headline, CTA)
                Positioned(
                  left: 20,
                  top: topPadding - 30,
                  bottom: 20,
                  width: screenWidth * 0.47,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Clinically Approved Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withValues(
                                alpha: 0.04,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/icons/ApprovedIcon.png',
                              width: 12,
                              height: 12,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    LucideIcons.badgeCheck,
                                    color: AppColors.primary,
                                    size: 12,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                'Clinically Approved',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Impact Headline
                      RichText(
                        textAlign: TextAlign.left,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            height: 1.25,
                            letterSpacing: -0.3,
                          ),
                          children: [
                            TextSpan(text: 'Your Journey to\n'),
                            TextSpan(text: 'Thicker, '),
                            TextSpan(
                              text: 'Healthier',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(text: ' Hair\nStarts with Science'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      // CTA Button
                      if (!hairState.isCompleted || hairState.isRetesting)
                        SizedBox(
                          height: 38,
                          child: ElevatedButton(
                          onPressed: widget.onStartHairTest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            elevation: 5,
                            shadowColor: AppColors.primary.withValues(
                              alpha: 0.35,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: BlocBuilder<HairTestCubit, HairTestState>(
                            builder: (context, state) {
                              final isComplete =
                                  state.isCompleted && !state.isRetesting;
                              final isInProgress =
                                  HomeJourneySelector.hasAssessmentProgress(
                                    state,
                                  );
                              final label = isComplete
                                  ? 'Retake Hair Test'
                                  : isInProgress
                                  ? 'Continue Test'
                                  : 'Free Hair Test';
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(LucideIcons.arrowRight, size: 14),
                                  ],
                                ),
                              );
                            },
                          ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION 2: URGENT CARE CARD ---
  Widget _buildUrgentCareCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.primary5,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'URGENT CARE',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Worried about hair fall?',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Stop the recession before it starts. Get a clinically proven plan tailored to your scalp biology.',
              style: TextStyle(
                color: AppColors.secondaryDark,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _launchWhatsapp,
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Consult a specialist',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      LucideIcons.arrowRight,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SECTION 3: ANALYTICS & SOCIAL PROOF ---
  Widget _buildAnalyticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.lightCardGradient,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primary100),
        ),
        child: Column(
          children: [
            const Text(
              'Trusted by Thousands',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Real results backed by expertise and experience',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.secondaryDark),
            ),
            const SizedBox(height: 24),

            // Stat Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: LucideIcons.smile,
                    value: '20,000+',
                    title: 'Happy Customers',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    icon: LucideIcons.trophy,
                    value: '30+',
                    title: 'Years Experience',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Google Ratings Center Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary5,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.thumbsUp,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '4.9',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Row(
                              children: List.generate(
                                5,
                                (index) => const Icon(
                                  LucideIcons.star,
                                  color: AppColors.starGold,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Google Ratings • 10,000+ Reviews',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.secondaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: LucideIcons.heart,
                    value: '50M+',
                    title: 'Grafts Done',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    icon: LucideIcons.userRound,
                    value: '18,000+',
                    title: 'Grade 6/7 Cases',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary5,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 4: ESSENTIAL PRODUCTS ---
  Widget _buildEssentialProducts(BuildContext context) {
    return const _EssentialProductsSection();
  }

  // --- SECTION 6: WHY TRUST DR. HAIR ---
  Widget _buildWhyTrustDrHair() {
    final trustPoints = [
      {
        'title': 'Science-Backed',
        'icon': LucideIcons.flaskConical,
        'bg': const Color(0xFFEAF1F6),
        'color': const Color(0xFF1A365D),
      },
      {
        'title': 'Doctor Verified',
        'icon': LucideIcons.stethoscope,
        'bg': const Color(0xFFECFDF5),
        'color': const Color(0xFF0D9488),
      },
      {
        'title': 'FDA Approved',
        'icon': LucideIcons.shieldCheck,
        'bg': const Color(0xFFFAF5FF),
        'color': const Color(0xFF7E22CE),
      },
      {
        'title': 'Painless Solution',
        'icon': LucideIcons.flower2,
        'bg': const Color(0xFFFFF7ED),
        'color': const Color(0xFFEA580C),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why Trust Dr.Hair',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trustPoints.length,
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              final item = trustPoints[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary5,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item['bg'] as Color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- SECTION 7: RESTORATION JOURNEY (TIMELINE) ---
  Widget _buildRestorationJourney({required bool assessmentComplete}) {
    final careState = context.watch<CareCubit>().state;
    final hasRoutine = careState.routineTasks.isNotEmpty;
    final completedRoutine = careState.routineTasks
        .where((task) => task.isCompleted)
        .length;
    final steps = [
      {
        'step': '1',
        'title': assessmentComplete ? 'Hair assessment complete' : 'Take the Hair Test',
        'desc': assessmentComplete
            ? 'Your answers are saved and guide your care journey.'
            : 'Answer questions about your lifestyle and scalp to get started.',
      },
      {
        'step': '2',
        'title': assessmentComplete ? 'Personalized care plan' : 'Scalp analysis',
        'desc': assessmentComplete
            ? 'Your personalized care plan is ready to explore.'
            : 'Continue your assessment to create a plan for your scalp.',
      },
      {
        'step': '3',
        'title': 'Daily routine',
        'desc': assessmentComplete && hasRoutine
            ? '$completedRoutine of ${careState.routineTasks.length} care steps completed.'
            : 'Build a consistent routine from your personalized care steps.',
      },
      {
        'step': '4',
        'title': 'Track Progress',
        'desc': assessmentComplete
            ? 'Your progress journal is ready for check-ins and photo updates.'
            : 'Track your journey with regular check-ins and photo updates.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Restoration Journey',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 18),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == steps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: assessmentComplete || index == 0
                              ? AppColors.primary
                              : AppColors.primary5,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: assessmentComplete || index == 0
                                ? AppColors.primary
                                : AppColors.primary100,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item['step']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: assessmentComplete || index == 0
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColors.primary100,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['desc']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryDark,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- SECTION 8: VIDEO STORIES ---
  Widget _buildVideoStories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Real Patient Stories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push(RouteNames.videos),
                child: const Text(
                  'Watch All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            children: [
              _buildVideoCard(
                image: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=600',
                title: 'Yashveer Soni',
                subtitle: 'Recovered full crown density in 4 months',
              ),
              const SizedBox(width: 16),
              _buildVideoCard(
                image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=600',
                title: 'Rahul Sharma',
                subtitle: 'Stabilized genetic hair fall without surgery',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard({
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.primary100,
              child: const Icon(LucideIcons.imageOff, color: AppColors.primary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(
                    LucideIcons.play,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 9: LOCAL JOURNEY ACTION ---
  Widget _buildJourneyCard() {
    return BlocBuilder<HairTestCubit, HairTestState>(
      builder: (context, hairState) => BlocBuilder<CareCubit, CareState>(
        builder: (context, careState) {
          final action = HomeJourneySelector.select(
            hairState: hairState,
            careState: careState,
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080D1B2A),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR CARE JOURNEY',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    action.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        switch (action.destination) {
                          case HomeJourneyDestination.assessment:
                            widget.onStartHairTest();
                          case HomeJourneyDestination.routine:
                            if (hairState.isCompleted && !hairState.isRetesting) {
                              context.push(RouteNames.routine);
                            } else {
                              showAssessmentRequiredSheet(context);
                            }
                          case HomeJourneyDestination.progress:
                            if (hairState.isCompleted && !hairState.isRetesting) {
                              context.push(RouteNames.progress);
                            } else {
                              showAssessmentRequiredSheet(context);
                            }
                        }
                      },
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(action.buttonLabel),
                    ),
                  ),
                  if (hairState.isCompleted && !hairState.isRetesting) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Assessment results are informational and are not a medical diagnosis.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary100),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary5,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                LucideIcons.calendarDays,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prefer expert guidance?',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Book an appointment with our care team.',
                    style: TextStyle(
                      color: AppColors.secondaryDark,
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Book appointment',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => context.push(RouteNames.coachBooking),
              icon: const Icon(LucideIcons.arrowRight, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // --- SECTION 10: REVIEWS ---
  Widget _buildReviewsSection(BuildContext context) {
    final reviews = [
      {
        'name': 'Amit Verma',
        'rating': 5,
        'comment': 'After 3 months of following the custom kit, my hair thinning significantly reduced and my density improved visibly.',
      },
      {
        'name': 'Pooja Nair',
        'rating': 5,
        'comment': 'The AI hair test is surprisingly thorough. The doctor-prescribed serum worked wonders for my chronic hair shedding.',
      },
      {
        'name': 'Siddharth Roy',
        'rating': 5,
        'comment': 'I was skeptical at first, but DrHair gave me actual clinical insight into my scalp condition. Highly recommended!',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Voices of Success',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push(RouteNames.reviews),
                child: const Text(
                  'All Reviews',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 175,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final r = reviews[index];
              return Container(
                width: 280,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary5,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.primary100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (r['name'] as String)[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['name'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                r['rating'] as int,
                                (i) => const Icon(
                                  LucideIcons.star,
                                  color: AppColors.starGold,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      r['comment'] as String,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- SECTION 11: EXPERT TIPS ---
  Widget _buildExpertTips() {
    final tips = [
      {
        'icon': '🔥',
        'title': 'Avoid excessive heat styling',
        'desc': 'High temperatures weaken hair shafts and damage follicles.',
      },
      {
        'icon': '🥗',
        'title': 'Protein-rich diet',
        'desc': 'Hair is built of keratin, requiring healthy dietary protein.',
      },
      {
        'icon': '🧘',
        'title': 'Manage stress levels',
        'desc': 'Chronic stress triggers telogen effluvium hair shedding.',
      },
      {
        'icon': '🧴',
        'title': 'Sulfate-free shampoos',
        'desc': 'Preserve essential scalp lipids and moisture balance.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Expert Tips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 156,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final t = tips[index];
              return Container(
                width: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary5,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['icon']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 8),
                    Text(
                      t['title']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['desc']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- SECTION 13: FAQS ---
  Widget _buildFaqSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequently Asked',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          _buildFaqItem(
            question: 'What is doctor-backed hair recovery?',
            answer: 'Unlike generic commercial shampoos, our plans involve licensed dermatologists assessing your scalp photos, lifestyle, and genetics to formulate targeted clinical topicals and nutrients.',
          ),
          _buildFaqItem(
            question: 'How long until I see visible results?',
            answer: 'Most patients experience hair shedding reduction within 4-6 weeks, followed by noticeable follicular thickening and new growth in 3-5 months.',
          ),
          _buildFaqItem(
            question: 'Is the online hair test really free?',
            answer: 'Yes, the 3-minute diagnostic assessment and initial follicular health report are 100% free with no obligation to purchase.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textSecondary,
            title: Text(
              question,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryDark,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SECTION 14: CERTIFICATIONS ---
  Widget _buildCertifications() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildCertBadge(
              'Clinically\nApproved',
              LucideIcons.badgeCheck,
            ),
          ),
          Expanded(
            child: _buildCertBadge('ISO\nCertified', LucideIcons.shieldPlus),
          ),
          Expanded(
            child: _buildCertBadge(
              'Dermatologist\nVerified',
              LucideIcons.stethoscope,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertBadge(String title, IconData icon) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary5,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary100),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryDark,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _EssentialProductsSection extends StatelessWidget {
  const _EssentialProductsSection();

  @override
  Widget build(BuildContext context) {
    final products = ProductItem.demoCatalog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Essential Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Doctor-approved formulations & therapies',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push(RouteNames.products),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Medicines Horizontal List
        SizedBox(
          height: 275,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = products[index];
              return MedicineCard(
                title: item.name,
                desc: item.subtitle,
                price: item.supplyPlans.isEmpty
                    ? 'Price unavailable'
                    : '₹${item.supplyPlans.first.price}',
                imageUrl: item.images.isEmpty ? '' : item.images.first,
                category: item.category.toLowerCase().contains('ayurveda')
                    ? MedicineCategory.ayurveda
                    : MedicineCategory.dermatologist,
                rating: item.rating,
                showAddToCart: false,
                onTap: () =>
                    context.push(RouteNames.productDetails, extra: item),
              );
            },
          ),
        ),
      ],
    );
  }
}
