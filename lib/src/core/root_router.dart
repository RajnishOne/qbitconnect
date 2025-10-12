import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state_manager.dart';
import '../screens/connection_screen.dart';
import '../screens/torrents_screen.dart';
import '../screens/server_list_screen.dart';
import '../services/server_storage.dart';
import '../models/server_config.dart';
import 'splash_screen.dart';

/// Handles the root routing logic for the app
class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  List<ServerConfig>? _servers;

  @override
  void initState() {
    super.initState();
    _loadServers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().loadAndAutoConnect();
    });
  }

  Future<void> _loadServers() async {
    final servers = await ServerStorage.loadServerConfigs();
    if (mounted) {
      setState(() {
        _servers = servers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.isInitializing) {
      return const SplashScreen();
    }

    if (!appState.isAuthenticated) {
      // If auto-connect failed and we have servers, show server list
      if (appState.autoConnectFailed &&
          _servers != null &&
          _servers!.isNotEmpty) {
        return const ServerListScreen();
      }

      // Otherwise show connection screen (first launch or no servers)
      return const ConnectionScreen();
    }

    return const TorrentsScreen();
  }
}
