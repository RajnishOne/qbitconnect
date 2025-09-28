import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Complete app theme configuration
class AppTheme {
  /// Light theme
  static ThemeData get lightTheme {
    final colorScheme = AppColorScheme.light();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: colorScheme.primary,
        onPrimary: Colors.white,
        secondary: colorScheme.secondary,
        onSecondary: Colors.white,
        error: colorScheme.error,
        onError: Colors.white,
        surface: colorScheme.surface,
        onSurface: colorScheme.textPrimary,
        surfaceContainerHighest: colorScheme.surface,
        onSurfaceVariant: colorScheme.textSecondary,
        outline: colorScheme.border,
        outlineVariant: colorScheme.divider,
        shadow: colorScheme.shadow,
        scrim: colorScheme.overlay,
        inverseSurface: colorScheme.background,
        onInverseSurface: colorScheme.textPrimary,
        inversePrimary: colorScheme.primary,
        surfaceTint: colorScheme.primary,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        iconTheme: IconThemeData(color: colorScheme.textPrimary),
        surfaceTintColor: Colors.transparent,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: colorScheme.textPrimary,
        ),
        displaySmall: AppTextStyles.displaySmall.copyWith(
          color: colorScheme.textPrimary,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: colorScheme.textPrimary,
        ),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(
          color: colorScheme.textPrimary,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: colorScheme.textPrimary,
        ),
        titleSmall: AppTextStyles.titleSmall.copyWith(
          color: colorScheme.textPrimary,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.textPrimary,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: colorScheme.textSecondary,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: colorScheme.textSecondary,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: colorScheme.textSecondary,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: AppTextStyles.labelLarge.copyWith(
          color: colorScheme.textSecondary,
        ),
        hintStyle: AppTextStyles.hintText.copyWith(color: colorScheme.textHint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: AppTextStyles.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(color: colorScheme.textPrimary, size: 24),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary.withValues(alpha: 0.1),
        disabledColor: colorScheme.surface,
        labelStyle: AppTextStyles.chipText.copyWith(
          color: colorScheme.textPrimary,
        ),
        secondaryLabelStyle: AppTextStyles.chipText.copyWith(
          color: colorScheme.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.divider,
        thickness: 1,
        space: 1,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppTextStyles.bodyLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        subtitleTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.textSecondary,
        ),
        leadingAndTrailingTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.textSecondary,
        ),
        iconColor: colorScheme.textSecondary,
        textColor: colorScheme.textPrimary,
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.border,
        circularTrackColor: colorScheme.border,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          return colorScheme.border;
        }),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.textSecondary;
        }),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: colorScheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),

      // Drawer theme
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
      ),

      // Navigation drawer theme
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.1),
        tileHeight: 56,
        labelTextStyle: WidgetStateProperty.all(
          AppTextStyles.bodyMedium.copyWith(color: colorScheme.textPrimary),
        ),
      ),

      // Scaffold background color
      scaffoldBackgroundColor: colorScheme.background,
    );
  }

  /// Dark theme
  static ThemeData get darkTheme {
    final colorScheme = AppColorScheme.dark();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: colorScheme.primary,
        onPrimary: Colors.black,
        secondary: colorScheme.secondary,
        onSecondary: Colors.black,
        error: colorScheme.error,
        onError: Colors.black,
        surface: colorScheme.surface,
        onSurface: colorScheme.textPrimary,
        surfaceContainerHighest: colorScheme.surface,
        onSurfaceVariant: colorScheme.textSecondary,
        outline: colorScheme.border,
        outlineVariant: colorScheme.divider,
        shadow: colorScheme.shadow,
        scrim: colorScheme.overlay,
        inverseSurface: colorScheme.background,
        onInverseSurface: colorScheme.textPrimary,
        inversePrimary: colorScheme.primary,
        surfaceTint: colorScheme.primary,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        iconTheme: IconThemeData(color: colorScheme.textPrimary),
        surfaceTintColor: Colors.transparent,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: colorScheme.textPrimary,
        ),
        displaySmall: AppTextStyles.displaySmall.copyWith(
          color: colorScheme.textPrimary,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: colorScheme.textPrimary,
        ),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(
          color: colorScheme.textPrimary,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: colorScheme.textPrimary,
        ),
        titleSmall: AppTextStyles.titleSmall.copyWith(
          color: colorScheme.textPrimary,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.textPrimary,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: colorScheme.textSecondary,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: colorScheme.textSecondary,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: colorScheme.textSecondary,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: AppTextStyles.labelLarge.copyWith(
          color: colorScheme.textSecondary,
        ),
        hintStyle: AppTextStyles.hintText.copyWith(color: colorScheme.textHint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.black,
          textStyle: AppTextStyles.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 2,
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: AppTextStyles.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.black,
          textStyle: AppTextStyles.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(color: colorScheme.textPrimary, size: 24),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.black,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary.withValues(alpha: 0.1),
        disabledColor: colorScheme.surface,
        labelStyle: AppTextStyles.chipText.copyWith(
          color: colorScheme.textPrimary,
        ),
        secondaryLabelStyle: AppTextStyles.chipText.copyWith(
          color: colorScheme.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.divider,
        thickness: 1,
        space: 1,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppTextStyles.bodyLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        subtitleTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.textSecondary,
        ),
        leadingAndTrailingTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.textSecondary,
        ),
        iconColor: colorScheme.textSecondary,
        textColor: colorScheme.textPrimary,
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.border,
        circularTrackColor: colorScheme.border,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          return colorScheme.border;
        }),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.textSecondary;
        }),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: BorderSide(color: colorScheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: colorScheme.textPrimary,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),

      // Drawer theme
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
      ),

      // Navigation drawer theme
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.1),
        tileHeight: 56,
        labelTextStyle: WidgetStateProperty.all(
          AppTextStyles.bodyMedium.copyWith(color: colorScheme.textPrimary),
        ),
      ),

      // Scaffold background color
      scaffoldBackgroundColor: colorScheme.background,
    );
  }
}
