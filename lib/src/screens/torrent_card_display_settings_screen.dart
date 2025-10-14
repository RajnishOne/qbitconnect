import 'dart:io';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';
import '../models/torrent_card_display_options.dart';
import '../services/display_options_cache.dart';

class TorrentCardDisplaySettingsScreen extends StatefulWidget {
  const TorrentCardDisplaySettingsScreen({super.key});

  @override
  State<TorrentCardDisplaySettingsScreen> createState() =>
      _TorrentCardDisplaySettingsScreenState();
}

class _TorrentCardDisplaySettingsScreenState
    extends State<TorrentCardDisplaySettingsScreen> {
  List<TorrentCardDisplayOption> _selectedOptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Use cached options if available, otherwise load them
    if (DisplayOptionsCache.isCached) {
      _selectedOptions = List.from(DisplayOptionsCache.getCachedOptions());
      _isLoading = false;
      if (mounted) setState(() {});
    } else {
      await DisplayOptionsCache.loadOptions();
      if (mounted) {
        setState(() {
          _selectedOptions = List.from(DisplayOptionsCache.getCachedOptions());
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    await DisplayOptionsCache.updateOptions(_selectedOptions);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedOptions.removeAt(oldIndex);
      _selectedOptions.insert(newIndex, item);
    });
    _saveSettings();
  }

  void _toggleOption(TorrentCardDisplayOption option) {
    setState(() {
      if (_selectedOptions.contains(option)) {
        _selectedOptions.remove(option);
      } else {
        // Check if we can add more options (max 4)
        if (_selectedOptions.length < TorrentCardDisplayOption.maxSelections) {
          _selectedOptions.add(option);
        } else {
          // Show a snackbar if trying to exceed max selections
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocaleKeys.maximumOptionsCanBeSelected.tr(
                  namedArgs: {
                    'max': TorrentCardDisplayOption.maxSelections.toString(),
                  },
                ),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
    _saveSettings();
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
        appBar: AppBar(
          title: Text(LocaleKeys.torrentCardDisplay.tr()),
          actions: [
            if (_selectedOptions.length <
                TorrentCardDisplayOption.maxSelections)
              TextButton(
                onPressed: () {
                  // Reset to default options
                  setState(() {
                    _selectedOptions = List.from(
                      TorrentCardDisplayOption.defaultOptions,
                    );
                  });
                  _saveSettings();
                },
                child: Text(LocaleKeys.reset.tr()),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            LocaleKeys.customizeTorrentCardInfo.tr(),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LocaleKeys.selectUpToOptionsToDisplay.tr(
                        namedArgs: {
                          'max': TorrentCardDisplayOption.maxSelections
                              .toString(),
                          'current': _selectedOptions.length.toString(),
                        },
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Preview section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.preview.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _buildPreviewText(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Options list
            Card(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.checklist,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          LocaleKeys.availableOptions.tr(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedOptions.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final option = _selectedOptions[index];
                      return _OptionTile(
                        key: ValueKey(option),
                        option: option,
                        isSelected: true,
                        canSelect: true,
                        onToggle: () => _toggleOption(option),
                        isReorderable: true,
                      );
                    },
                  ),
                  // Show unselected options
                  ...TorrentCardDisplayOption.allOptions
                      .where((option) => !_selectedOptions.contains(option))
                      .map((option) {
                        return _OptionTile(
                          key: ValueKey(option),
                          option: option,
                          isSelected: false,
                          canSelect:
                              _selectedOptions.length <
                              TorrentCardDisplayOption.maxSelections,
                          onToggle: () => _toggleOption(option),
                          isReorderable: false,
                        );
                      }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildPreviewText() {
    if (_selectedOptions.isEmpty) {
      return LocaleKeys.noOptionsSelected.tr();
    }

    final List<String> previewParts = [];

    for (final option in _selectedOptions) {
      switch (option) {
        case TorrentCardDisplayOption.percentage:
          previewParts.add('85.2%');
          break;
        case TorrentCardDisplayOption.size:
          previewParts.add('Size 2.1 GB');
          break;
        case TorrentCardDisplayOption.downloadSpeed:
          previewParts.add('DL 1.2 MB/s');
          break;
        case TorrentCardDisplayOption.uploadSpeed:
          previewParts.add('UL 256 KB/s');
          break;
        case TorrentCardDisplayOption.ratio:
          previewParts.add('Ratio 0.85');
          break;
        case TorrentCardDisplayOption.eta:
          previewParts.add('ETA 2h 15m');
          break;
        case TorrentCardDisplayOption.seeds:
          previewParts.add('Seeds 45');
          break;
        case TorrentCardDisplayOption.leeches:
          previewParts.add('Leeches 12');
          break;
        case TorrentCardDisplayOption.uploaded:
          previewParts.add('Uploaded 1.8 GB');
          break;
        case TorrentCardDisplayOption.downloaded:
          previewParts.add('Downloaded 2.1 GB');
          break;
      }
    }

    return previewParts.join(' • ');
  }
}

/// Optimized option tile widget to reduce rebuilds
class _OptionTile extends StatelessWidget {
  final TorrentCardDisplayOption option;
  final bool isSelected;
  final bool canSelect;
  final VoidCallback onToggle;
  final bool isReorderable;

  const _OptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.canSelect,
    required this.onToggle,
    this.isReorderable = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: isSelected,
        onChanged: canSelect ? (_) => onToggle() : null,
      ),
      title: Text(option.displayName),
      subtitle: Text(_getOptionDescription(option)),
      trailing: isReorderable
          ? Icon(
              Icons.drag_handle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onToggle,
    );
  }

  String _getOptionDescription(TorrentCardDisplayOption option) {
    switch (option) {
      case TorrentCardDisplayOption.percentage:
        return LocaleKeys.showsDownloadProgressPercentage.tr();
      case TorrentCardDisplayOption.size:
        return LocaleKeys.showsTotalTorrentSize.tr();
      case TorrentCardDisplayOption.downloadSpeed:
        return LocaleKeys.showsCurrentDownloadSpeed.tr();
      case TorrentCardDisplayOption.uploadSpeed:
        return LocaleKeys.showsCurrentUploadSpeed.tr();
      case TorrentCardDisplayOption.ratio:
        return LocaleKeys.showsUploadDownloadRatio.tr();
      case TorrentCardDisplayOption.eta:
        return LocaleKeys.showsEstimatedTimeToCompletion.tr();
      case TorrentCardDisplayOption.seeds:
        return LocaleKeys.showsNumberOfSeeders.tr();
      case TorrentCardDisplayOption.leeches:
        return LocaleKeys.showsNumberOfLeechers.tr();
      case TorrentCardDisplayOption.uploaded:
        return LocaleKeys.showsTotalUploadedData.tr();
      case TorrentCardDisplayOption.downloaded:
        return LocaleKeys.showsTotalDownloadedData.tr();
    }
  }
}
