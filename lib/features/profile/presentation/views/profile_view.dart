import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/app_button.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<void> _launchWhatsapp() async {
    const phoneNumber = '918058056789';
    final uri = Uri.parse('https://wa.me/$phoneNumber');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch WhatsApp');
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
                    onPressed: () {
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.primary,
                          content: Text(
                            'Authentication is not connected, so no account session was changed.',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
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
                  icon: LucideIcons.clipboardPlus,
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.primary5,
                  title: 'Treatment plan',
                  subtitle: 'View your regimen and dosage',
                  onTap: () => context.push(RouteNames.treatmentDetails),
                ),
                _ProfileMenuTile(
                  icon: LucideIcons.calendarCheck,
                  iconColor: const Color(0xFF059669),
                  iconBgColor: const Color(0xFFECFDF5),
                  title: 'Daily routine',
                  subtitle: 'Check off today’s care steps',
                  onTap: () => context.push(RouteNames.routine),
                ),
                _ProfileMenuTile(
                  icon: LucideIcons.chartNoAxesCombined,
                  iconColor: const Color(0xFF7C3AED),
                  iconBgColor: const Color(0xFFF5F3FF),
                  title: 'Progress journal',
                  subtitle: 'Review your check-ins over time',
                  onTap: () => context.push(RouteNames.progress),
                ),
                _ProfileMenuTile(
                  icon: LucideIcons.apple,
                  iconColor: const Color(0xFFEA580C),
                  iconBgColor: const Color(0xFFFFF7ED),
                  title: 'Nutrition guide',
                  subtitle: 'See daily meal ideas',
                  onTap: () => context.push(RouteNames.dietPlan),
                ),
                _ProfileMenuTile(
                  icon: LucideIcons.bell,
                  iconColor: const Color(0xFFCA8A04),
                  iconBgColor: const Color(0xFFFEFCE8),
                  title: 'Care reminders',
                  subtitle: 'Manage your reminder preferences',
                  onTap: () => context.push(RouteNames.reminders),
                ),
                _ProfileMenuTile(
                  icon: LucideIcons.phoneCall,
                  iconColor: const Color(0xFF0891B2),
                  iconBgColor: const Color(0xFFECFEFF),
                  title: 'Talk to a hair coach',
                  subtitle: 'Choose a time for a guidance call',
                  onTap: () => context.push(RouteNames.coachBooking),
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
                  icon: LucideIcons.shoppingBag,
                  iconColor: const Color(0xFF0284C7),
                  iconBgColor: const Color(0xFFF0F9FF),
                  title: 'My cart',
                  subtitle: 'Review products in your cart',
                  onTap: () => context.push(RouteNames.cart),
                ),
                _ProfileMenuTile(
                  icon: LucideIcons.packageCheck,
                  iconColor: const Color(0xFF059669),
                  iconBgColor: const Color(0xFFECFDF5),
                  title: 'Orders & delivery',
                  subtitle: 'Check your order status',
                  onTap: () => context.push(RouteNames.orders),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 22),
              _buildSectionHeader(
                title: 'ACCOUNT',
                subtitle: 'Your details and support',
              ),
              const SizedBox(height: 10),
              _buildGroupedCard([
                _ProfileMenuTile(
                  icon: LucideIcons.userRound,
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.primary5,
                  title: 'Personal information',
                  subtitle: 'Edit your profile details',
                  onTap: () => context.push(RouteNames.updateProfile),
                ),
                _ProfileMenuTile(
                  icon: LucideIcons.messageSquare,
                  iconColor: AppColors.whatsapp,
                  iconBgColor: AppColors.whatsapp.withValues(alpha: 0.12),
                  title: 'Contact support',
                  subtitle: 'Chat with the Dr.Hair team on WhatsApp',
                  onTap: _launchWhatsapp,
                ),
                _ProfileMenuTile(
                  icon: LucideIcons.logOut,
                  iconColor: AppColors.danger,
                  iconBgColor: AppColors.danger.withValues(alpha: 0.1),
                  title: 'Sign out',
                  subtitle: 'Sign out of this account',
                  isDestructive: true,
                  onTap: () => _showSignOutDialog(context),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Dr.Hair · Hair care, made personal',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
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
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary5,
            child: Icon(LucideIcons.userRound, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yashveer Soni',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Patient ID: DRH-2024-8849',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryDark,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Sign in',
                onPressed: () => context.push(RouteNames.signin),
                icon: const Icon(LucideIcons.logIn, color: AppColors.primary),
              ),
              IconButton(
                tooltip: 'Edit profile',
                onPressed: () => context.push(RouteNames.updateProfile),
                icon: const Icon(LucideIcons.pencil, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
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
    this.isDestructive = false,
    this.showDivider = true,
  }) : badgeColor = null,
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
