import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Helper class to easily access theme colors and text styles
class ThemeHelper {
  /// Get the current color scheme based on context
  static AppColorScheme getColors(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AppColors.getScheme(brightness);
  }

  /// Get text styles with colors applied based on context
  static AppTextStylesWithColors getTextStyles(BuildContext context) {
    final colors = getColors(context);
    return AppTextStylesWithColors(colors);
  }

  /// Get torrent status color based on state
  static Color getTorrentStatusColor(BuildContext context, String state) {
    final colors = getColors(context);
    final stateLower = state.toLowerCase();

    if (stateLower.contains('downloading') || stateLower.contains('down')) {
      return colors.downloading;
    } else if (stateLower.contains('uploading') ||
        stateLower.contains('seeding') ||
        stateLower.contains('seed')) {
      return colors.seeding;
    } else if (stateLower.contains('paused') ||
        stateLower.contains('stopped')) {
      return colors.paused;
    } else if (stateLower.contains('completed') ||
        stateLower.contains('finished')) {
      return colors.completed;
    } else if (stateLower.contains('error') || stateLower.contains('failed')) {
      return colors.errored;
    } else if (stateLower.contains('stalled')) {
      return colors.stalled;
    } else {
      return colors.textSecondary;
    }
  }

  /// Get transfer speed color
  static Color getSpeedColor(BuildContext context, bool isDownload) {
    final colors = getColors(context);
    return isDownload ? colors.downloadSpeed : colors.uploadSpeed;
  }
}

/// Text styles with colors applied
class AppTextStylesWithColors {
  final AppColorScheme colors;

  const AppTextStylesWithColors(this.colors);

  // Display styles
  TextStyle get displayLarge =>
      AppTextStyles.displayLarge.copyWith(color: colors.textPrimary);
  TextStyle get displayMedium =>
      AppTextStyles.displayMedium.copyWith(color: colors.textPrimary);
  TextStyle get displaySmall =>
      AppTextStyles.displaySmall.copyWith(color: colors.textPrimary);

  // Headline styles
  TextStyle get headlineLarge =>
      AppTextStyles.headlineLarge.copyWith(color: colors.textPrimary);
  TextStyle get headlineMedium =>
      AppTextStyles.headlineMedium.copyWith(color: colors.textPrimary);
  TextStyle get headlineSmall =>
      AppTextStyles.headlineSmall.copyWith(color: colors.textPrimary);

  // Title styles
  TextStyle get titleLarge =>
      AppTextStyles.titleLarge.copyWith(color: colors.textPrimary);
  TextStyle get titleMedium =>
      AppTextStyles.titleMedium.copyWith(color: colors.textPrimary);
  TextStyle get titleSmall =>
      AppTextStyles.titleSmall.copyWith(color: colors.textPrimary);

  // Body styles
  TextStyle get bodyLarge =>
      AppTextStyles.bodyLarge.copyWith(color: colors.textPrimary);
  TextStyle get bodyMedium =>
      AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary);
  TextStyle get bodySmall =>
      AppTextStyles.bodySmall.copyWith(color: colors.textSecondary);

  // Label styles
  TextStyle get labelLarge =>
      AppTextStyles.labelLarge.copyWith(color: colors.textPrimary);
  TextStyle get labelMedium =>
      AppTextStyles.labelMedium.copyWith(color: colors.textSecondary);
  TextStyle get labelSmall =>
      AppTextStyles.labelSmall.copyWith(color: colors.textSecondary);

  // Custom app-specific styles
  TextStyle get appTitle =>
      AppTextStyles.appTitle.copyWith(color: colors.textPrimary);
  TextStyle get cardTitle =>
      AppTextStyles.cardTitle.copyWith(color: colors.textPrimary);
  TextStyle get cardSubtitle =>
      AppTextStyles.cardSubtitle.copyWith(color: colors.textSecondary);
  TextStyle get statusText =>
      AppTextStyles.statusText.copyWith(color: colors.textSecondary);
  TextStyle get speedText =>
      AppTextStyles.speedText.copyWith(color: colors.textSecondary);
  TextStyle get infoText =>
      AppTextStyles.infoText.copyWith(color: colors.textSecondary);
  TextStyle get buttonText =>
      AppTextStyles.buttonText.copyWith(color: colors.textPrimary);
  TextStyle get inputText =>
      AppTextStyles.inputText.copyWith(color: colors.textPrimary);
  TextStyle get hintText =>
      AppTextStyles.hintText.copyWith(color: colors.textHint);
  TextStyle get errorText =>
      AppTextStyles.errorText.copyWith(color: colors.error);
  TextStyle get successText =>
      AppTextStyles.successText.copyWith(color: colors.success);
  TextStyle get warningText =>
      AppTextStyles.warningText.copyWith(color: colors.warning);
  TextStyle get torrentName =>
      AppTextStyles.torrentName.copyWith(color: colors.textPrimary);
  TextStyle get torrentInfo =>
      AppTextStyles.torrentInfo.copyWith(color: colors.textSecondary);
  TextStyle get drawerTitle =>
      AppTextStyles.drawerTitle.copyWith(color: colors.textPrimary);
  TextStyle get drawerItem =>
      AppTextStyles.drawerItem.copyWith(color: colors.textPrimary);
  TextStyle get chipText =>
      AppTextStyles.chipText.copyWith(color: colors.textPrimary);
  TextStyle get progressText =>
      AppTextStyles.progressText.copyWith(color: colors.textPrimary);
  TextStyle get percentageText =>
      AppTextStyles.percentageText.copyWith(color: colors.textPrimary);
  TextStyle get fileSizeText =>
      AppTextStyles.fileSizeText.copyWith(color: colors.textSecondary);
  TextStyle get peerInfoText =>
      AppTextStyles.peerInfoText.copyWith(color: colors.textSecondary);
  TextStyle get trackerText =>
      AppTextStyles.trackerText.copyWith(color: colors.textSecondary);
  TextStyle get detailsLabel =>
      AppTextStyles.detailsLabel.copyWith(color: colors.textPrimary);
  TextStyle get detailsValue =>
      AppTextStyles.detailsValue.copyWith(color: colors.textSecondary);
}
