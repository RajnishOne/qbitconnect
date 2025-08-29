import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/theme_manager.dart';
import '../theme/theme_variants.dart';
import '../services/firebase_service.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Log screen view
    FirebaseService.instance.logScreenView(
      screenName: 'theme_selection_screen',
      screenClass: 'ThemeSelectionScreen',
    );
  }

  /// Determine if a theme should use dark mode
  bool _isThemeDark(AppThemeVariant theme) {
    switch (theme.name) {
      case 'light':
        return false;
      case 'dark':
      case 'oled':
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentTheme = appState.currentTheme;

    // Determine if we should use dark mode based on the current theme
    final isDarkMode = _isThemeDark(currentTheme);

    // Get the current theme data directly from the theme manager
    final currentThemeData = currentTheme.getThemeData(isDarkMode: isDarkMode);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Theme')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ThemeManager.availableThemes.length,
        itemBuilder: (context, index) {
          final theme = ThemeManager.availableThemes[index];
          final isSelected = currentTheme.name == theme.name;
          final previewColors = ThemeManager.getThemePreviewColors(
            theme,
            isDarkMode: _isThemeDark(theme),
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isSelected ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? BorderSide(
                      color: currentThemeData.colorScheme.primary,
                      width: 2,
                    )
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () => _selectTheme(theme),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ThemeManager.getThemeDisplayName(theme),
                                style: currentThemeData.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ThemeManager.getThemeDescription(theme),
                                style: currentThemeData.textTheme.bodyMedium
                                    ?.copyWith(
                                      color: currentThemeData
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: currentThemeData.colorScheme.primary,
                            size: 24,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Theme preview
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: previewColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Primary color indicator
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: previewColors[0].withValues(alpha: 0.8),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.palette,
                                  color:
                                      previewColors[0].computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // Secondary color indicator
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: previewColors[1].withValues(alpha: 0.8),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.ac_unit,
                                  color:
                                      previewColors[1].computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          // Surface color indicator
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: previewColors[2].withValues(alpha: 0.8),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.circle,
                                  color:
                                      previewColors[2].computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                          // Background color indicator
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: previewColors[3].withValues(alpha: 0.8),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.radio_button_unchecked,
                                  color:
                                      previewColors[3].computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectTheme(AppThemeVariant theme) async {
    // Update the app theme
    await context.read<AppState>().setTheme(theme);

    // Force rebuild of this screen to reflect theme changes immediately
    if (mounted) {
      setState(() {});
    }

    // Log theme change
    FirebaseService.instance.logEvent(
      name: 'theme_changed',
      parameters: {
        'theme_name': theme.name,
        'theme_display_name': theme.displayName,
      },
    );

    // Show a brief feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme changed to ${theme.displayName}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
