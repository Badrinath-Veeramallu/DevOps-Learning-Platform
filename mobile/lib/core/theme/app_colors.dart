import 'package:flutter/material.dart';

/// Centralized color palette for the DevOps Learning Platform mobile application.
///
/// These colors are directly derived from the Deep Burgundy design system
/// established in the web application (`web/src/index.css` and `design-system/devops-learning-platform/MASTER.md`).
class AppColors {
  // Prevent instantiation of utility class
  AppColors._();

  // Core Canvas & Surfaces (White + Pale Blush Light Theme)
  static const Color background = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFCF8F9);
  static const Color gridLine = Color(0xFFF5ECEF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFCF8F9);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x143B1F24); // ~8% burgundy shadow

  // Primary Accent (Deep Burgundy)
  static const Color primary = Color(0xFF3B1F24);
  static const Color primaryHover = Color(0xFF4D2930);
  static const Color primaryActive = Color(0xFF2E171B);
  static const Color primaryLight = Color(0xFF82535D);
  static const Color primarySubtle = Color(0xFFF5ECEF); // Subtle blush fill
  static const Color primaryBorder = Color(0xFFE7D4D7); // Pale blush border

  // Secondary Accent (Muted Burgundy)
  static const Color secondary = Color(0xFF60343D);
  static const Color secondaryHover = Color(0xFF723D48);
  static const Color secondaryActive = Color(0xFF4E2A31);
  static const Color secondaryLight = Color(0xFFB88A91);
  static const Color secondarySubtle = Color(0xFFFCF8F9);
  static const Color secondaryBorder = Color(0xFFE8DDE0);

  // Accent & Highlights (Dusty Rose & Soft Rose & Pale Blush)
  static const Color accent = Color(0xFF82535D);
  static const Color lightAccent = Color(0xFFB88A91);
  static const Color paleBlush = Color(0xFFE7D4D7);
  static const Color subtleHighlight = Color(0xFFE7D4D7);

  // Dusty Mauve Highlights (Aliased for backward compatibility)
  static const Color indigo = Color(0xFF82535D);
  static const Color indigoSubtle = Color(0xFFF5ECEF);
  static const Color indigoBorder = Color(0xFFE7D4D7);

  // Typography Colors (Website Dark Ink & Muted Ink)
  static const Color textMain = Color(0xFF171521);
  static const Color textMuted = Color(0xFF454252);
  static const Color textSubtle = Color(0xFF797587);

  // Semantic Feedback (Light Theme Accessible Contrast)
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);
  static const Color errorText = Color(0xFF991B1B);

  static const Color success = Color(0xFF15803D);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);
  static const Color successText = Color(0xFF15803D);

  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);
  static const Color warningText = Color(0xFF92400E);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFFF5ECEF);
  static const Color borderDefault = Color(0xFFE8DDE0);
  static const Color borderHover = Color(0xFFB88A91);

  // Pathway Winding Road Palette (Matches Web SVG Road)
  static const Color roadCushion = Color(0xFFF7EFF1);
  static const Color roadBase = Color(0xFFEDDFE2);
  static const Color roadDash = Color(0xFF82535D);

  // Code Block & Animation Terminal Dark Surfaces (Preserved per Web UI)
  static const Color codeBackground = Color(0xFF171521);
  static const Color codeHeader = Color(0xFF110E19);
  static const Color codeText = Color(0xFFF5ECEF);
  static const Color terminalBackground = Color(0xFF2A1419);
  static const Color terminalHeader = Color(0xFF1E0D11);
  static const Color terminalText = Color(0xFFECDEE1);
}
