import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Navy Brand Palette (from React Theme & UIColors)
  static const Color primary = Color(0xFF1A365D);
  static const Color primary800 = Color(0xFF2E486D);
  static const Color primary700 = Color(0xFF435B7C);
  static const Color primary600 = Color(0xFF596E8C);
  static const Color primary500 = Color(0xFF6F819C);
  static const Color primary200 = Color(0xFFB4BFCD);
  static const Color primary100 = Color(0xFFD6E0FC);
  static const Color primary50 = Color(0xFFEFF6FF);
  static const Color primary5 = Color(0xFFF0F7FF);
  static const Color secondary = Color(0xFF0D9488); // Teal accent

  // Surface & Neutrals
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF0F7FF);
  static const Color card = Color(0xFFD6E0FC);
  static const Color border = Color(0xFFE2E8F0);

  // Neutrals Palette
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A365D);
  static const Color primaryDark = Color(0xFF1A1C1C);
  static const Color secondaryDark = Color(0xFF444655);
  static const Color textSecondary = Color(0xFF596E8C);
  static const Color textMuted = Color(0xFFA0A4A8);

  // Status & Brand Accents
  static const Color whatsapp = Color(0xFF25D366);
  static const Color starGold = Color(0xFFFFA500);
  static const Color danger = Color(0xFFC40C0C);
  static const Color success = Color(0xFF358916);
  static const Color error = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF002147)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    colors: [Color(0xFFD6E0FC), Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
