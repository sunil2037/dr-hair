import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Shows one brief, dismissible toast-style message above the current screen.
/// A new message replaces any visible or queued message so feedback never stacks.
class AppToast {
  AppToast._();

  static const Duration _messageDuration = Duration(milliseconds: 2200);
  static const Duration _actionDuration = Duration(seconds: 3);

  static void show(BuildContext context, SnackBar message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null || !context.mounted) return;

    // Remove old feedback immediately instead of queueing messages behind it.
    messenger.clearSnackBars();
    messenger.removeCurrentSnackBar();
    final duration = message.action == null ? _messageDuration : _actionDuration;
    messenger.showSnackBar(
      SnackBar(
        content: message.content,
        action: message.action,
        backgroundColor: message.backgroundColor ?? AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        showCloseIcon: false,
      ),
    );
  }
}
