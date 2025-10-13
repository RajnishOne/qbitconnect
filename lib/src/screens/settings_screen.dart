import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';
import '../state/app_state_manager.dart';
import '../services/prefs.dart';
import '../services/firebase_service.dart';
import '../utils/app_info.dart';
import '../utils/byte_formatter.dart';
import 'package:network_ninja/network_ninja.dart';
import 'theme_selection_screen.dart';
import 'statistics_screen.dart';
import 'language_selection_screen.dart';
import 'webview_screen.dart';
import 'torrent_card_display_settings_screen.dart';
import 'server_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<String> _statusFilterNotifier = ValueNotifier<String>(
    'all',
  );
  bool _pollingEnabled = true;
  int _pollingInterval = 4;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Log screen view
    FirebaseService.instance.logScreenView(
      screenName: 'settings_screen',
      screenClass: 'SettingsScreen',
    );
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final statusFilter = await Prefs.loadStatusFilter();
    final pollingEnabled = await Prefs.loadPollingEnabled();
    final pollingInterval = await Prefs.loadPollingInterval();

    if (mounted) {
      setState(() {
        _pollingEnabled = pollingEnabled;
        _pollingInterval = pollingInterval;
        _isLoading = false;
      });
      _statusFilterNotifier.value = statusFilter;
    }
  }

  Future<void> _setStatusFilter(String filter) async {
    _statusFilterNotifier.value = filter;

    await Prefs.saveStatusFilter(filter);

    // Update the app filter
    if (mounted) {
      context.read<AppState>().setFilter(filter);
    }
  }

  Future<void> _togglePolling(bool value) async {
    setState(() {
      _pollingEnabled = value;
    });

    await Prefs.savePollingEnabled(value);

    // Log polling setting change
    FirebaseService.instance.logEvent(
      name: 'polling_setting_changed',
      parameters: {'polling_enabled': value ? 'yes' : 'no'},
    );

    // Update the app polling setting
    if (mounted) {
      context.read<AppState>().setPollingEnabled(value);
    }
  }

  Future<void> _setPollingInterval(int seconds) async {
    setState(() {
      _pollingInterval = seconds;
    });

    await Prefs.savePollingInterval(seconds);

    // Update the app polling interval
    if (mounted) {
      context.read<AppState>().setPollingInterval(seconds);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const WebViewScreen(
            title: 'Privacy Policy',
            url: 'https://sites.google.com/view/qbitconnecttnc/privacy-policy',
          ),
        ),
      );
    }
  }

  Future<void> _openTermsAndConditions() async {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const WebViewScreen(
            title: 'Terms & Conditions',
            url:
                'https://sites.google.com/view/qbitconnecttnc/terms-conditions',
          ),
        ),
      );
    }
  }

  String _getIntervalDisplayText(int seconds) {
    if (seconds < 60) {
      return 'Every $seconds seconds';
    } else if (seconds == 60) {
      return 'Every 1 minute';
    } else {
      return 'Every 15 minutes';
    }
  }

  Widget _buildCustomRadio(String value, String? selectedValue) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => _setStatusFilter(value),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 12,
                color: Theme.of(context).colorScheme.onPrimary,
              )
            : null,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      bottom: Platform.isAndroid,
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleKeys.settings.tr()),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageSelectionScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.language),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Server Info Section
            Consumer<AppState>(
              builder: (context, appState, child) {
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (appState.serverName != null) ...[
                              _buildInfoRow(
                                'Server Name',
                                appState.serverName!,
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (appState.qbittorrentVersion != null) ...[
                              _buildInfoRow(
                                'Version',
                                appState.qbittorrentVersion!,
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (appState.baseUrl != null) ...[
                              _buildInfoRow(
                                'Connection URL',
                                appState.baseUrl!,
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (appState.transferInfo != null) ...[
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              const Text(
                                'Transfer Speeds',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Chip(
                                    avatar: const Icon(
                                      Icons.download,
                                      color: Colors.green,
                                    ),
                                    label: Text(
                                      ByteFormatter.formatBytesPerSecond(
                                        appState.transferInfo!.dlInfoSpeed,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    avatar: const Icon(
                                      Icons.upload,
                                      color: Colors.red,
                                    ),
                                    label: Text(
                                      ByteFormatter.formatBytesPerSecond(
                                        appState.transferInfo!.upInfoSpeed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Servers Section
            Card(
              child: ListTile(
                title: Text(LocaleKeys.servers.tr()),
                subtitle: Text(LocaleKeys.manageServers.tr()),
                leading: const Icon(Icons.dns),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServerListScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Statistics Section
            Card(
              child: ListTile(
                title: Text(LocaleKeys.statistics.tr()),
                subtitle: Text(LocaleKeys.analytics.tr()),
                leading: const Icon(Icons.analytics),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatisticsScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Torrent Card Display Section
            Card(
              child: ListTile(
                title: Text(LocaleKeys.torrentCardDisplay.tr()),
                subtitle: Text(LocaleKeys.customizeTorrentCard.tr()),
                leading: const Icon(Icons.view_list),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const TorrentCardDisplaySettingsScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Theme Section
            Card(
              child: ListTile(
                title: Text(LocaleKeys.theme.tr()),
                subtitle: Text(
                  context.watch<AppState>().currentTheme.displayName,
                ),
                leading: const Icon(Icons.palette),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThemeSelectionScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Status Filter Section
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list),
                        SizedBox(width: 12),
                        Text(
                          'Default Status Filter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: Text(LocaleKeys.allTorrents.tr()),
                    subtitle: Text(LocaleKeys.showAllTorrents.tr()),
                    leading: ValueListenableBuilder<String>(
                      valueListenable: _statusFilterNotifier,
                      builder: (context, value, child) {
                        return _buildCustomRadio('all', value);
                      },
                    ),
                    onTap: () => _setStatusFilter('all'),
                  ),
                  ListTile(
                    title: Text(LocaleKeys.downloading.tr()),
                    subtitle: Text(LocaleKeys.showOnlyDownloading.tr()),
                    leading: ValueListenableBuilder<String>(
                      valueListenable: _statusFilterNotifier,
                      builder: (context, value, child) {
                        return _buildCustomRadio('downloading', value);
                      },
                    ),
                    onTap: () => _setStatusFilter('downloading'),
                  ),
                  ListTile(
                    title: Text(LocaleKeys.completed.tr()),
                    subtitle: Text(LocaleKeys.showOnlyCompleted.tr()),
                    leading: ValueListenableBuilder<String>(
                      valueListenable: _statusFilterNotifier,
                      builder: (context, value, child) {
                        return _buildCustomRadio('completed', value);
                      },
                    ),
                    onTap: () => _setStatusFilter('completed'),
                  ),
                  ListTile(
                    title: Text(LocaleKeys.seeding.tr()),
                    subtitle: Text(LocaleKeys.showOnlySeeding.tr()),
                    leading: ValueListenableBuilder<String>(
                      valueListenable: _statusFilterNotifier,
                      builder: (context, value, child) {
                        return _buildCustomRadio('seeding', value);
                      },
                    ),
                    onTap: () => _setStatusFilter('seeding'),
                  ),
                  ListTile(
                    title: Text(LocaleKeys.paused.tr()),
                    subtitle: Text(LocaleKeys.showOnlyPaused.tr()),
                    leading: ValueListenableBuilder<String>(
                      valueListenable: _statusFilterNotifier,
                      builder: (context, value, child) {
                        return _buildCustomRadio('paused', value);
                      },
                    ),
                    onTap: () => _setStatusFilter('paused'),
                  ),
                  ListTile(
                    title: Text(LocaleKeys.active.tr()),
                    subtitle: Text(LocaleKeys.showOnlyActive.tr()),
                    leading: ValueListenableBuilder<String>(
                      valueListenable: _statusFilterNotifier,
                      builder: (context, value, child) {
                        return _buildCustomRadio('active', value);
                      },
                    ),
                    onTap: () => _setStatusFilter('active'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Polling Settings Section
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.sync),
                        SizedBox(width: 12),
                        Text(
                          'Auto-Refresh Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    title: Text(LocaleKeys.enableAutoRefresh.tr()),
                    subtitle: Text(
                      LocaleKeys.automaticallyRefreshTorrentList.tr(),
                    ),
                    value: _pollingEnabled,
                    onChanged: _togglePolling,
                    secondary: const Icon(Icons.sync),
                  ),
                  if (_pollingEnabled) ...[
                    ListTile(
                      title: Text(LocaleKeys.refreshInterval.tr()),
                      subtitle: Text(_getIntervalDisplayText(_pollingInterval)),
                      leading: const Icon(Icons.timer),
                      trailing: DropdownButton<int>(
                        value: _pollingInterval,
                        items: [2, 4, 6, 8, 10, 15, 60, 900].map((seconds) {
                          String displayText;
                          if (seconds < 60) {
                            displayText = '${seconds}s';
                          } else if (seconds == 60) {
                            displayText = '1m';
                          } else {
                            displayText = '15m';
                          }
                          return DropdownMenuItem<int>(
                            value: seconds,
                            child: Text(displayText),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _setPollingInterval(value);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Legal Section
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(LocaleKeys.privacyPolicy.tr()),
                    subtitle: Text(LocaleKeys.readOurPrivacyPolicy.tr()),
                    leading: const Icon(Icons.privacy_tip_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openPrivacyPolicy,
                  ),
                  ListTile(
                    title: Text(LocaleKeys.termsConditions.tr()),
                    subtitle: Text(LocaleKeys.readOurTermsAndConditions.tr()),
                    leading: const Icon(Icons.description_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openTermsAndConditions,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: ListTile(
                title: Text(LocaleKeys.logs.tr()),
                leading: const Icon(Icons.network_check_rounded),
                trailing: const Icon(Icons.chevron_right),
                onTap: context.showNetworkLogs,
              ),
            ),

            const SizedBox(height: 16),

            // About Section
            Card(
              child: ListTile(
                title: Text(LocaleKeys.version.tr()),
                trailing: Text(AppInfo.version),
                leading: const Icon(Icons.app_settings_alt),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
