import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/batch_selection_state.dart';
import '../models/torrent.dart';
import '../services/firebase_service.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/add_torrent_fab.dart';
import '../widgets/animated_reload_button.dart';
import '../widgets/animated_reload_elevated_button.dart';
import '../widgets/torrent_card_with_selection.dart';
import '../widgets/torrent_actions_sheet.dart';
import '../widgets/batch_actions_bar.dart';
import 'torrent_details_screen.dart';
import 'settings_screen.dart';

class TorrentsScreen extends StatefulWidget {
  const TorrentsScreen({super.key});

  @override
  State<TorrentsScreen> createState() => _TorrentsScreenState();
}

class _TorrentsScreenState extends State<TorrentsScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Log screen view
    FirebaseService.instance.logScreenView(
      screenName: 'torrents_screen',
      screenClass: 'TorrentsScreen',
    );
    _initializeBatchSelection();
  }

  void _initializeBatchSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final batchState = context.read<BatchSelectionState>();
      final appState = context.read<AppState>();

      batchState.initialize(
        currentFilter: appState.activeFilter,
        currentCategory: appState.activeCategory,
        currentSearchQuery: _searchQuery,
        getFilteredHashesCallback: () =>
            _getFilteredTorrents(appState).map((t) => t.hash).toList(),
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        bottom: Platform.isAndroid,
        top: false,
        child: Scaffold(
          drawer: Drawer(
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const ListTile(
                    title: Text(
                      'Transfer Info',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Row(
                    children: (appState.transferInfo != null)
                        ? [
                            const SizedBox(width: 16),
                            Chip(
                              avatar: Icon(Icons.download, color: Colors.green),
                              label: Text(
                                '${_formatBytes(appState.transferInfo!.dlInfoSpeed)}/s',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Chip(
                              avatar: Icon(Icons.upload, color: Colors.red),
                              label: Text(
                                '${_formatBytes(appState.transferInfo!.upInfoSpeed)}/s',
                              ),
                            ),
                          ]
                        : [],
                  ),

                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Disconnect'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.read<AppState>().disconnect();
                    },
                  ),
                ],
              ),
            ),
          ),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    appState.serverName?.isNotEmpty == true
                        ? appState.serverName!
                        : 'qBitConnect',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                if (appState.qbittorrentVersion != null)
                  Text(
                    appState.qbittorrentVersion!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            actions: [
              Consumer<BatchSelectionState>(
                builder: (context, batchState, child) {
                  // Don't show any action buttons when torrent list is empty
                  if (_getFilteredTorrents(appState).isEmpty) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedReloadButton(
                          onPressed: () =>
                              context.read<AppState>().refreshNow(),
                          tooltip: 'Refresh torrents',
                          iconSize: 22,
                        ),
                      ],
                    );
                  }

                  if (batchState.isSelectionMode) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => batchState.selectAll(),
                          icon: const Icon(Icons.select_all),
                          tooltip: 'Select All',
                          iconSize: 20,
                        ),
                        IconButton(
                          onPressed: () => batchState.clearSelection(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Cancel',
                          iconSize: 20,
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedReloadButton(
                          onPressed: () =>
                              context.read<AppState>().refreshNow(),
                          tooltip: 'Refresh torrents',
                          iconSize: 22,
                        ),
                        IconButton(
                          onPressed: () => batchState.enterSelectionMode(),
                          icon: const Icon(Icons.check_box_outlined),
                          tooltip: 'Select torrents',
                          iconSize: 22,
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
          floatingActionButton: const AddTorrentFab(),
          bottomNavigationBar: const BatchActionsBar(),
          body: RefreshIndicator(
            onRefresh: () => context.read<AppState>().refreshNow(),
            child: Column(
              children: [
                // Search and Filter Bar - Only show when torrents exist
                if (_getFilteredTorrents(appState).isNotEmpty)
                  SearchFilterBar(
                    searchController: _searchController,
                    searchQuery: _searchQuery,
                    onSearchChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    onClearSearch: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                // Torrents List
                Expanded(
                  child: _getFilteredTorrents(appState).isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (appState.isRefreshing &&
                                  !appState.hasLoadedOnce) ...[
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading torrents...',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ] else ...[
                                Icon(
                                  _searchQuery.isNotEmpty
                                      ? Icons.search_off
                                      : Icons.download,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No torrents match your search'
                                      : 'No torrents found',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                // Show reload button only when no search is active and API returned empty
                                if (_searchQuery.isEmpty &&
                                    appState.hasLoadedOnce) ...[
                                  const SizedBox(height: 24),
                                  AnimatedReloadElevatedButton(
                                    onPressed: () =>
                                        context.read<AppState>().refreshNow(),
                                    label: 'Reload',
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 120),
                          controller: _scrollController,
                          itemCount: _getFilteredTorrents(appState).length,
                          itemBuilder: (context, index) {
                            final torrent = _getFilteredTorrents(
                              appState,
                            )[index];
                            return TorrentCardWithSelection(
                              torrent: torrent,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TorrentDetailsScreen(torrent: torrent),
                                  ),
                                );
                              },
                              onLongPress: () =>
                                  _showTorrentActions(context, torrent),
                              onSelectionToggle: () {
                                // Update batch selection state when selection changes
                                final batchState = context
                                    .read<BatchSelectionState>();
                                batchState.updateFilterState(
                                  filter: appState.activeFilter,
                                  category: appState.activeCategory,
                                  searchQuery: _searchQuery,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Torrent> _getFilteredTorrents(AppState appState) {
    if (_searchQuery.isEmpty) {
      return appState.torrents;
    }

    return appState.torrents.where((torrent) {
      return torrent.name.toLowerCase().contains(_searchQuery) ||
          torrent.displayCategory.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _showTorrentActions(BuildContext context, Torrent torrent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      builder: (context) => TorrentActionsSheet(torrent: torrent),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    if (bytes < 0) return '0 B'; // Handle negative values
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    int unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    if (value.isNaN || value.isInfinite) return '0 B';
    return '${value.toStringAsFixed(value >= 10 || value.floorToDouble() == value ? 0 : 1)} ${units[unitIndex]}';
  }
}
