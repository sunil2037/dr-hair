import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/photo_source_bottom_sheet.dart';
import '../../../shop/data/models/product_model.dart';
import '../../../shop/presentation/viewmodels/cart_cubit.dart';
import '../../../shop/presentation/viewmodels/products_cubit.dart';
import '../viewmodels/hair_test_cubit.dart';
import '../viewmodels/hair_test_state.dart';

/// The Clinical Assessment Report View displaying the patient's hair test diagnosis,
/// verified doctor reports, uploaded scalp photos, personalized recommended products,
/// and in-clinic doctor consultation options.
class AssessmentReportView extends StatefulWidget {
  final HairTestState state;

  const AssessmentReportView({super.key, required this.state});

  @override
  State<AssessmentReportView> createState() => _AssessmentReportViewState();
}

class _AssessmentReportViewState extends State<AssessmentReportView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HairTestCubit, HairTestState>(
      builder: (context, dynamicState) {
        final state = dynamicState.isCompleted || dynamicState.isSubmitted
            ? dynamicState
            : widget.state;
        final selectedPattern = _selectedPatternIllustration(state);
        final String trimmedName = state.name.trim();
        final String displayName = trimmedName.isNotEmpty
            ? '${trimmedName[0].toUpperCase()}${trimmedName.substring(1)}, ${state.age}'
            : 'Patient, ${state.age}';

        final stageStr = (state.stage ?? state.primaryConcern ?? '')
            .toLowerCase();
        final bool isSevereOrPatchy =
            stageStr.contains('stage 4') ||
            stageStr.contains('stage 5') ||
            stageStr.contains('patch') ||
            stageStr.contains('extensive');

        final liveProducts = context.watch<ProductsCubit?>()?.state.products;
        final recommendedProducts = _getRecommendedProducts(
          state,
          liveProducts,
        );

        final isReviewed =
            state.assessmentStatus == 'reviewed' ||
            state.clinicalReports.isNotEmpty ||
            state.doctorCarePlan != null;
        final isUnderReview = state.assessmentStatus == 'under_review';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(
                LucideIcons.arrowLeft,
                color: AppColors.primaryDark,
              ),
              onPressed: () {
                context.read<HairTestCubit>().dismissReport();
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go(RouteNames.mainShell);
                }
              },
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Assessment complete',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Assessment Report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  context.read<HairTestCubit>().startRetest();
                  context.push(RouteNames.hairTest);
                },
                child: const Text(
                  'Retest',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await context.read<HairTestCubit?>()?.refreshClinicalReports();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Expert Clinical Review Status Notice
                    _buildExpertReviewNoticeCard(
                      context,
                      state,
                      isReviewed,
                      isUnderReview,
                    ),

                    const SizedBox(height: 16),

                    // 2. Main Diagnosis Card
                    _buildMainDiagnosisCard(
                      state,
                      selectedPattern,
                      displayName,
                      isReviewed,
                      isUnderReview,
                    ),

                    // 3. Doctor's Prescribed Regimen (if reviewed by doctor)
                    if (state.doctorCarePlan != null) ...[
                      const SizedBox(height: 20),
                      _buildDoctorPrescribedCarePlanCard(
                        context,
                        state.doctorCarePlan!,
                      ),
                    ],

                    // 4. Doctor's Clinical Report Section (if available)
                    if (state.clinicalReports.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDoctorClinicalReportsSection(
                        context,
                        state.clinicalReports,
                      ),
                    ],

                    // 5. In-Clinic Doctor Consultation (Hero placement if Stage 4/5 or patchy)
                    if (isSevereOrPatchy) ...[
                      const SizedBox(height: 20),
                      _buildDoctorAppointmentCard(context, isHero: true),
                    ],

                    const SizedBox(height: 20),

                    // 6. Clinical Scalp Photos Section
                    _buildScalpPhotosSection(context, state),

                    // 7. Recommended Clinical Products Section (Stage 1/2/3 protocols)
                    if (!isSevereOrPatchy) ...[
                      const SizedBox(height: 20),
                      _buildRecommendedProductsSection(
                        context,
                        recommendedProducts,
                        state,
                        isReviewed,
                      ),
                      const SizedBox(height: 20),
                      _buildDoctorAppointmentCard(context, isHero: false),
                    ],

                    const SizedBox(height: 20),

                    // 8. Summary Card
                    _buildSummaryCard(state),

                    const SizedBox(height: 16),

                    // 9. Medical Disclaimer Box
                    _buildDisclaimerBox(),

                    const SizedBox(height: 24),

                    // 10. Next steps & routine setup
                    _buildPostAssessmentNextSteps(context),

                    const SizedBox(height: 20),

                    // 11. Return to Home
                    AppButton(
                      height: 48,
                      text: 'Done',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.large,
                      width: double.infinity,
                      onPressed: () {
                        context.read<HairTestCubit>().dismissReport();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go(RouteNames.mainShell);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: isSevereOrPatchy
                  ? AppButton(
                      height: 48,
                      text: 'Book Consultation with Dr. Jai Bansal (₹500)',
                      variant: AppButtonVariant.filled,
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      icon: const Icon(
                        LucideIcons.calendarCheck2,
                        size: 16,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          context.push(RouteNames.clinicAppointment),
                    )
                  : AppButton(
                      height: 48,
                      text: isReviewed
                          ? 'Order Prescribed Regimen Kit'
                          : 'Order Recommended Stage Kit',
                      variant: AppButtonVariant.filled,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      icon: const Icon(
                        LucideIcons.shoppingBag,
                        size: 16,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        final cart = context.read<CartCubit?>();
                        if (cart != null && recommendedProducts.isNotEmpty) {
                          for (final prod in recommendedProducts) {
                            final plan = prod.supplyPlans.isNotEmpty
                                ? prod.supplyPlans.first
                                : ProductSupplyPlan(
                                    title: 'Standard',
                                    subtitle: prod.subtitle,
                                    price: 999,
                                    mrp: 1299,
                                  );
                            cart.addProduct(
                              product: prod,
                              plan: plan,
                              quantity: 1,
                            );
                          }
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Complete kit added to cart!',
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'View Cart',
                                textColor: Colors.white,
                                onPressed: () => context.push(RouteNames.cart),
                              ),
                            ),
                          );
                        } else {
                          context.push(RouteNames.products);
                        }
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpertReviewNoticeCard(
    BuildContext context,
    HairTestState state,
    bool isReviewed,
    bool isUnderReview,
  ) {
    Color cardBg;
    Color borderCol;
    Color iconCol;
    IconData iconData;
    String badgeText;
    String title;
    String subtitle;
    String description;

    if (isReviewed) {
      cardBg = const Color(0xFFF0FDF4);
      borderCol = const Color(0xFFBBF7D0);
      iconCol = const Color(0xFF16A34A);
      iconData = LucideIcons.badgeCheck;
      badgeText = 'Expert Clinical Review Completed';
      title = 'Prescribed by Dr. Jai Bansal';
      subtitle = 'Verified Trichologist & Clinic Head';
      description = 'Dr. Jai Bansal has reviewed your scalp assessment and photos. Your verified treatment regimen and clinical instructions are active below.';
    } else if (isUnderReview) {
      cardBg = const Color(0xFFEFF6FF);
      borderCol = const Color(0xFFBFDBFE);
      iconCol = const Color(0xFF2563EB);
      iconData = LucideIcons.hourglass;
      badgeText = 'Scalp Photos Under Review';
      title = 'Under Review by Expert Clinic Team';
      subtitle = 'Assigned to Dr. Jai Bansal';
      description = 'Dr. Jai Bansal and our clinical team are currently analyzing your hair loss patterns and scalp photos. Your personalized care regimen will be published here shortly.';
    } else {
      cardBg = const Color(0xFFFFFBEB);
      borderCol = const Color(0xFFFDE68A);
      iconCol = const Color(0xFFD97706);
      iconData = LucideIcons.clock;
      badgeText = 'Submitted · Awaiting Doctor Review';
      title = 'Report Sent to Expert Clinic Team';
      subtitle = 'Assigned to Dr. Jai Bansal';
      description = 'Your report has been sent to our expert clinic team (Dr. Jai Bansal). Please wait for review. After the expert analyzes your report and scalp photos, they will provide clinical feedback, personalized care regimen, and verified assessment soon.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderCol),
                ),
                child: Icon(iconData, color: iconCol, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderCol),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: iconCol,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _buildReviewTracker(
            isReviewed: isReviewed,
            isUnderReview: isUnderReview,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTracker({
    required bool isReviewed,
    required bool isUnderReview,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildTrackerStep(
            'Intake Sent',
            isDone: true,
            isActive: false,
            isLast: false,
          ),
          _buildTrackerStep(
            'Doctor Review',
            isDone: isReviewed,
            isActive: isUnderReview || !isReviewed,
            isLast: false,
          ),
          _buildTrackerStep(
            'Regimen Prescribed',
            isDone: isReviewed,
            isActive: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerStep(
    String label, {
    required bool isDone,
    required bool isActive,
    required bool isLast,
  }) {
    Color circleColor = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF94A3B8);
    IconData icon = LucideIcons.circle;

    if (isDone) {
      circleColor = const Color(0xFF16A34A);
      textColor = const Color(0xFF166534);
      icon = LucideIcons.check;
    } else if (isActive) {
      circleColor = const Color(0xFF2563EB);
      textColor = const Color(0xFF1E40AF);
      icon = LucideIcons.clock;
    }

    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 12, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isDone || isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Container(
              width: 16,
              height: 2,
              margin: const EdgeInsets.only(bottom: 14),
              color: isDone ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
            ),
        ],
      ),
    );
  }

  Widget _buildMainDiagnosisCard(
    HairTestState state,
    ({String label, String asset})? selectedPattern,
    String displayName,
    bool isReviewed,
    bool isUnderReview,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isReviewed
                      ? const Color(0xFFEAF8EE)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isReviewed
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isReviewed
                          ? LucideIcons.badgeCheck
                          : LucideIcons.clipboardCheck,
                      color: isReviewed
                          ? const Color(0xFF1B6A47)
                          : const Color(0xFF1D4ED8),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isReviewed ? 'Clinically Verified' : 'Intake Recorded',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isReviewed
                              ? const Color(0xFF1B6A47)
                              : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.referenceNo != null && state.referenceNo!.isNotEmpty)
                Text(
                  state.referenceNo!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryDark,
                  ),
                ),
            ],
          ),
          if (selectedPattern != null) ...[
            const SizedBox(height: 14),
            _buildSelectedPatternCard(selectedPattern),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppColors.secondaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.stageTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary5,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.clipboardCheck,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What this may mean',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.stageDescription,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 12,
                    height: 1.45,
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

  Widget _buildDoctorPrescribedCarePlanCard(
    BuildContext context,
    Map<String, dynamic> plan,
  ) {
    final String instructions =
        plan['instructions']?.toString() ??
        'Follow daily application schedule as directed.';
    final String? nextReview = plan['next_review_date']?.toString();
    final List medications = (plan['medications'] as List?) ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.pill,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Doctor's Verified Care Plan",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14532D),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Prescribed by Dr. Jai Bansal',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Clinical Regimen Instructions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            instructions,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: Color(0xFF14532D),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (medications.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Prescribed Formulations & Dosage',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF166534),
              ),
            ),
            const SizedBox(height: 8),
            for (final med in medications) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.check,
                      size: 14,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        med['name']?.toString() ?? 'Medication',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    if (med['dosage'] != null)
                      Text(
                        med['dosage'].toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
          if (nextReview != null && nextReview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 6),
                Text(
                  'Next Clinical Review: $nextReview',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedPatternCard(({String label, String asset}) pattern) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary5,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 86,
            child: Image.asset(
              pattern.asset,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your selected pattern',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pattern.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Matches your self-reported hairline or crown shedding.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScalpPhotosSection(BuildContext context, HairTestState state) {
    final angles = ['front', 'top', 'crown', 'left', 'right', 'back'];
    final labels = {
      'front': 'Front Hairline',
      'top': 'Top View',
      'crown': 'Crown Vertex',
      'left': 'Left Temple',
      'right': 'Right Temple',
      'back': 'Back Scalp',
    };

    final hasAnyPhotos = state.photos.values.any((p) => p.trim().isNotEmpty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary5,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.camera,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Scalp Photos',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Photos attached to this assessment for doctor review',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasAnyPhotos) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: angles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final angle = angles[index];
                final photoPath = state.photos[angle];
                final label = labels[angle] ?? angle;

                if (photoPath == null || photoPath.trim().isEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.image,
                          size: 20,
                          color: AppColors.secondaryDark,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Missing',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final isLocal =
                    !photoPath.startsWith('http://') &&
                    !photoPath.startsWith('https://');

                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      isLocal
                          ? Image.file(File(photoPath), fit: BoxFit.cover)
                          : CustomCachedImage(
                              imageUrl: photoPath,
                              fit: BoxFit.cover,
                            ),
                      Container(
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    LucideIcons.imageOff,
                    size: 28,
                    color: AppColors.secondaryDark,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No scalp photos attached',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'You can add photos anytime for more precise clinical tracking.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppButton(
            height: 42,
            text: hasAnyPhotos ? 'Update scalp photos' : 'Add scalp photos',
            variant: AppButtonVariant.outlined,
            icon: const Icon(LucideIcons.upload, size: 14),
            onPressed: () => _openScalpPhotoUpdater(context),
          ),
        ],
      ),
    );
  }

  void _openScalpPhotoUpdater(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select photo angle to capture',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Clear scalp photos help Dr. Hair clinicians assess hairline and vertex follicles accurately.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryDark),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _angleChip(sheetCtx, 'front', 'Front Hairline'),
                _angleChip(sheetCtx, 'top', 'Top View'),
                _angleChip(sheetCtx, 'crown', 'Crown Vertex'),
                _angleChip(sheetCtx, 'left', 'Left Temple'),
                _angleChip(sheetCtx, 'right', 'Right Temple'),
                _angleChip(sheetCtx, 'back', 'Back Scalp'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _angleChip(BuildContext context, String angle, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.pop(context);
        _pickPhotoForAngle(context, angle);
      },
    );
  }

  void _pickPhotoForAngle(BuildContext context, String angle) {
    final cubit = context.read<HairTestCubit>();
    PhotoSourceBottomSheet.show(
      context,
      title: 'Upload $angle photo',
      onSelectSource: (source) => cubit.pickPhoto(label: angle, source: source),
    );
  }

  Widget _buildRecommendedProductsSection(
    BuildContext context,
    List<ProductItem> products,
    HairTestState state,
    bool isReviewed,
  ) {
    final stageStr = (state.stage ?? state.primaryConcern ?? '').toLowerCase();
    String stageTitle = 'Recommended Clinical Products';
    String stageSubtitle =
        'Tailored formulations based on your root cause & scalp status';
    if (stageStr.contains('stage 1')) {
      stageTitle = 'Stage 1 Care Protocol (Preventative & Roots)';
      stageSubtitle =
          'Formulations to nourish follicles and maintain scalp balance';
    } else if (stageStr.contains('stage 2')) {
      stageTitle = 'Stage 2 Care Protocol (Targeted Regrowth & DHT Defense)';
      stageSubtitle =
          'Formulations to revive receding temples and crown follicles';
    } else if (stageStr.contains('stage 3')) {
      stageTitle = 'Stage 3 Care Protocol (Intensive Regrowth Kit)';
      stageSubtitle = 'High-potency clinical kit targeting visible scalp areas';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary5,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended Clinical Products',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stageTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stageSubtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (products.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final cart = context.read<CartCubit?>();
                    if (cart != null) {
                      for (final prod in products) {
                        final plan = prod.supplyPlans.isNotEmpty
                            ? prod.supplyPlans.first
                            : ProductSupplyPlan(
                                title: 'Standard',
                                subtitle: prod.subtitle,
                                price: 999,
                                mrp: 1299,
                              );
                        cart.addProduct(product: prod, plan: plan, quantity: 1);
                      }
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Complete kit added to cart!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'View Cart',
                            textColor: Colors.white,
                            onPressed: () => context.push(RouteNames.cart),
                          ),
                        ),
                      );
                    } else {
                      context.push(RouteNames.products);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(LucideIcons.shoppingBag, size: 15),
                  label: const Text(
                    'Add Complete Kit to Cart',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            for (final product in products) ...[
              _buildProductCard(context, product),
              const SizedBox(height: 12),
            ],
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No specific retail formulations needed. Consult our clinic for prescription-grade care.',
                style: TextStyle(fontSize: 12, color: AppColors.secondaryDark),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () => context.push(RouteNames.products),
              icon: const Icon(
                LucideIcons.sparkles,
                size: 14,
                color: AppColors.primary,
              ),
              label: const Text(
                'Explore recommended products',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductItem product) {
    final plan = product.supplyPlans.isNotEmpty
        ? product.supplyPlans.first
        : ProductSupplyPlan(
            title: 'Standard',
            subtitle: product.subtitle,
            price: 999,
            mrp: 1299,
          );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary5.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 58,
              height: 58,
              child: CustomCachedImage(
                imageUrl: product.images.isNotEmpty
                    ? product.images.first
                    : ProductItem.fallbackProductImageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      '₹${plan.price.toInt()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    if (plan.mrp > plan.price)
                      Text(
                        '₹${plan.mrp.toInt()}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final cart = context.read<CartCubit?>();
              if (cart != null) {
                cart.addProduct(product: product, plan: plan, quantity: 1);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added to cart!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: 'View Cart',
                      textColor: Colors.white,
                      onPressed: () => context.push(RouteNames.cart),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.plus, size: 12),
                SizedBox(width: 4),
                Text(
                  'Add',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorAppointmentCard(
    BuildContext context, {
    bool isHero = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHero ? const Color(0xFF93C5FD) : const Color(0xFFBFDBFE),
          width: isHero ? 1.5 : 1.0,
        ),
        boxShadow: isHero
            ? [
                BoxShadow(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHero) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertCircle, size: 12, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'Doctor Recommendation · In-Person Review Required',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.stethoscope,
                  color: Color(0xFF1D4ED8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHero
                          ? 'In-Person Clinical Consultation Recommended'
                          : 'Prefer an In-Person Clinical Assessment?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Consult Dr. Jai Bansal (Dermatologist & Hair Specialist)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isHero
                ? 'For advanced thinning (Stage 4/5) or patchy shedding, retail formulations alone are not sufficient. An in-person digital trichoscopy and doctor examination is strongly recommended to preserve existing follicles.'
                : 'Get a comprehensive digital trichoscopy examination, clinical blood biomarker review, and doctor-prescribed customized treatment regimen at Dr. Hair OPD Clinic.',
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            height: 50,
            text: isHero
                ? 'Book In-Person Consultation (₹500)'
                : 'Book Consultation (₹500)',
            variant: AppButtonVariant.filled,
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            icon: const Icon(
              LucideIcons.calendarCheck2,
              size: 16,
              color: Colors.white,
            ),
            onPressed: () => context.push(RouteNames.clinicAppointment),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorClinicalReportsSection(
    BuildContext context,
    List<Map<String, dynamic>> reports,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.fileCheck2,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Doctor's Clinical Report",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14532D),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Verified by Dr. Jai Bansal',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your scalp assessment has been reviewed by Dr. Jai Bansal. An official clinical diagnosis report is available below.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 16),
          ...reports.map((report) {
            final String title =
                report['title']?.toString() ?? 'Clinical Hair & Scalp Report';
            final String fileName =
                report['file_name']?.toString() ?? 'report.pdf';
            final String reportId = report['id']?.toString() ?? '';
            final num bytes = (report['bytes'] as num?) ?? 1024;
            final String sizeStr = bytes / 1024 < 1000
                ? '${(bytes / 1024).toStringAsFixed(0)} KB'
                : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.fileText,
                        size: 18,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      Text(
                        sizeStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                            side: const BorderSide(color: Color(0xFFBBF7D0)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(LucideIcons.fileText, size: 14),
                          label: const Text(
                            'View PDF',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () async {
                            final cubit = context.read<HairTestCubit?>();
                            final uri = await cubit?.getReportDownloadUri(
                              reportId,
                            );
                            if (uri != null && context.mounted) {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(LucideIcons.shoppingBag, size: 14),
                          label: const Text(
                            'Order Kit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            context.push(RouteNames.products);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPostAssessmentNextSteps(BuildContext context) {
    final hairState = context.watch<HairTestCubit>().state;
    final hasCompletedAssessment =
        hairState.isCompleted && !hairState.isRetesting;

    if (!hasCompletedAssessment) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Want your own care plan?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Complete the hair screening to get customized product recommendations and a routine that fits your lifestyle.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.secondaryDark,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Take Hair Assessment',
              variant: AppButtonVariant.filled,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () {
                context.read<HairTestCubit>().startRetest();
                context.push(RouteNames.hairTest);
              },
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your next steps',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Build a simple care habit and track changes over time.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.secondaryDark,
            ),
          ),
          const SizedBox(height: 16),
          _nextStepRow('1', 'Review your daily routine'),
          _nextStepRow('2', 'Set a reminder that works for you'),
          _nextStepRow('3', 'Add a baseline progress photo'),
          const SizedBox(height: 12),
          AppButton(
            text: 'Set up my routine',
            variant: AppButtonVariant.filled,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: () => context.push(RouteNames.routine),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => context.push(RouteNames.reminders),
                  child: const Text('Set a reminder'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      context.push(RouteNames.progress, extra: true),
                  child: const Text('Add progress photo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nextStepRow(String number, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary5,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(HairTestState state) {
    final details = [
      (key: 'Gender', value: state.selectedGender ?? 'Not selected'),
      (key: 'Age', value: state.age.isNotEmpty ? state.age : 'Not specified'),
      if (state.primaryConcern != null && state.primaryConcern!.isNotEmpty)
        (key: 'Main Concern', value: state.primaryConcern!),
      if (state.duration != null && state.duration!.isNotEmpty)
        (key: 'Duration', value: state.duration!),
      if (state.dandruff != null && state.dandruff!.isNotEmpty)
        (key: 'Dandruff Status', value: state.dandruff!),
      if (state.familyHistory != null && state.familyHistory!.isNotEmpty)
        (key: 'Family History', value: state.familyHistory!),
      if (state.gutHealth != null && state.gutHealth!.isNotEmpty)
        (key: 'Gut Health', value: state.gutHealth!),
      if (state.stressLevel != null && state.stressLevel!.isNotEmpty)
        (key: 'Stress Level', value: state.stressLevel!),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHAT YOU SHARED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'These are the details you selected for this assessment.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.secondaryDark,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < details.length; index++) ...[
            if (index > 0) const Divider(height: 16, color: AppColors.border),
            _buildSummaryRow(details[index].key, details[index].value),
          ],
        ],
      ),
    );
  }

  Widget _buildDisclaimerBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.stethoscope, color: Color(0xFFD97706), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to use this result',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This summary is based on your answers and is not a medical diagnosis. A qualified clinician can assess your symptoms and discuss suitable care.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

List<ProductItem> _getRecommendedProducts(
  HairTestState state, [
  List<ProductItem>? liveProducts,
]) {
  final catalog = (liveProducts != null && liveProducts.isNotEmpty)
      ? liveProducts
      : ProductItem.demoCatalog;

  final list = <ProductItem>[];
  final stageStr = (state.stage ?? state.primaryConcern ?? '').toLowerCase();
  final dandruff = (state.dandruff ?? '').toLowerCase();
  final gut = (state.gutHealth ?? '').toLowerCase();
  final stress = (state.stressLevel ?? '').toLowerCase();

  ProductItem? findInCatalog(bool Function(ProductItem p) predicate) {
    try {
      return catalog.firstWhere(predicate);
    } catch (_) {
      return null;
    }
  }

  // 1. Stage-specific Core Formulations
  if (stageStr.contains('stage 1')) {
    // Stage 1: Preventative - Root Nourishing Serum + Gentle Shampoo + Biotin/Supplements
    final serum =
        findInCatalog(
          (p) =>
              p.name.toLowerCase().contains('root') ||
              p.name.toLowerCase().contains('boost') ||
              p.name.toLowerCase().contains('serum'),
        ) ??
        findInCatalog((p) => p.category.toLowerCase().contains('serum'));
    if (serum != null && !list.contains(serum)) {
      list.add(serum);
    }

    final shampoo =
        findInCatalog(
          (p) =>
              p.name.toLowerCase().contains('gentle') ||
              p.name.toLowerCase().contains('cleans') ||
              p.category.toLowerCase().contains('shampoo'),
        ) ??
        findInCatalog((p) => p.category.toLowerCase().contains('shampoo'));
    if (shampoo != null && !list.contains(shampoo)) {
      list.add(shampoo);
    }

    final supplement =
        findInCatalog(
          (p) =>
              p.name.toLowerCase().contains('biotin') ||
              p.name.toLowerCase().contains('nutrition') ||
              p.category.toLowerCase().contains('supplement'),
        ) ??
        findInCatalog((p) => p.category.toLowerCase().contains('supplement'));
    if (supplement != null && !list.contains(supplement)) {
      list.add(supplement);
    }
  } else if (stageStr.contains('stage 2')) {
    // Stage 2: Targeted Regrowth - 5% Minoxidil / Regrowth Serum + Anti-DHT Shampoo + Roller / Nutrition
    final regrowthSerum =
        findInCatalog(
          (p) =>
              p.name.toLowerCase().contains('minoxidil') ||
              p.name.toLowerCase().contains('regrowth') ||
              p.category.toLowerCase().contains('serum'),
        ) ??
        findInCatalog((p) => p.category.toLowerCase().contains('serum'));
    if (regrowthSerum != null && !list.contains(regrowthSerum)) {
      list.add(regrowthSerum);
    }

    final dhtShampoo =
        findInCatalog(
          (p) =>
              p.name.toLowerCase().contains('dht') ||
              p.name.toLowerCase().contains('fall') ||
              p.category.toLowerCase().contains('shampoo'),
        ) ??
        findInCatalog((p) => p.category.toLowerCase().contains('shampoo'));
    if (dhtShampoo != null && !list.contains(dhtShampoo)) {
      list.add(dhtShampoo);
    }

    final rollerOrNutrition =
        findInCatalog(
          (p) =>
              p.name.toLowerCase().contains('roller') ||
              p.name.toLowerCase().contains('vital') ||
              p.category.toLowerCase().contains('kit'),
        ) ??
        findInCatalog((p) => p.category.toLowerCase().contains('supplement'));
    if (rollerOrNutrition != null && !list.contains(rollerOrNutrition)) {
      list.add(rollerOrNutrition);
    }
  } else if (stageStr.contains('stage 3')) {
    // Stage 3: Intensive Clinical Kit - Intensive Regrowth Serum + Hair Vitalizer/Supplements + Exfoliating/DHT Shampoo
    final intensiveSerum =
        findInCatalog(
          (p) =>
              p.name.toLowerCase().contains('regrowth') ||
              p.name.toLowerCase().contains('peptide') ||
              p.name.toLowerCase().contains('intensive'),
        ) ??
        findInCatalog((p) => p.category.toLowerCase().contains('serum'));
    if (intensiveSerum != null && !list.contains(intensiveSerum)) {
      list.add(intensiveSerum);
    }

    final hairSupp =
        findInCatalog(
          (p) =>
              p.name.toLowerCase().contains('tablet') ||
              p.name.toLowerCase().contains('multivitamin') ||
              p.name.toLowerCase().contains('nutrition') ||
              p.category.toLowerCase().contains('supplement'),
        ) ??
        findInCatalog((p) => p.category.toLowerCase().contains('supplement'));
    if (hairSupp != null && !list.contains(hairSupp)) {
      list.add(hairSupp);
    }

    final shampoo =
        findInCatalog(
          (p) =>
              p.name.toLowerCase().contains('dht') ||
              p.name.toLowerCase().contains('shampoo'),
        ) ??
        findInCatalog((p) => p.category.toLowerCase().contains('shampoo'));
    if (shampoo != null && !list.contains(shampoo)) {
      list.add(shampoo);
    }
  }

  // 2. Dandruff / Scalp condition
  if (dandruff.contains('flake') ||
      dandruff.contains('itch') ||
      dandruff.contains('dandruff')) {
    final match = findInCatalog(
      (p) =>
          p.id.contains('dandruff') ||
          p.name.toLowerCase().contains('dandruff') ||
          p.category.toLowerCase().contains('dandruff'),
    );
    if (match != null && !list.contains(match)) {
      list.add(match);
    }
  }

  // 3. Gut health
  if (gut.contains('sometimes') ||
      gut.contains('often') ||
      gut.contains('yes')) {
    final gutMatch = findInCatalog(
      (p) =>
          p.id.contains('gut') ||
          p.name.toLowerCase().contains('gut') ||
          p.category.toLowerCase().contains('gut'),
    );
    if (gutMatch != null && !list.contains(gutMatch)) {
      list.add(gutMatch);
    }
  }

  // 4. Stress
  if (stress.contains('high') ||
      stress.contains('extreme') ||
      stress.contains('moderate')) {
    final stressMatch = findInCatalog(
      (p) =>
          p.id.contains('stress') ||
          p.name.toLowerCase().contains('stress') ||
          p.category.toLowerCase().contains('stress'),
    );
    if (stressMatch != null && !list.contains(stressMatch)) {
      list.add(stressMatch);
    }
  }

  // Fallback to ensure at least 3 relevant products
  if (list.length < 3) {
    for (final p in catalog) {
      if (!list.contains(p)) {
        list.add(p);
      }
      if (list.length >= 3) break;
    }
  }

  return list.take(4).toList();
}

({String label, String asset})? _selectedPatternIllustration(
  HairTestState state,
) {
  final selected = state.primaryConcern?.trim();
  final value = selected == null || selected.isEmpty
      ? state.stage?.trim()
      : selected;
  if (value == null || value.isEmpty || value == 'Not sure') return null;

  const stageAssets = <String, String>{
    'Stage 1': 'assets/images/hair_assessment/stage_1.png',
    'Stage 2': 'assets/images/hair_assessment/stage_2.png',
    'Stage 3': 'assets/images/hair_assessment/stage_3.png',
    'Stage 4': 'assets/images/hair_assessment/stage_4.png',
    'Stage 5': 'assets/images/hair_assessment/stage_5.png',
  };
  for (final entry in stageAssets.entries) {
    if (value == entry.key || value.startsWith('${entry.key} -')) {
      return (label: entry.key, asset: entry.value);
    }
  }

  final normalized = value.toLowerCase();
  if (normalized.contains('patch')) {
    return (
      label: 'Patchy hair loss',
      asset: 'assets/images/hair_assessment/patchy_loss.png',
    );
  }
  if (normalized.contains('shed') || normalized.contains('hair fall')) {
    return (
      label: 'Hair shedding',
      asset: 'assets/images/hair_assessment/hair_fall.png',
    );
  }
  return null;
}
