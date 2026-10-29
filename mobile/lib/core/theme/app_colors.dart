import 'package:flutter/material.dart';

/// Centralized color palette for the DevOps Learning Platform mobile application.
///
/// These colors are directly derived from the Deep Burgundy design system
/// established in the web application (`web/src/index.css` and `design-system/devops-learning-platform/MASTER.md`).
class AppColors {
  // Prevent instantiation of utility class
  AppColors._();

  // Core Canvas & Surfaces
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF0F172A);
  static const Color surfaceElevated = Color(0xFF1E293B);
  static const Color surfaceCard = Color(0xE00F172A); // 88% opacity
  static const Color inputBackground = Color(0xFF090D16);

  // Primary Accent (Deep Burgundy)
  static const Color primary = Color(0xFF3B1F24);
  static const Color primaryHover = Color(0xFF4D2930);
  static const Color primaryActive = Color(0xFF2E171B);
  static const Color primaryLight = Color(0xFF82535D);
  static const Color primarySubtle = Color(0x333B1F24); // ~20% opacity
  static const Color primaryBorder = Color(0x6682535D); // ~40% opacity dusty rose

  // Secondary Accent (Muted Burgundy)
  static const Color secondary = Color(0xFF60343D);
  static const Color secondaryHover = Color(0xFF723D48);
  static const Color secondaryActive = Color(0xFF4E2A31);
  static const Color secondaryLight = Color(0xFFB88A91);
  static const Color secondarySubtle = Color(0x3360343D);
  static const Color secondaryBorder = Color(0x66B88A91);

  // Accent & Highlights (Dusty Rose & Soft Rose & Pale Blush)
  static const Color accent = Color(0xFF82535D);
  static const Color lightAccent = Color(0xFFB88A91);
  static const Color subtleHighlight = Color(0xFFE7D4D7);

  // Legacy alias for brand depth (Dusty Rose)
  static const Color indigo = Color(0xFF82535D);
  static const Color indigoSubtle = Color(0x3382535D);
  static const Color indigoBorder = Color(0x6682535D);

  // Typography Colors
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);

  // Semantic Feedback (Preserved strictly)
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0x1FEF4444);
  static const Color errorBorder = Color(0x4DEF4444);

  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0x1F10B981);
  static const Color successBorder = Color(0x5910B981);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x1FF59E0B);
  static const Color warningBorder = Color(0x59F59E0B);

  // Borders & Dividers
  static const Color borderSubtle = Color(0x14FFFFFF); // 8% white
  static const Color borderDefault = Color(0xFF1E293B);
  static const Color borderHover = Color(0xFF334155);
}
