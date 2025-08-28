import 'package:flutter/material.dart';

/// App color scheme for both light and dark modes
class AppColors {
  // Primary colors - Modern teal/cyan instead of blue
  static const Color primaryLight = Color(0xFF21539A);
  static const Color primaryDark = Color(0xFF89A1DD);

  // Secondary colors - Complementary purple
  static const Color secondaryLight = Color(0xFF7C4DFF);
  static const Color secondaryDark = Color(0xFFB388FF);

  // Background colors - Clean whites and dark grays
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text colors - High contrast for readability
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textHintLight = Color(0xFF9E9E9E);
  static const Color textHintDark = Color(0xFF808080);

  // Status colors - Vibrant and accessible
  static const Color successLight = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF81C784);
  static const Color warningLight = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFFFB74D);
  static const Color errorLight = Color(0xFFF44336);
  static const Color errorDark = Color(0xFFE57373);
  static const Color infoLight = Color(0xFF00BFA5);
  static const Color infoDark = Color(0xFF4DD0E1);

  // Torrent status colors - Distinct and meaningful
  static const Color downloadingLight = Color(0xFF4CAF50);
  static const Color downloadingDark = Color(0xFF81C784);
  static const Color seedingLight = Color(0xFF00BFA5);
  static const Color seedingDark = Color(0xFF4DD0E1);
  static const Color pausedLight = Color(0xFFFF9800);
  static const Color pausedDark = Color(0xFFFFB74D);
  static const Color completedLight = Color(0xFF9C27B0);
  static const Color completedDark = Color(0xFFBA68C8);
  static const Color erroredLight = Color(0xFFF44336);
  static const Color erroredDark = Color(0xFFE57373);
  static const Color stalledLight = Color(0xFF9E9E9E);
  static const Color stalledDark = Color(0xFFB0B0B0);

  // Transfer colors - Green for download, teal for upload
  static const Color downloadSpeedLight = Color(0xFF4CAF50);
  static const Color downloadSpeedDark = Color(0xFF81C784);
  static const Color uploadSpeedLight = Color(0xFF00BFA5);
  static const Color uploadSpeedDark = Color(0xFF4DD0E1);

  // Border and divider colors - Subtle and clean
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF424242);
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);

  // Shadow colors - Subtle shadows
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x1AFFFFFF);

  // Overlay colors - For modals and overlays
  static const Color overlayLight = Color(0x80000000);
  static const Color overlayDark = Color(0x80FFFFFF);

  /// Get colors based on brightness
  static AppColorScheme getScheme(Brightness brightness) {
    return brightness == Brightness.light
        ? AppColorScheme.light()
        : AppColorScheme.dark();
  }
}

/// Color scheme for a specific brightness
class AppColorScheme {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color downloading;
  final Color seeding;
  final Color paused;
  final Color completed;
  final Color errored;
  final Color stalled;
  final Color downloadSpeed;
  final Color uploadSpeed;
  final Color border;
  final Color divider;
  final Color shadow;
  final Color overlay;

  const AppColorScheme({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.downloading,
    required this.seeding,
    required this.paused,
    required this.completed,
    required this.errored,
    required this.stalled,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.border,
    required this.divider,
    required this.shadow,
    required this.overlay,
  });

  /// Light theme color scheme
  factory AppColorScheme.light() {
    return const AppColorScheme(
      primary: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      background: AppColors.backgroundLight,
      surface: AppColors.surfaceLight,
      textPrimary: AppColors.textPrimaryLight,
      textSecondary: AppColors.textSecondaryLight,
      textHint: AppColors.textHintLight,
      success: AppColors.successLight,
      warning: AppColors.warningLight,
      error: AppColors.errorLight,
      info: AppColors.infoLight,
      downloading: AppColors.downloadingLight,
      seeding: AppColors.seedingLight,
      paused: AppColors.pausedLight,
      completed: AppColors.completedLight,
      errored: AppColors.erroredLight,
      stalled: AppColors.stalledLight,
      downloadSpeed: AppColors.downloadSpeedLight,
      uploadSpeed: AppColors.uploadSpeedLight,
      border: AppColors.borderLight,
      divider: AppColors.dividerLight,
      shadow: AppColors.shadowLight,
      overlay: AppColors.overlayLight,
    );
  }

  /// Dark theme color scheme
  factory AppColorScheme.dark() {
    return const AppColorScheme(
      primary: AppColors.primaryDark,
      secondary: AppColors.secondaryDark,
      background: AppColors.backgroundDark,
      surface: AppColors.surfaceDark,
      textPrimary: AppColors.textPrimaryDark,
      textSecondary: AppColors.textSecondaryDark,
      textHint: AppColors.textHintDark,
      success: AppColors.successDark,
      warning: AppColors.warningDark,
      error: AppColors.errorDark,
      info: AppColors.infoDark,
      downloading: AppColors.downloadingDark,
      seeding: AppColors.seedingDark,
      paused: AppColors.pausedDark,
      completed: AppColors.completedDark,
      errored: AppColors.erroredDark,
      stalled: AppColors.stalledDark,
      downloadSpeed: AppColors.downloadSpeedDark,
      uploadSpeed: AppColors.uploadSpeedDark,
      border: AppColors.borderDark,
      divider: AppColors.dividerDark,
      shadow: AppColors.shadowDark,
      overlay: AppColors.overlayDark,
    );
  }
}
