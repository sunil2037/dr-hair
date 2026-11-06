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
    final state = widget.state;
    final selectedPattern = _selectedPatternIllustration(state);
    final String trimmedName = state.name.trim();
    final String displayName = trimmedName.isNotEmpty
        ? '${trimmedName[0].toUpperCase()}${trimmedName.substring(1)}, ${state.age}'
        : 'Patient, ${state.age}';

    final recommendedProducts = _getRecommendedProducts(state);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primaryDark),
          onPressed: () {
            context.read<HairTestCubit>().dismissReport();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RouteNames.mainShell);
            }
          },
        ),
        title: const Text(
          'Assessment Report',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Main Diagnosis Card
              Container(
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
                    // Status Badge
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8EE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.checkCircle2,
                            color: Color(0xFF1B6A47),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Assessment complete',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B6A47),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (selectedPattern != null) ...[
                      const SizedBox(height: 4),
                      _buildSelectedPatternCard(selectedPattern),
                      const SizedBox(height: 16),
                    ],

                    // Patient Header Row with Avatar
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Your answers suggest',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.secondaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                state.assessmentSummary,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.primary5,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            LucideIcons.clipboardCheck,
                            color: AppColors.primary,
                            size: 25,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
              ),

              // 2. Doctor's Clinical Report Section (if available)
              if (state.clinicalReports.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildDoctorClinicalReportsSection(context, state.clinicalReports),
              ],

              const SizedBox(height: 20),

              // 3. Clinical Scalp Photos Section (Replacing fake AI analysis HUD)
              _buildScalpPhotosSection(context, state),

              const SizedBox(height: 20),

              // 4. Recommended Clinical Products Section
              _buildRecommendedProductsSection(context, recommendedProducts),

              const SizedBox(height: 20),

              // 5. In-Clinic Doctor Consultation / Appointment Booking
              _buildDoctorAppointmentCard(context),

              const SizedBox(height: 20),

              // 6. Summary Card
              _buildSummaryCard(state),

              const SizedBox(height: 16),

              // 7. Medical Disclaimer Box
              _buildDisclaimerBox(),

              const SizedBox(height: 24),

              // 8. Next steps & routine setup
              _buildPostAssessmentNextSteps(context),

              const SizedBox(height: 24),

              // 9. Actions
              AppButton(
                height: 50,
                text: 'Explore recommended products',
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.large,
                width: double.infinity,
                onPressed: () {
                  context.read<HairTestCubit>().dismissReport();
                  context.push(RouteNames.products);
                },
              ),

              const SizedBox(height: 12),

              AppButton(
                height: 50,
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
                const SizedBox(height: 4),
                Text(
                  pattern.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This is the illustration you selected.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.secondaryDark,
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
    final photos = state.photos;
    final hasAnyPhoto = photos.values.any((p) => p.isNotEmpty);

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
                      'Photos shared with Dr. Jai Bansal for trichology review',
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
          if (hasAnyPhoto) ...[
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPhotoThumbnailCard(context, 'Front Hairline', photos['Front Hairline']),
                _buildPhotoThumbnailCard(context, 'Crown / Top', photos['Crown / Top']),
                _buildPhotoThumbnailCard(context, 'Side Profile', photos['Side Profile / Temples']),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.image, size: 28, color: AppColors.secondaryDark),
                  const SizedBox(width: 12),
                  const Expanded(
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
                          style: TextStyle(fontSize: 11, color: AppColors.secondaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _promptUploadPhoto(context),
            icon: const Icon(LucideIcons.camera, size: 15, color: AppColors.primary),
            label: Text(
              hasAnyPhoto ? 'Upload / Update Scalp Photos' : 'Add Scalp Photos for Doctor',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnailCard(BuildContext context, String angle, String? path) {
    final bool hasImage = path != null && path.isNotEmpty;

    return InkWell(
      onTap: () {
        if (hasImage) {
          _viewFullImage(context, path, angle);
        } else {
          _promptUploadPhoto(context, initialAngle: angle);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: hasImage ? Colors.black87 : AppColors.primary5,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage) ...[
              if (path.startsWith('http://') || path.startsWith('https://'))
                CustomCachedImage(imageUrl: path, fit: BoxFit.cover)
              else
                Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(LucideIcons.image, color: Colors.white60),
                ),
            ] else ...[
              const Center(
                child: Icon(LucideIcons.plus, size: 24, color: AppColors.primary),
              ),
            ],
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                color: Colors.black.withValues(alpha: 0.7),
                child: Text(
                  angle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewFullImage(BuildContext context, String path, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: path.startsWith('http')
                  ? CustomCachedImage(imageUrl: path, fit: BoxFit.contain)
                  : Image.file(File(path), fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(LucideIcons.x, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptUploadPhoto(BuildContext context, {String? initialAngle}) async {
    final angle = initialAngle ?? 'Crown / Top';
    final cubit = context.read<HairTestCubit?>();
    if (cubit == null) return;

    PhotoSourceBottomSheet.show(
      context,
      title: 'Upload Scalp Photo',
      subtitle: 'Select image source for $angle',
      cameraSubtitle: 'Capture clear view of your hair/scalp',
      gallerySubtitle: 'Choose from your photo library',
      hasExistingPhoto: cubit.state.hasPhoto(angle),
      onSelectSource: (source) => cubit.pickPhoto(label: angle, source: source),
    );
  }

  Widget _buildRecommendedProductsSection(
    BuildContext context,
    List<ProductItem> products,
  ) {
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Clinical Products',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tailored formulations based on your root cause & scalp status',
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
          if (products.isNotEmpty) ...[
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
                Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorAppointmentCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prefer an In-Person Clinical Assessment?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Consult Dr. Jai Bansal (Dermatologist & Hair Specialist)',
                      style: TextStyle(
                        fontSize: 11,
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
          const Text(
            'Get a comprehensive digital trichoscopy examination, clinical blood biomarker review, and doctor-prescribed customized treatment regimen at Dr. Hair OPD Clinic.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Book Consultation (₹500)',
            variant: AppButtonVariant.filled,
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            icon: const Icon(LucideIcons.calendarCheck2, size: 16, color: Colors.white),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16A34A),
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
                            side: const BorderSide(color: Color(0xFF16A34A)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(LucideIcons.download, size: 14),
                          label: const Text(
                            'View PDF',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () async {
                            final cubit = context.read<HairTestCubit?>();
                            if (cubit != null && reportId.isNotEmpty) {
                              final uri =
                                  await cubit.getReportDownloadUri(reportId);
                              if (uri != null) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not open report. Please try again.',
                                      ),
                                    ),
                                  );
                                }
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
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
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
              'Complete your hair assessment to unlock your routine and progress tools.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.secondaryDark,
              ),
            ),
            const SizedBox(height: 14),
            AppButton(
              text: 'Start my assessment',
              variant: AppButtonVariant.filled,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => context.push(RouteNames.hairTest),
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
    final photoCount = state.photos.values.where((p) => p.isNotEmpty).length;
    final details = <MapEntry<String, String>>[];

    void addDetail(String label, String? value) {
      final trimmedValue = value?.trim();
      if (trimmedValue != null && trimmedValue.isNotEmpty) {
        details.add(MapEntry(label, trimmedValue));
      }
    }

    addDetail('Hair concern', state.primaryConcern ?? state.stage);
    addDetail('Duration', state.duration);
    addDetail('Scalp concern', state.dandruff);
    addDetail('Gut health', state.gutHealth);
    addDetail('Stress & lifestyle', state.stressLevel);
    addDetail('Family history', state.familyHistory);
    details.add(
      MapEntry(
        'Photos',
        photoCount > 0 ? '$photoCount added' : 'Not added · optional',
      ),
    );

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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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

List<ProductItem> _getRecommendedProducts(HairTestState state) {
  final catalog = ProductItem.demoCatalog;

  final list = <ProductItem>[];
  final dandruff = (state.dandruff ?? '').toLowerCase();
  final gut = (state.gutHealth ?? '').toLowerCase();
  final stress = (state.stressLevel ?? '').toLowerCase();

  // 1. Dandruff / Scalp condition
  if (dandruff.contains('flake') || dandruff.contains('itch') || dandruff.contains('dandruff')) {
    final match = catalog.firstWhere(
      (p) => p.id.contains('dandruff') || p.category.toLowerCase().contains('dandruff'),
      orElse: () => catalog.first,
    );
    if (!list.contains(match)) list.add(match);
  }

  // 2. Primary Hair Regrowth Serum
  final serum = catalog.firstWhere(
    (p) => p.id.contains('regrowth') || p.name.toLowerCase().contains('serum'),
    orElse: () => catalog.first,
  );
  if (!list.contains(serum)) list.add(serum);

  // 3. Gut health
  if (gut.contains('sometimes') || gut.contains('often') || gut.contains('yes')) {
    final gutMatch = catalog.firstWhere(
      (p) => p.id.contains('gut') || p.category.toLowerCase().contains('gut'),
      orElse: () => catalog.first,
    );
    if (!list.contains(gutMatch)) list.add(gutMatch);
  }

  // 4. Stress
  if (stress.contains('high') || stress.contains('extreme') || stress.contains('moderate')) {
    final stressMatch = catalog.firstWhere(
      (p) => p.id.contains('stress') || p.category.toLowerCase().contains('stress'),
      orElse: () => catalog.first,
    );
    if (!list.contains(stressMatch)) list.add(stressMatch);
  }

  if (list.isEmpty) {
    list.addAll(catalog.take(3));
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
