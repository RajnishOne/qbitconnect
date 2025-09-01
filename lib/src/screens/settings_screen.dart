import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';
import '../services/prefs.dart';
import '../services/firebase_service.dart';
import '../utils/app_info.dart';
import 'package:network_ninja/network_ninja.dart';
import 'theme_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _statusFilter = 'all';
  bool _pollingEnabled = true;
  int _pollingInterval = 4;
  bool _isLoading = true;
  int _versionTapCount = 0;

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
        _statusFilter = statusFilter;
        _pollingEnabled = pollingEnabled;
        _pollingInterval = pollingInterval;
        _isLoading = false;
      });
    }
  }

  Future<void> _setStatusFilter(String filter) async {
    setState(() {
      _statusFilter = filter;
    });

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

  void _onVersionTap() {
    setState(() {
      _versionTapCount++;
    });

    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      _toggleNetworkLogsBubble();
    }
  }

  void _toggleNetworkLogsBubble() {
    // Show the network logs bubble using Network Ninja
    context.showNetworkNinjaBubble();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network logs bubble enabled for this session.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://sites.google.com/view/qbitconnecttnc/privacy-policy';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Privacy Policy'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openTermsAndConditions() async {
    const url = 'https://sites.google.com/view/qbitconnecttnc/terms-conditions';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Terms & Conditions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openGitHubRepository() async {
    const url = 'https://github.com/RajnishOne/qbitconnect';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open GitHub repository'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      bottom: Platform.isAndroid,
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                  RadioListTile<String>(
                    title: const Text('All Torrents'),
                    subtitle: const Text('Show all torrents by default'),
                    value: 'all',
                    groupValue: _statusFilter,
                    onChanged: (value) => _setStatusFilter(value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Downloading'),
                    subtitle: const Text('Show only downloading torrents'),
                    value: 'downloading',
                    groupValue: _statusFilter,
                    onChanged: (value) => _setStatusFilter(value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Completed'),
                    subtitle: const Text('Show only completed torrents'),
                    value: 'completed',
                    groupValue: _statusFilter,
                    onChanged: (value) => _setStatusFilter(value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Seeding'),
                    subtitle: const Text('Show only seeding torrents'),
                    value: 'seeding',
                    groupValue: _statusFilter,
                    onChanged: (value) => _setStatusFilter(value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Paused'),
                    subtitle: const Text('Show only paused torrents'),
                    value: 'paused',
                    groupValue: _statusFilter,
                    onChanged: (value) => _setStatusFilter(value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Active'),
                    subtitle: const Text('Show only active torrents'),
                    value: 'active',
                    groupValue: _statusFilter,
                    onChanged: (value) => _setStatusFilter(value!),
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
                      subtitle: Text('Every $_pollingInterval seconds'),
                      leading: const Icon(Icons.timer),
                      trailing: DropdownButton<int>(
                        value: _pollingInterval,
                        items: [2, 4, 6, 8, 10, 15].map((seconds) {
                          return DropdownMenuItem<int>(
                            value: seconds,
                            child: Text('${seconds}s'),
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
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.gavel),
                        SizedBox(width: 12),
                        Text(
                          'Legal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Read our privacy policy'),
                    leading: const Icon(Icons.privacy_tip_outlined),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: _openPrivacyPolicy,
                  ),
                  ListTile(
                    title: const Text('Terms & Conditions'),
                    subtitle: const Text('Read our terms and conditions'),
                    leading: const Icon(Icons.description_outlined),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: _openTermsAndConditions,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // About Section
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 12),
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('Version'),
                    subtitle: Text(AppInfo.version),
                    leading: const Icon(Icons.app_settings_alt),
                    onTap: _onVersionTap,
                  ),
                  ListTile(
                    title: const Text('Open Source'),
                    subtitle: const Text(
                      'This app is open source under MIT license',
                    ),
                    leading: const Icon(Icons.code),
                  ),
                  ListTile(
                    title: const Text('Contribute'),
                    subtitle: const Text('Open a pull request on GitHub'),
                    leading: const Icon(Icons.fork_right),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: _openGitHubRepository,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
