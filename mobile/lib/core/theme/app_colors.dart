import 'package:flutter/material.dart';

/// Centralized color palette for the DevOps Learning Platform mobile application.
///
/// These colors are directly derived from the Cyber Midnight design system
/// established in the web application (`web/src/index.css` and `design-system/`).
class AppColors {
  // Prevent instantiation of utility class
  AppColors._();

  // Core Canvas & Surfaces
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceElevated = Color(0xFF1E293B);
  static const Color surfaceCard = Color(0xE0111827); // 88% opacity
  static const Color inputBackground = Color(0xFF0B1120);

  // Primary Accent (Cyan)
  static const Color primary = Color(0xFF22D3EE);
  static const Color primaryHover = Color(0xFF06B6D4);
  static const Color primaryActive = Color(0xFF0891B2);
  static const Color primaryLight = Color(0xFF67E8F9);
  static const Color primarySubtle = Color(0x1F22D3EE); // 12% opacity
  static const Color primaryBorder = Color(0x5922D3EE); // 35% opacity

  // Secondary Accent (Lime)
  static const Color secondary = Color(0xFFA3E635);
  static const Color secondaryHover = Color(0xFF84CC16);
  static const Color secondaryActive = Color(0xFF65A30D);
  static const Color secondaryLight = Color(0xFFBEF264);
  static const Color secondarySubtle = Color(0x1FA3E635);
  static const Color secondaryBorder = Color(0x59A3E635);

  // Indigo Accent (Brand depth)
  static const Color indigo = Color(0xFF6366F1);
  static const Color indigoSubtle = Color(0x1F6366F1);
  static const Color indigoBorder = Color(0x596366F1);

  // Typography Colors
  static const Color textMain = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);

  // Semantic Feedback
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0x1FEF4444);
  static const Color errorBorder = Color(0x4DEF4444);

  static const Color success = Color(0xFFA3E635);
  static const Color successBg = Color(0x1FA3E635);
  static const Color successBorder = Color(0x59A3E635);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x1FF59E0B);
  static const Color warningBorder = Color(0x59F59E0B);

  // Borders & Dividers
  static const Color borderSubtle = Color(0x14FFFFFF); // 8% white
  static const Color borderDefault = Color(0xFF1E293B);
  static const Color borderHover = Color(0xFF334155);
}
