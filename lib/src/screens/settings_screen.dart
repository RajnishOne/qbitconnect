import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../state/app_state_manager.dart';
import '../services/prefs.dart';
import '../services/firebase_service.dart';
import '../utils/app_info.dart';
import '../utils/byte_formatter.dart';
import 'package:network_ninja/network_ninja.dart';
import 'theme_selection_screen.dart';
import 'statistics_screen.dart';
import 'webview_screen.dart';
import 'torrent_card_display_settings_screen.dart';

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

  // Store historical speed data (last 60 data points)
  final List<double> _downloadSpeedHistory = [];
  final List<double> _uploadSpeedHistory = [];
  final int _maxDataPoints = 60;

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

  void _updateSpeedHistory(int dlSpeed, int upSpeed) {
    if (!mounted) return;

    setState(() {
      _downloadSpeedHistory.add(dlSpeed.toDouble());
      _uploadSpeedHistory.add(upSpeed.toDouble());

      // Keep only last N data points
      if (_downloadSpeedHistory.length > _maxDataPoints) {
        _downloadSpeedHistory.removeAt(0);
      }
      if (_uploadSpeedHistory.length > _maxDataPoints) {
        _uploadSpeedHistory.removeAt(0);
      }
    });
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
      parameters: {'polling_enabled': value},
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
          title: const Text('Settings'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                tooltip: "Disconnect",
                onPressed: () => _showDisconnectDialog(context),
                icon: Icon(
                  Icons.power_settings_new_rounded,
                  color: Colors.orange,
                ),
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
                // Update speed history when transfer info changes
                if (appState.transferInfo != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateSpeedHistory(
                      appState.transferInfo!.dlInfoSpeed,
                      appState.transferInfo!.upInfoSpeed,
                    );
                  });
                }

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
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Speed Over Time Graph
            if (_downloadSpeedHistory.length > 1) _buildSpeedGraph(),

            const SizedBox(height: 16),

            // Statistics Section
            Card(
              child: ListTile(
                title: const Text('Statistics'),
                subtitle: const Text('View detailed torrent statistics'),
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
                title: const Text('Torrent Card Display'),
                subtitle: const Text('Customize torrent card'),
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
                title: const Text('Theme'),
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
                    title: const Text('All Torrents'),
                    subtitle: const Text('Show all torrents by default'),
                    leading: ValueListenableBuilder<String>(
                      valueListenable: _statusFilterNotifier,
                      builder: (context, value, child) {
                        return _buildCustomRadio('all', value);
                      },
                    ),
                    onTap: () => _setStatusFilter('all'),
                  ),
                  ListTile(
                    title: const Text('Downloading'),
                    subtitle: const Text('Show only downloading torrents'),
                    leading: ValueListenableBuilder<String>(
                      valueListenable: _statusFilterNotifier,
                      builder: (context, value, child) {
                        return _buildCustomRadio('downloading', value);
                      },
                    ),
                    onTap: () => _setStatusFilter('downloading'),
                  ),
                  ListTile(
                    title: const Text('Completed'),
                    subtitle: const Text('Show only completed torrents'),
                    leading: ValueListenableBuilder<String>(
                      valueListenable: _statusFilterNotifier,
                      builder: (context, value, child) {
                        return _buildCustomRadio('completed', value);
                      },
                    ),
                    onTap: () => _setStatusFilter('completed'),
                  ),
                  ListTile(
                    title: const Text('Seeding'),
                    subtitle: const Text('Show only seeding torrents'),
                    leading: ValueListenableBuilder<String>(
                      valueListenable: _statusFilterNotifier,
                      builder: (context, value, child) {
                        return _buildCustomRadio('seeding', value);
                      },
                    ),
                    onTap: () => _setStatusFilter('seeding'),
                  ),
                  ListTile(
                    title: const Text('Paused'),
                    subtitle: const Text('Show only paused torrents'),
                    leading: ValueListenableBuilder<String>(
                      valueListenable: _statusFilterNotifier,
                      builder: (context, value, child) {
                        return _buildCustomRadio('paused', value);
                      },
                    ),
                    onTap: () => _setStatusFilter('paused'),
                  ),
                  ListTile(
                    title: const Text('Active'),
                    subtitle: const Text('Show only active torrents'),
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
                    title: const Text('Enable Auto-Refresh'),
                    subtitle: const Text('Automatically refresh torrent list'),
                    value: _pollingEnabled,
                    onChanged: _togglePolling,
                    secondary: const Icon(Icons.sync),
                  ),
                  if (_pollingEnabled) ...[
                    ListTile(
                      title: const Text('Refresh Interval'),
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
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Read our privacy policy'),
                    leading: const Icon(Icons.privacy_tip_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openPrivacyPolicy,
                  ),
                  ListTile(
                    title: const Text('Terms & Conditions'),
                    subtitle: const Text('Read our terms and conditions'),
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
                title: const Text('Logs'),
                leading: const Icon(Icons.network_check_rounded),
                trailing: const Icon(Icons.chevron_right),
                onTap: context.showNetworkLogs,
              ),
            ),

            const SizedBox(height: 16),

            // About Section
            Card(
              child: ListTile(
                title: const Text('Version'),
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

  void _showDisconnectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Disconnect'),
          content: const Text(
            'Are you sure you want to disconnect from the qBittorrent server?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Disconnect'),
              onPressed: () {
                context.read<AppState>().disconnect();
                Navigator.of(context).pop(); // Dismiss Dialog
                Navigator.of(context).pop(); // Go to torrent screen
              },
            ),
          ],
        );
      },
    );
  }

  // Compact speed visualization
  Widget _buildSpeedGraph() {
    final dlMax = _downloadSpeedHistory.isEmpty
        ? 1.0
        : _downloadSpeedHistory.reduce((a, b) => a > b ? a : b);
    final upMax = _uploadSpeedHistory.isEmpty
        ? 1.0
        : _uploadSpeedHistory.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Download Speed with Mini Sparkline
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.download,
                        color: Color(0xFF2196F3),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Download',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _downloadSpeedHistory.isEmpty
                        ? '0 B/s'
                        : ByteFormatter.formatBytesPerSecond(
                            _downloadSpeedHistory.last.toInt(),
                          ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  if (_downloadSpeedHistory.length > 1) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: (_downloadSpeedHistory.length - 1).toDouble(),
                          minY: 0,
                          maxY: dlMax * 1.2,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _downloadSpeedHistory
                                  .asMap()
                                  .entries
                                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                                  .toList(),
                              isCurved: true,
                              color: const Color(0xFF2196F3),
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2196F3).withOpacity(0.3),
                                    const Color(0xFF2196F3).withOpacity(0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: const LineTouchData(enabled: false),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 1,
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            // Upload Speed with Mini Sparkline
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.upload,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Upload',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _uploadSpeedHistory.isEmpty
                        ? '0 B/s'
                        : ByteFormatter.formatBytesPerSecond(
                            _uploadSpeedHistory.last.toInt(),
                          ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  if (_uploadSpeedHistory.length > 1) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: (_uploadSpeedHistory.length - 1).toDouble(),
                          minY: 0,
                          maxY: upMax * 1.2,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _uploadSpeedHistory
                                  .asMap()
                                  .entries
                                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                                  .toList(),
                              isCurved: true,
                              color: const Color(0xFF4CAF50),
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF4CAF50).withOpacity(0.3),
                                    const Color(0xFF4CAF50).withOpacity(0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: const LineTouchData(enabled: false),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
