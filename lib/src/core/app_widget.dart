import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_strings.dart';
import '../state/app_state_manager.dart';
import '../state/batch_selection_state.dart';
import '../theme/theme_cache.dart';
import '../utils/animation_manager.dart';
import 'root_router.dart';

/// Main app widget that handles the overall app structure and lifecycle
class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> with WidgetsBindingObserver {
  late AppState appState;

  @override
  void initState() {
    super.initState();
    appState = AppState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up all animations when the app is disposed
    AnimationManager.disposeAll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // Handle async onAppResumed without awaiting to avoid blocking the UI
        appState.onAppResumed().catchError((error) {
          // Silently handle error to avoid blocking UI
        });
        break;
      case AppLifecycleState.paused:
        appState.onAppPaused();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        appState.onAppPaused();
        break;
      case AppLifecycleState.inactive:
        // Don't change polling for inactive state (like when pulling down notification panel)
        break;
    }
  }

  /// Determine theme mode based on current theme variant
  ThemeMode _getThemeMode(AppState appState) {
    // Use ThemeCache for consistent theme mode determination
    return ThemeCache.getThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider(create: (_) => BatchSelectionState()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          // Use cached themes directly - no more nested FutureBuilders!
          return MaterialApp(
            title: AppStrings.appName,
            theme: ThemeCache.lightTheme,
            darkTheme: ThemeCache.darkTheme,
            themeMode: _getThemeMode(appState),
            home: const RootRouter(),
          );
        },
      ),
    );
  }
}
