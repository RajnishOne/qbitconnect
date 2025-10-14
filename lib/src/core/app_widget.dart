import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';
import '../state/app_state_manager.dart';
import '../state/batch_selection_state.dart';
import '../theme/theme_cache.dart';
import '../utils/animation_manager.dart';
import '../services/deep_link_handler.dart';
import 'root_router.dart';

/// Main app widget that handles the overall app structure and lifecycle
class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> with WidgetsBindingObserver {
  late AppState appState;
  final DeepLinkHandler _deepLinkHandler = DeepLinkHandler();
  Uri? _pendingDeepLink;
  int _deepLinkRetryCount = 0;
  static const int _maxDeepLinkRetries = 20; // 10 seconds max (20 * 500ms)

  @override
  void initState() {
    super.initState();
    appState = AppState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDeepLinkHandler();
    AppWidgetAccess.setAppWidgetState(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up all animations when the app is disposed
    AnimationManager.disposeAll();
    _deepLinkHandler.dispose();
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

  /// Initialize deep link handler
  void _initializeDeepLinkHandler() {
    _deepLinkHandler.initialize().catchError((error) {
      // Silently handle error to avoid blocking UI
    });

    // Listen to deep link events
    _deepLinkHandler.linkStream.listen((Uri uri) {
      // Handle deep links when the app is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleDeepLink(uri);
        }
      });
    });
  }

  /// Handle incoming deep links
  void _handleDeepLink(Uri uri) {
    // Only handle torrent-related links
    if (_deepLinkHandler.isTorrentRelated(uri)) {
      _pendingDeepLink = uri;
      _processPendingDeepLink();
    }
  }

  /// Process pending deep link when app is ready
  void _processPendingDeepLink() {
    if (_pendingDeepLink == null) return;

    // Check retry limit
    if (_deepLinkRetryCount >= _maxDeepLinkRetries) {
      _pendingDeepLink = null;
      _deepLinkRetryCount = 0;
      return;
    }

    // Check if app state is ready (not initializing)
    if (!appState.isInitializing) {
      // Don't process here, just store it for the main screen to handle
      // The main screen will check for pending deep links when it's ready
      return;
    } else {
      _deepLinkRetryCount++;
      // App still initializing, try again later
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _processPendingDeepLink();
        }
      });
    }
  }

  /// Get the pending deep link (called by main screen)
  Uri? getPendingDeepLink() {
    final link = _pendingDeepLink;
    if (link != null) {
      _pendingDeepLink = null;
      _deepLinkRetryCount = 0;
    }
    return link;
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
          // Process pending deep link when app state changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _processPendingDeepLink();
            }
          });

          return MaterialApp(
            title: LocaleKeys.appName.tr(),
            theme: ThemeCache.lightTheme,
            darkTheme: ThemeCache.darkTheme,
            themeMode: _getThemeMode(appState),
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            home: const RootRouter(),
          );
        },
      ),
    );
  }
}

/// Global access to AppWidget for deep link handling and language updates
class AppWidgetAccess {
  static _AppWidgetState? _appWidgetState;

  static void setAppWidgetState(_AppWidgetState state) {
    _appWidgetState = state;
  }

  static Uri? getPendingDeepLink() {
    return _appWidgetState?.getPendingDeepLink();
  }

  /// Convenience getter for accessing the app widget state
  static _AppWidgetState? get appWidgetState => _appWidgetState;
}
