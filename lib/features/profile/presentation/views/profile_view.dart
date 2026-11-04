import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/session/session_coordinator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/assessment_gate.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/viewmodels/auth_cubit.dart';
import '../../../auth/presentation/viewmodels/auth_state.dart';
import '../../../shop/presentation/viewmodels/cart_cubit.dart';
import '../../../hair_test/presentation/viewmodels/hair_test_cubit.dart';
import '../../../hair_test/presentation/viewmodels/hair_test_state.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  void _openPersonalizedFeature(BuildContext context, String route) {
    final state =
        context.read<HairTestCubit?>()?.state ?? const HairTestState();
    if (!state.isCompleted || state.isRetesting) {
      showAssessmentRequiredSheet(context);
      return;
    }
    context.push(route);
  }

  void _showSignOutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,

      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.logOut,
                color: AppColors.danger,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign Out of Dr.Hair?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You will need to verify your registered phone number or email to access your clinical treatment records.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Cancel',
                    variant: AppButtonVariant.outlined,
                    borderColor: AppColors.border,
                    foregroundColor: AppColors.secondaryDark,
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Sign Out',
                    variant: AppButtonVariant.filled,
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    onPressed: () async {
                      Navigator.pop(modalContext);
                      await SessionCoordinator.instance.signOut(context);
                      if (context.mounted) {
                        context.go(RouteNames.signin);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top + 20.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(
            title: 'YOUR CARE',
            subtitle: 'The tools for your hair health journey',
          ),
          const SizedBox(height: 10),
          _buildGroupedCard([
            _ProfileMenuTile(
              icon: LucideIcons.clipboardCheck,
              iconColor: const Color(0xFF0D9488),
              iconBgColor: const Color(0xFFF0FDFA),
              title: 'Assessment result',
              subtitle: 'Review your assessment answers and summary',
              onTap: () => context.push(RouteNames.assessmentResult),
            ),
            _ProfileMenuTile(
              icon: LucideIcons.calendarDays,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary5,
              title: 'Clinic appointments',
              subtitle: 'Request a physical visit with Dr. Jai Bansal',
              onTap: () => context.push(RouteNames.clinicAppointment),
            ),
            _ProfileMenuTile(
              icon: LucideIcons.clipboardPlus,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary5,
              title: 'Treatment plan',
              subtitle: 'View your regimen and dosage',
              onTap: () => _openPersonalizedFeature(
                context,
                RouteNames.treatmentDetails,
              ),
            ),
            _ProfileMenuTile(
              icon: LucideIcons.calendarCheck,
              iconColor: const Color(0xFF059669),
              iconBgColor: const Color(0xFFECFDF5),
              title: 'Daily routine',
              subtitle: 'Check off today’s care steps',
              onTap: () =>
                  _openPersonalizedFeature(context, RouteNames.routine),
            ),
            _ProfileMenuTile(
              icon: LucideIcons.chartNoAxesCombined,
              iconColor: const Color(0xFF7C3AED),
              iconBgColor: const Color(0xFFF5F3FF),
              title: 'Progress journal',
              subtitle: 'Review your check-ins over time',
              onTap: () =>
                  _openPersonalizedFeature(context, RouteNames.progress),
            ),
            _ProfileMenuTile(
              icon: LucideIcons.apple,
              iconColor: const Color(0xFFEA580C),
              iconBgColor: const Color(0xFFFFF7ED),
              title: 'Nutrition guide',
              subtitle: 'See daily meal ideas',
              onTap: () =>
                  _openPersonalizedFeature(context, RouteNames.dietPlan),
            ),
            _ProfileMenuTile(
              icon: LucideIcons.bell,
              iconColor: const Color(0xFFCA8A04),
              iconBgColor: const Color(0xFFFEFCE8),
              title: 'Care reminders',
              subtitle: 'Manage your reminder preferences',
              onTap: () =>
                  _openPersonalizedFeature(context, RouteNames.reminders),
              showDivider: false,
            ),
          ]),
          const SizedBox(height: 22),
          _buildSectionHeader(
            title: 'ORDERS',
            subtitle: 'Your products and deliveries',
          ),
          const SizedBox(height: 10),
          _buildGroupedCard([
            _ProfileMenuTile(
              icon: LucideIcons.packageCheck,
              iconColor: const Color(0xFF059669),
              iconBgColor: const Color(0xFFECFDF5),
              title: 'Orders & delivery',
              subtitle: 'Check your order status',
              onTap: () => context.push(RouteNames.orders),
            ),
            Builder(
              builder: (context) {
                final cart = context.read<CartCubit?>();
                Widget tile(int itemCount) => _ProfileMenuTile(
                  icon: LucideIcons.shoppingBag,
                  iconColor: const Color(0xFF0284C7),
                  iconBgColor: const Color(0xFFF0F9FF),
                  title: 'My cart',
                  subtitle: itemCount == 0
                      ? 'Your cart is empty'
                      : '$itemCount ${itemCount == 1 ? 'item' : 'items'} ready to review',
                  onTap: () => context.push(RouteNames.cart),
                  showDivider: false,
                );
                if (cart == null) return tile(0);
                return BlocBuilder<CartCubit, CartState>(
                  builder: (context, state) => tile(state.itemCount),
                );
              },
            ),
          ]),
          const SizedBox(height: 22),
          _buildSectionHeader(
            title: 'PREFERENCES',
            subtitle: 'Notification toggles, policies, and account security',
          ),
          const SizedBox(height: 10),
          _buildGroupedCard([
            _ProfileMenuTile(
              icon: LucideIcons.settings,
              iconColor: const Color(0xFF0F766E),
              iconBgColor: const Color(0xFFF0FDFA),
              title: 'Settings & preferences',
              subtitle: 'Alerts, account info, policies, and deletion',
              onTap: () => context.push(RouteNames.settings),
              showDivider: false,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSignOutButton(context),

          const SizedBox(height: 60),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dr.Hair · Hair care, made personal',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                SizedBox(height: 4),
                Text(
                  'App Version ${AppStrings.appVersion}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showSignOutDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.logOut,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Sign out',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.secondaryDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context) {
    final authCubit = context.read<AuthCubit?>();

    Widget buildCard(UserModel? user) {
      final previewUser = authCubit == null ? UserModel.demoPatient() : null;
      final profile = user ?? previewUser;
      final name = profile?.name.isNotEmpty == true
          ? profile!.name
          : 'Your profile';
      final patientId = profile?.patientId.isNotEmpty == true
          ? profile!.patientId
          : 'Complete your profile';

      final photoUrl = user?.photoUrl;

      Widget avatarWidget;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        if (photoUrl.startsWith('http')) {
          avatarWidget = ClipOval(
            child: CustomCachedImage(
              imageUrl: photoUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          );
        } else {
          avatarWidget = ClipOval(
            child: Image.file(
              File(photoUrl),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary5,
                child: Icon(LucideIcons.userRound, color: AppColors.primary),
              ),
            ),
          );
        }
      } else {
        avatarWidget = const CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary5,
          child: Icon(LucideIcons.userRound, color: AppColors.primary),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            avatarWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  // const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Patient ID: $patientId',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: patientId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Patient ID copied'),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.copy, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => context.push(RouteNames.settings),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.settings,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.push(RouteNames.updateProfile),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.pencil,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (authCubit != null) {
      return BlocBuilder<AuthCubit, AuthState>(
        bloc: authCubit,
        builder: (context, state) => buildCard(state.user),
      );
    }
    return buildCard(null);
  }
}

/// An interactive, micro-animated profile menu item tile with tactile feedback.
class _ProfileMenuTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showDivider;

  const _ProfileMenuTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  }) : isDestructive = false,
       badgeColor = null,
       badgeText = null;

  @override
  State<_ProfileMenuTile> createState() => _ProfileMenuTileState();
}

class _ProfileMenuTileState extends State<_ProfileMenuTile> {
  bool _isPressed = false;

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations = MediaQuery.disableAnimationsOf(context);
    final Duration motionDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 130);

    return Column(
      children: [
        AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: motionDuration,
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: _handleTap,
              splashColor: widget.iconColor.withValues(alpha: 0.08),
              highlightColor: widget.iconColor.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.isDestructive
                            ? AppColors.danger.withValues(alpha: 0.1)
                            : widget.iconBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.isDestructive
                            ? AppColors.danger
                            : widget.iconColor,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isDestructive
                                        ? AppColors.danger
                                        : AppColors.primaryDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.badgeText != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (widget.badgeColor ?? AppColors.primary)
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    widget.badgeText!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          widget.badgeColor ??
                                          AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryDark,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Trailing Arrow
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: widget.isDestructive
                          ? AppColors.danger.withValues(alpha: 0.5)
                          : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.showDivider)
          const Divider(
            height: 1,
            indent: 74,
            endIndent: 16,
            color: Color(0xFFF1F5F9),
          ),
      ],
    );
  }
}
