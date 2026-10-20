import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../routes/route_names.dart';

/// Clean, medical-grade top navigation bar for Dr.Hair app.
/// Supports smooth transparency transition on scroll via [scrollProgress] (0.0 = transparent, 1.0 = solid white).
/// Supports [isDark] to adapt styling and status bar icons to dark backgrounds (e.g. video reels).
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showNotifications;
  final bool showWhatsApp;
  final List<Widget>? extraActions;
  final double scrollProgress;
  final bool isDark;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    this.showNotifications = true,
    this.showWhatsApp = true,
    this.extraActions,
    this.scrollProgress = 1.0,
    this.isDark = false,
    this.leading,
  });

  Future<void> _launchWhatsapp() async {
    HapticFeedback.lightImpact();
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
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double progress = scrollProgress.clamp(0.0, 1.0);
    final bool canPop = Navigator.of(context).canPop();

    final SystemUiOverlayStyle overlayStyle = isDark
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          )
        : (progress > 0.4
              ? const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                )
              : const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                ));

    final BoxDecoration decoration = isDark
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          )
        : BoxDecoration(
            color: Colors.white.withValues(alpha: progress),
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: progress),
                width: 1,
              ),
            ),
            boxShadow: progress > 0.05
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05 * progress),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        decoration: decoration,
        padding: EdgeInsets.only(
          top: topPadding + 4,
          left: 12,
          right: 12,
          bottom: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Optional back button + Logo
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null)
                  leading!
                else if (canPop)
                  IconButton(
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: isDark ? Colors.white : AppColors.primary,
                      size: 22,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    tooltip: 'Back',
                    splashRadius: 20,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Image.asset(
                    'assets/images/icon.png',
                    height: 38,
                    fit: BoxFit.contain,
                    color: isDark ? Colors.white : null,
                    colorBlendMode: isDark ? BlendMode.srcIn : null,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'Dr.Hair',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Actions: Notifications, WhatsApp
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showWhatsApp)
                  IconButton(
                    onPressed: _launchWhatsapp,
                    icon: Image.asset("assets/icons/whatsapp.png", height: 24),
                    tooltip: 'WhatsApp Consultation',
                    splashRadius: 20,
                  ),
                if (showNotifications)
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push(RouteNames.notifications);
                    },
                    icon: Icon(
                      LucideIcons.bell,
                      color: isDark ? Colors.white : AppColors.primary,
                      size: 22,
                    ),
                    tooltip: 'Notifications',
                    splashRadius: 22,
                  ),

                if (extraActions != null) ...?extraActions,
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
