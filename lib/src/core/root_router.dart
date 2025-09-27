import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state_manager.dart';
import '../screens/connection_screen.dart';
import '../screens/torrents_screen.dart';
import 'splash_screen.dart';

/// Handles the root routing logic for the app
class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
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
      return const SplashScreen();
    }

    if (!appState.isAuthenticated) {
      return const ConnectionScreen();
    }

    return const TorrentsScreen();
  }
}
