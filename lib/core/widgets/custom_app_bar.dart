import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../routes/route_names.dart';

/// Clean, medical-grade top navigation bar for Dr.Hair app.
/// Supports smooth transparency transition on scroll via [scrollProgress] (0.0 = transparent, 1.0 = solid white).
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showCart;
  final bool showWhatsApp;
  final List<Widget>? extraActions;
  final double scrollProgress;

  const CustomAppBar({
    super.key,
    this.showCart = true,
    this.showWhatsApp = true,
    this.extraActions,
    this.scrollProgress = 1.0,
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

    return Container(
      decoration: BoxDecoration(
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
      ),
      padding: EdgeInsets.only(
        top: topPadding + 4,
        left: 16,
        right: 12,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo with soft frosted background when transparent for high legibility
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: (1.0 - progress) * 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              'assets/images/icon.png',
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                'Dr.Hair',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Actions: Shopping Cart, WhatsApp
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showWhatsApp)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: (1.0 - progress) * 0.85,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _launchWhatsapp,
                    icon: const Icon(
                      LucideIcons.messageCircle,
                      color: AppColors.whatsapp,
                      size: 24,
                    ),
                    tooltip: 'WhatsApp Consultation',
                    splashRadius: 20,
                  ),
                ),
              if (showCart)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: (1.0 - progress) * 0.85,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push(RouteNames.cart);
                    },
                    icon: const Icon(
                      LucideIcons.shoppingBag,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    tooltip: 'Shopping Cart',
                    splashRadius: 22,
                  ),
                ),

              if (extraActions != null) ...?extraActions,
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
