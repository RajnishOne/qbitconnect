import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';

import '../state/app_state_manager.dart';
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
import '../widgets/reusable_widgets.dart';
import '../services/deep_link_handler.dart';
import '../core/app_widget.dart';
import 'torrent_details_screen.dart';
import 'settings_screen.dart';
import 'server_list_screen.dart';
import '../widgets/server_switcher_sheet.dart';

class TorrentsScreen extends StatefulWidget {
  const TorrentsScreen({super.key});

  @override
  State<TorrentsScreen> createState() => _TorrentsScreenState();
}

class _TorrentsScreenState extends State<TorrentsScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  /// Formats filter names for display in the UI
  String _formatFilterName(String filter) {
    switch (filter) {
      case 'all':
        return 'All';
      case 'downloading':
        return 'Downloading';
      case 'completed':
        return 'Completed';
      case 'seeding':
        return 'Seeding';
      case 'paused':
        return 'Paused';
      case 'stalled':
        return 'Stalled';
      case 'errored':
        return 'Errored';
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      default:
        return filter;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Log screen view
    FirebaseService.instance.logScreenView(
      screenName: 'torrents_screen',
      screenClass: 'TorrentsScreen',
    );
    _initializeBatchSelection();
    _checkForPendingDeepLink();

    // Unfocus search field when user starts scrolling
    _scrollController.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
      }
    });
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

  void _checkForPendingDeepLink() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check for pending deep links using global access
      final pendingLink = AppWidgetAccess.getPendingDeepLink();
      if (pendingLink != null) {
        // Process the deep link now that we have a proper navigation context
        final deepLinkHandler = DeepLinkHandler();
        deepLinkHandler.handleTorrentLink(pendingLink, context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Check for pending deep links when app comes to foreground
      _checkForPendingDeepLink();
    }
  }

  void _showServerSwitcher(BuildContext context, AppState appState) {
    // Unfocus search field when opening server switcher
    _searchFocusNode.unfocus();

    showModalBottomSheet(
      context: context,
      builder: (context) => ServerSwitcherSheet(
        currentServerId: appState.activeServerId,
        onServerSelected: (server) async {
          Navigator.pop(context);
          // Show loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${LocaleKeys.switchingToServer.tr()} ${server.name}...',
              ),
              duration: const Duration(seconds: 1),
            ),
          );
          try {
            await appState.connectToServer(server);
            await appState.refreshNow();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(LocaleKeys.failedToSwitchServer.tr()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onManageServers: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ServerListScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final appState = context.watch<AppState>();

    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: SafeArea(
        bottom: Platform.isAndroid,
        top: false,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () {
                // Unfocus search field when opening settings
                _searchFocusNode.unfocus();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              tooltip: LocaleKeys.settings.tr(),
            ),
            title: GestureDetector(
              onTap: () => _showServerSwitcher(context, appState),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            appState.serverName?.isNotEmpty == true
                                ? appState.serverName!
                                : 'qBitConnect',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 24,
                      ),
                    ],
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
            ),
            actions: [
              Selector<BatchSelectionState, bool>(
                selector: (context, batchState) => batchState.isSelectionMode,
                builder: (context, isSelectionMode, child) {
                  // Don't show any action buttons when torrent list is empty
                  if (_getFilteredTorrents(appState).isEmpty) {
                    return AnimatedReloadButton(
                      onPressed: () => context.read<AppState>().refreshNow(),
                      tooltip: LocaleKeys.refreshTorrents.tr(),
                      iconSize: 22,
                      uniqueId: 'empty_state',
                    );
                  }

                  if (isSelectionMode) {
                    final batchState = context.read<BatchSelectionState>();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReusableWidgets.selectAllButton(batchState.selectAll),
                        ReusableWidgets.cancelButton(batchState.clearSelection),
                      ],
                    );
                  } else {
                    return AnimatedReloadButton(
                      onPressed: () => context.read<AppState>().refreshNow(),
                      tooltip: LocaleKeys.refreshTorrents.tr(),
                      iconSize: 22,
                      uniqueId: 'normal_state',
                    );
                  }
                },
              ),
            ],
          ),
          floatingActionButton: AddTorrentFab(
            searchFocusNode: _searchFocusNode,
          ),
          bottomNavigationBar: const BatchActionsBar(),
          body: RefreshIndicator(
            onRefresh: () => context.read<AppState>().refreshNow(),
            child: Column(
              children: [
                SearchFilterBar(
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
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
                                      ? LocaleKeys.noTorrentsMatchSearch.tr()
                                      : LocaleKeys.noTorrentsFound.tr(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                // Show current filter subtitle when no search is active
                                if (_searchQuery.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${LocaleKeys.currentFilter.tr()}: ${_formatFilterName(appState.activeFilter)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                  ),
                                ],
                                // Show reload button only when no search is active and API returned empty
                                if (_searchQuery.isEmpty &&
                                    appState.hasLoadedOnce) ...[
                                  ReusableWidgets.largeSpacing,
                                  AnimatedReloadElevatedButton(
                                    onPressed: () =>
                                        context.read<AppState>().refreshNow(),
                                    label: LocaleKeys.reload.tr(),
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
                              key: ValueKey(torrent.hash),
                              // Add key for better performance
                              torrent: torrent,
                              onTap: () {
                                // Unfocus search field when tapping on torrent
                                _searchFocusNode.unfocus();
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
                                // No need to update filter state on selection toggle
                                // The selection state is already managed by the toggleSelection method
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
    // Unfocus search field when opening torrent actions
    _searchFocusNode.unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      builder: (context) => TorrentActionsSheet(torrent: torrent),
    );
  }
}
