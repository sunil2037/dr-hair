import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/notifications/firebase_push_service.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/session/session_coordinator.dart';
import '../../../../core/storage/app_local_cache.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/viewmodels/auth_cubit.dart';
import '../../../auth/presentation/viewmodels/auth_state.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  static const String _pushCacheKey = 'push_notifications_enabled';
  bool _pushNotificationsEnabled = true;
  bool _isTogglingPush = false;

  @override
  void initState() {
    super.initState();
    _loadPushPreference();
  }

  Future<void> _loadPushPreference() async {
    final cached = AppLocalCache.instance.getBool(_pushCacheKey);
    if (cached != null && mounted) {
      setState(() {
        _pushNotificationsEnabled = cached;
      });
    }
  }

  Future<void> _onPushToggled(bool value) async {
    if (_isTogglingPush) return;
    setState(() {
      _isTogglingPush = true;
      _pushNotificationsEnabled = value;
    });

    try {
      await AppLocalCache.instance.put(_pushCacheKey, value);
      if (value) {
        await FirebasePushService.syncDeviceTokenWithBackend();
        if (mounted) {
          AppToast.show(
            context,
            const SnackBar(
              backgroundColor: AppColors.success,
              content: Text('Push notifications enabled for care alerts.'),
            ),
          );
        }
      } else {
        await FirebasePushService.unregisterDeviceToken();
        if (mounted) {
          AppToast.show(
            context,
            const SnackBar(
              backgroundColor: AppColors.secondaryDark,
              content: Text('Push notifications turned off.'),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Could not update notification preferences.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingPush = false);
      }
    }
  }

  void _showDeleteAccountSheet(BuildContext context) {
    String selectedReason = 'Completed my hair treatment';
    final reasons = [
      'Completed my hair treatment',
      'Privacy or data concerns',
      'Moving to another clinic',
      'Created a duplicate account',
      'Other reasons',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.alertTriangle,
                          color: AppColors.danger,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Permanently Delete Account?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'In compliance with DPDP data privacy standards, deleting your account will permanently erase your personal profile, assessment answers, routine check-ins, and active login sessions. Past clinical invoices and prescriptions are retained securely for mandatory medical record compliance.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reason for leaving (Optional):',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return ChoiceChip(
                        label: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.primaryDark,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setSheetState(() => selectedReason = reason);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Keep Account',
                          variant: AppButtonVariant.outlined,
                          borderColor: AppColors.border,
                          foregroundColor: AppColors.secondaryDark,
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Delete Forever',
                          variant: AppButtonVariant.filled,
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            _executeAccountDeletion(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _executeAccountDeletion(BuildContext context) async {
    final authCubit = context.read<AuthCubit?>();
    final success = await authCubit?.deleteAccount() ?? false;
    if (!context.mounted) return;

    if (success) {
      await SessionCoordinator.instance.signOut(context);
      if (context.mounted) {
        context.go(RouteNames.signin);
        AppToast.show(
          context,
          const SnackBar(
            backgroundColor: AppColors.primaryDark,
            content: Text('Your account and profile have been permanently deleted.'),
          ),
        );
      }
    } else {
      final error = authCubit?.state.errorMessage ??
          'Could not complete account deletion. Please try again.';
      AppToast.show(
        context,
        SnackBar(backgroundColor: AppColors.danger, content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primaryDark),
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : context.go(RouteNames.profile),
        ),
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state.user;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // 1. Notification Controls
              _buildSectionTitle('NOTIFICATIONS & ALERTS'),
              const SizedBox(height: 8),
              _buildCardContainer(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.bellRing,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Push Notifications',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Receive clinical care reminders, order tracking, and doctor updates.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.secondaryDark,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch.adaptive(
                      value: _pushNotificationsEnabled,
                      activeTrackColor: AppColors.primary,
                      activeThumbColor: Colors.white,
                      onChanged: _isTogglingPush ? null : _onPushToggled,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 2. Account Information
              _buildSectionTitle('PATIENT ACCOUNT'),
              const SizedBox(height: 8),
              _buildCardContainer(
                child: Column(
                  children: [
                    if (user != null) ...[
                      _buildInfoRow(
                        icon: LucideIcons.idCard,
                        label: 'Patient ID',
                        value: user.patientId,
                        trailing: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: user.patientId));
                            AppToast.show(
                              context,
                              const SnackBar(
                                content: Text('Patient ID copied to clipboard!'),
                              ),
                            );
                          },
                          child: const Icon(
                            LucideIcons.copy,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Divider(height: 20),
                    ],
                    _buildInfoRow(
                      icon: LucideIcons.user,
                      label: 'Full Name',
                      value: user?.name.isNotEmpty == true ? user!.name : 'Patient User',
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      icon: LucideIcons.mail,
                      label: 'Email',
                      value: user?.email?.isNotEmpty == true ? user!.email! : 'Not linked',
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      icon: LucideIcons.phone,
                      label: 'Mobile',
                      value: user?.phone?.isNotEmpty == true ? user!.phone! : 'Not linked',
                    ),
                    const Divider(height: 20),
                    InkWell(
                      onTap: () => context.push(RouteNames.updateProfile),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: const [
                            Icon(LucideIcons.userPen, size: 18, color: AppColors.primary),
                            SizedBox(width: 10),
                            Text(
                              'Edit Profile & Details',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Spacer(),
                            Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 3. Legal & Compliance
              _buildSectionTitle('LEGAL & POLICIES'),
              const SizedBox(height: 8),
              _buildCardContainer(
                child: Column(
                  children: [
                    _buildNavRow(
                      icon: LucideIcons.shieldCheck,
                      title: 'Privacy Policy',
                      subtitle: 'DPDP compliance and patient health record protection',
                      onTap: () => context.push(RouteNames.privacyPolicy),
                    ),
                    const Divider(height: 20),
                    _buildNavRow(
                      icon: LucideIcons.fileText,
                      title: 'Terms of Service',
                      subtitle: 'Platform agreements and consultation terms',
                      onTap: () => context.push(RouteNames.terms),
                    ),
                    const Divider(height: 20),
                    _buildNavRow(
                      icon: LucideIcons.receipt,
                      title: 'Return & Refund Policy',
                      subtitle: 'Guidelines for product returns and clinic fees',
                      onTap: () => context.push(RouteNames.returnsRefunds),
                    ),
                    const Divider(height: 20),
                    _buildNavRow(
                      icon: LucideIcons.ban,
                      title: 'Cancellation Policy',
                      subtitle: 'Appointment and order cancellation windows',
                      onTap: () => context.push(RouteNames.cancellationPolicy),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 4. App Info & Disclaimer
              _buildSectionTitle('APP INFO'),
              const SizedBox(height: 8),
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Dr. Hair Clinical Suite',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'Version 1.0.0 (Release)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Dr. Hair provides trichological wellness guidance and doctor consultations. It does not replace emergency medical diagnosis.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // 5. Danger Zone
              _buildSectionTitle('DANGER ZONE', color: AppColors.danger),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permanently Delete Account',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Erase your clinical hair assessment, routine check-ins, and user profile data forever. This cannot be undone.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        label: const Text(
                          'Delete My Account',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        onPressed: () => _showDeleteAccountSheet(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color color = AppColors.secondaryDark}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryDark,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          trailing,
        ],
      ],
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary5,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
