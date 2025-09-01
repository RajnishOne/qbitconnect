import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Theme variant with custom color schemes
class AppThemeVariant {
  final String name;
  final String displayName;
  final String description;
  final AppColorScheme Function({required bool isDarkMode}) colorSchemeBuilder;

  const AppThemeVariant({
    required this.name,
    required this.displayName,
    required this.description,
    required this.colorSchemeBuilder,
  });

  /// Get theme data for this variant
  ThemeData getThemeData({required bool isDarkMode}) {
    final colorScheme = colorSchemeBuilder(isDarkMode: isDarkMode);
    return _buildThemeData(colorScheme, isDarkMode);
  }

  /// Get color scheme for this variant
  AppColorScheme getColorScheme({required bool isDarkMode}) {
    return colorSchemeBuilder(isDarkMode: isDarkMode);
  }

  /// Build theme data from color scheme
  ThemeData _buildThemeData(AppColorScheme colorScheme, bool isDarkMode) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,

      // Color scheme
      colorScheme: ColorScheme(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: colorScheme.primary,
        onPrimary: isDarkMode ? Colors.black : Colors.white,
        secondary: colorScheme.secondary,
        onSecondary: isDarkMode ? Colors.black : Colors.white,
        error: colorScheme.error,
        onError: isDarkMode ? Colors.black : Colors.white,
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
          foregroundColor: isDarkMode ? Colors.black : Colors.white,
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
          foregroundColor: isDarkMode ? Colors.black : Colors.white,
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
        foregroundColor: isDarkMode ? Colors.black : Colors.white,
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
        checkColor: WidgetStateProperty.all(
          isDarkMode ? Colors.black : Colors.white,
        ),
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

  // Theme variants
  static const AppThemeVariant light = AppThemeVariant(
    name: 'light',
    displayName: 'Light',
    description: 'Clean and bright light theme',
    colorSchemeBuilder: _lightColorScheme,
  );

  static const AppThemeVariant dark = AppThemeVariant(
    name: 'dark',
    displayName: 'Dark',
    description: 'Comfortable dark theme with good contrast',
    colorSchemeBuilder: _darkColorScheme,
  );

  static const AppThemeVariant oled = AppThemeVariant(
    name: 'oled',
    displayName: 'OLED',
    description: 'True black theme for OLED displays',
    colorSchemeBuilder: _oledColorScheme,
  );
}

// Color scheme builders for each theme variant
AppColorScheme _lightColorScheme({required bool isDarkMode}) {
  return const AppColorScheme(
    primary: Color(0xFF1976D2), // Blue
    secondary: Color(0xFF00ACC1), // Cyan
    background: Color(0xFFFAFAFA), // Light gray background
    surface: Color(0xFFFFFFFF), // White surface
    textPrimary: Color(0xFF212121), // Dark gray text
    textSecondary: Color(0xFF757575), // Medium gray text
    textHint: Color(0xFF9E9E9E), // Light gray hint
    success: Color(0xFF4CAF50), // Green
    warning: Color(0xFFFF9800), // Orange
    error: Color(0xFFF44336), // Red
    info: Color(0xFF00ACC1), // Cyan
    downloading: Color(0xFF4CAF50), // Green
    seeding: Color(0xFF00ACC1), // Cyan
    paused: Color(0xFFFF9800), // Orange
    completed: Color(0xFF9C27B0), // Purple
    errored: Color(0xFFF44336), // Red
    stalled: Color(0xFF9E9E9E), // Gray
    downloadSpeed: Color(0xFF4CAF50), // Green
    uploadSpeed: Color(0xFF00ACC1), // Cyan
    border: Color(0xFFE0E0E0), // Light gray border
    divider: Color(0xFFE0E0E0), // Light gray divider
    shadow: Color(0x1A000000), // Black shadow
    overlay: Color(0x80000000), // Black overlay
  );
}

AppColorScheme _darkColorScheme({required bool isDarkMode}) {
  return const AppColorScheme(
    primary: Color(0xFF5C7CFA), // Muted purple-blue for dark theme
    secondary: Color(0xFF748FFC), // Softer blue for dark theme
    background: Color(0xFF121212), // Dark gray background
    surface: Color(0xFF1E1E1E), // Darker gray surface
    textPrimary: Color(0xFFE0E0E0), // Light gray text
    textSecondary: Color(0xFFB0B0B0), // Medium light gray text
    textHint: Color(0xFF808080), // Medium gray hint
    success: Color(0xFF81C784), // Light green
    warning: Color(0xFFFFB74D), // Light orange
    error: Color(0xFFE57373), // Light red
    info: Color(0xFF748FFC), // Muted blue info color for dark theme
    downloading: Color(0xFF81C784), // Light green
    seeding: Color(0xFF748FFC), // Muted blue seeding color for dark theme
    paused: Color(0xFFFFB74D), // Light orange
    completed: Color(0xFFBA68C8), // Light purple
    errored: Color(0xFFE57373), // Light red
    stalled: Color(0xFFB0B0B0), // Light gray
    downloadSpeed: Color(0xFF81C784), // Light green
    uploadSpeed: Color(
      0xFF748FFC,
    ), // Muted blue upload speed color for dark theme
    border: Color(0xFF424242), // Dark gray border
    divider: Color(0xFF424242), // Dark gray divider
    shadow: Color(0x1AFFFFFF), // White shadow
    overlay: Color(0x80FFFFFF), // White overlay
  );
}

AppColorScheme _oledColorScheme({required bool isDarkMode}) {
  return const AppColorScheme(
    primary: Color(0xFF6C7CE7), // Softer purple-blue for OLED theme
    secondary: Color(0xFF91A7FF), // Light muted blue for OLED theme
    background: Color(0xFF000000), // Pure black background
    surface: Color(0xFF0A0A0A), // Very dark gray surface
    textPrimary: Color(0xFFE0E0E0), // Light gray text
    textSecondary: Color(0xFFB0B0B0), // Medium light gray text
    textHint: Color(0xFF808080), // Medium gray hint
    success: Color(0xFF81C784), // Light green
    warning: Color(0xFFFFB74D), // Light orange
    error: Color(0xFFE57373), // Light red
    info: Color(0xFF91A7FF), // Muted blue info color for OLED theme
    downloading: Color(0xFF81C784), // Light green
    seeding: Color(0xFF91A7FF), // Muted blue seeding color for OLED theme
    paused: Color(0xFFFFB74D), // Light orange
    completed: Color(0xFFBA68C8), // Light purple
    errored: Color(0xFFE57373), // Light red
    stalled: Color(0xFFB0B0B0), // Light gray
    downloadSpeed: Color(0xFF81C784), // Light green
    uploadSpeed: Color(
      0xFF91A7FF,
    ), // Muted blue upload speed color for OLED theme
    border: Color(0xFF1A1A1A), // Very dark gray border
    divider: Color(0xFF1A1A1A), // Very dark gray divider
    shadow: Color(0x1AFFFFFF), // White shadow
    overlay: Color(0x80FFFFFF), // White overlay
  );
}
