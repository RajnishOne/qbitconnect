import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/state/app_state.dart';
import 'src/state/batch_selection_state.dart';
import 'src/screens/connection_screen.dart';
import 'src/screens/torrents_screen.dart';
import 'src/theme/app_theme.dart';
import 'src/utils/app_info.dart';
import 'src/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase in background to avoid blocking UI
  FirebaseService.instance.initialize().catchError((e) {
    print('Firebase initialization failed: $e');
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AppState appState;

  @override
  void initState() {
    super.initState();
    appState = AppState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize app info in background
    AppInfo.initialize().catchError((e) {
      print('App info initialization failed: $e');
    });

    // Log app open event
    FirebaseService.instance.logAppOpen().catchError((e) {
      print('Analytics app open logging failed: $e');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider(create: (_) => BatchSelectionState()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'qBitConnect',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const _RootRouter(),
          );
        },
      ),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().loadAndAutoConnect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.isInitializing) {
      return const _SplashScreen();
    }
    if (!appState.isAuthenticated) {
      return const ConnectionScreen();
    }
    return const TorrentsScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon or logo
            Icon(
              Icons.cloud_download,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'qBitConnect',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Remote Server Management',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.3,
              child: const LinearProgressIndicator(),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
