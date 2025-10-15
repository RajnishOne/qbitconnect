import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';
import '../state/app_state_manager.dart';
import '../models/torrent_add_options.dart';
import '../services/firebase_service.dart';

class AddTorrentUrlScreen extends StatefulWidget {
  final String? prefilledUrl;

  const AddTorrentUrlScreen({super.key, this.prefilledUrl});

  @override
  State<AddTorrentUrlScreen> createState() => _AddTorrentUrlScreenState();
}

class _AddTorrentUrlScreenState extends State<AddTorrentUrlScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _savePathController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _downloadLimitController =
      TextEditingController();
  final TextEditingController _uploadLimitController = TextEditingController();

  String _torrentManagementMode = LocaleKeys.manual.tr();
  String _stopCondition = LocaleKeys.none.tr();
  String _contentLayout = LocaleKeys.original.tr();

  bool _startTorrent = true;
  bool _addToTopOfQueue = false;
  bool _skipHashCheck = false;
  bool _sequentialDownload = false;
  bool _firstLastPiecePriority = false;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Log screen view
    FirebaseService.instance.logScreenView(
      screenName: 'add_torrent_url_screen',
      screenClass: 'AddTorrentUrlScreen',
    );
    _initializeDefaults();

    // Pre-fill URL if provided
    if (widget.prefilledUrl != null) {
      _urlController.text = widget.prefilledUrl!;
    }
  }

  void _initializeDefaults() {
    _initializeDefaultSavePath();
    _initializeDefaultOptions();
  }

  void _initializeDefaultOptions() {
    final appState = context.read<AppState>();
    if (appState.torrents.isNotEmpty) {
      // Get the most commonly used options from existing torrents
      final torrentManagementCounts = <bool, int>{};
      final sequentialCounts = <bool, int>{};
      final firstLastPieceCounts = <bool, int>{};

      for (final torrent in appState.torrents) {
        // Count torrent management mode (autoTmm)
        torrentManagementCounts[torrent.autoTmm] =
            (torrentManagementCounts[torrent.autoTmm] ?? 0) + 1;

        // Count sequential download
        sequentialCounts[torrent.isSequential] =
            (sequentialCounts[torrent.isSequential] ?? 0) + 1;

        // Count first/last piece priority
        firstLastPieceCounts[torrent.isFirstLastPiecePriority] =
            (firstLastPieceCounts[torrent.isFirstLastPiecePriority] ?? 0) + 1;
      }

      // Set torrent management mode based on most common
      if (torrentManagementCounts.isNotEmpty) {
        final mostUsedTmm = torrentManagementCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        _torrentManagementMode = mostUsedTmm
            ? LocaleKeys.automatic.tr()
            : LocaleKeys.manual.tr();
      }

      // Set sequential download based on most common
      if (sequentialCounts.isNotEmpty) {
        final mostUsedSequential = sequentialCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        _sequentialDownload = mostUsedSequential;
      }

      // Set first/last piece priority based on most common
      if (firstLastPieceCounts.isNotEmpty) {
        final mostUsedFirstLast = firstLastPieceCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        _firstLastPiecePriority = mostUsedFirstLast;
      }
    }
  }

  void _initializeDefaultSavePath() {
    final appState = context.read<AppState>();
    if (appState.torrents.isNotEmpty) {
      // Get the most commonly used save path from existing torrents
      final savePathCounts = <String, int>{};
      for (final torrent in appState.torrents) {
        if (torrent.savePath.isNotEmpty) {
          savePathCounts[torrent.savePath] =
              (savePathCounts[torrent.savePath] ?? 0) + 1;
        }
      }

      if (savePathCounts.isNotEmpty) {
        final mostUsedPath = savePathCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        _savePathController.text = mostUsedPath;
        return;
      }
    }

    // Fallback to a reasonable default
    _savePathController.text = '/downloads';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _savePathController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _downloadLimitController.dispose();
    _uploadLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        bottom: Platform.isAndroid,
        top: false,
        child: Scaffold(
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: Platform.isIOS ? 24 : 16,
              top: 16,
            ),
            child: FilledButton(
              onPressed: _isLoading ? null : _addTorrent,
              child: Text(LocaleKeys.addTorrent.tr()),
            ),
          ),
          appBar: AppBar(
            title: Text(LocaleKeys.addTorrentUrl.tr()),
            actions: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // URL Input Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleKeys.urls.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _urlController,
                          maxLines: 6,
                          textAlign: TextAlign.start,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                            hintText: LocaleKeys.enterMagnetLinksHttpUrls.tr(),
                            labelText: LocaleKeys.torrentUrls.tr(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LocaleKeys.oneLinkPerLineSupported.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Torrent Options Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleKeys.torrentOptions.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionsGrid(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsGrid() {
    return Column(
      children: [
        // Row 1
        Row(
          children: [
            Expanded(
              child: _buildDropdownOption(
                LocaleKeys.torrentManagementMode.tr(),
                _torrentManagementMode,
                [LocaleKeys.manual.tr(), LocaleKeys.automatic.tr()],
                (value) => setState(() => _torrentManagementMode = value!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildSavePathAutocomplete()),
          ],
        ),
        const SizedBox(height: 16),

        // Row 2
        Row(
          children: [
            Expanded(
              child: _buildTextOption(
                LocaleKeys.renameTorrent.tr(),
                _nameController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownOption(
                LocaleKeys.category.tr(),
                _categoryController.text.isEmpty
                    ? LocaleKeys.none.tr()
                    : _categoryController.text,
                [
                  LocaleKeys.none.tr(),
                  ...context
                      .read<AppState>()
                      .allCategories
                      .where(
                        (category) =>
                            category != LocaleKeys.uncategorized.tr() &&
                            category != LocaleKeys.none.tr(),
                      )
                      .toSet(),
                ],
                (value) => setState(
                  () => _categoryController.text = value == LocaleKeys.none.tr()
                      ? ''
                      : value!,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 3
        Row(
          children: [
            Expanded(
              child: _buildCheckboxOption(
                LocaleKeys.startTorrent.tr(),
                _startTorrent,
                (value) => setState(() => _startTorrent = value!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCheckboxOption(
                LocaleKeys.addToTopOfQueue.tr(),
                _addToTopOfQueue,
                (value) => setState(() => _addToTopOfQueue = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 4
        Row(
          children: [
            Expanded(
              child: _buildDropdownOption(
                LocaleKeys.stopCondition.tr(),
                _stopCondition,
                [
                  LocaleKeys.none.tr(),
                  LocaleKeys.metadataReceived.tr(),
                  LocaleKeys.filesChecked.tr(),
                ],
                (value) => setState(() => _stopCondition = value!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCheckboxOption(
                LocaleKeys.skipHashCheck.tr(),
                _skipHashCheck,
                (value) => setState(() => _skipHashCheck = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 5
        Row(
          children: [
            Expanded(
              child: _buildDropdownOption(
                LocaleKeys.contentLayout.tr(),
                _contentLayout,
                [
                  LocaleKeys.original.tr(),
                  LocaleKeys.createSubfolder.tr(),
                  LocaleKeys.dontCreateSubfolder.tr(),
                ],
                (value) => setState(() => _contentLayout = value!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCheckboxOption(
                LocaleKeys.downloadInSequentialOrder.tr(),
                _sequentialDownload,
                (value) => setState(() => _sequentialDownload = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 6
        Row(
          children: [
            Expanded(
              child: _buildCheckboxOption(
                LocaleKeys.downloadFirstAndLastPiecesFirst.tr(),
                _firstLastPiecePriority,
                (value) => setState(() => _firstLastPiecePriority = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 7 - Rate Limits
        Row(
          children: [
            Expanded(
              child: _buildRateLimitOption(
                LocaleKeys.limitDownloadRateHint.tr(),
                _downloadLimitController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRateLimitOption(
                LocaleKeys.limitUploadRateHint.tr(),
                _uploadLimitController,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownOption(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildTextOption(
    String label,
    TextEditingController controller, {
    bool hasDropdown = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            suffixIcon: hasDropdown ? const Icon(Icons.arrow_drop_down) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSavePathAutocomplete() {
    return FutureBuilder<List<String>>(
      future: context.read<AppState>().getAllDirectories(),
      builder: (context, snapshot) {
        final availableDirectories = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.saveFilesToLocationHint.tr(),
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _savePathController.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return availableDirectories;
                }
                return availableDirectories.where((String option) {
                  return option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
                });
              },
              onSelected: (String selection) {
                _savePathController.text = selection;
              },
              fieldViewBuilder:
                  (
                    BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    // Sync the autocomplete controller with our main controller
                    textEditingController.text = _savePathController.text;
                    textEditingController.addListener(() {
                      _savePathController.text = textEditingController.text;
                    });

                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: LocaleKeys.typeOrSelectDirectory.tr(),
                      ),
                    );
                  },
              optionsViewBuilder:
                  (
                    BuildContext context,
                    AutocompleteOnSelected<String> onSelected,
                    Iterable<String> options,
                  ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 150,
                            maxWidth: 400,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    option,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCheckboxOption(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildRateLimitOption(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixText: 'KiB/s',
          ),
        ),
      ],
    );
  }

  Future<void> _addTorrent() async {
    final urls = _urlController.text.trim();
    if (urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.pleaseEnterAtLeastOneUrl.tr())),
      );
      return;
    }

    // Store context before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final options = TorrentAddOptions(
        savePath: _savePathController.text.trim().isEmpty
            ? null
            : _savePathController.text.trim(),
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        startTorrent: _startTorrent,
        addToTopOfQueue: _addToTopOfQueue,
        stopCondition: _stopCondition == LocaleKeys.none.tr()
            ? null
            : _stopCondition,
        skipHashCheck: _skipHashCheck,
        contentLayout: _contentLayout == LocaleKeys.original.tr()
            ? null
            : _contentLayout,
        sequentialDownload: _sequentialDownload,
        firstLastPiecePriority: _firstLastPiecePriority,
        downloadLimit: _downloadLimitController.text.trim().isEmpty
            ? null
            : int.tryParse(_downloadLimitController.text.trim()),
        uploadLimit: _uploadLimitController.text.trim().isEmpty
            ? null
            : int.tryParse(_uploadLimitController.text.trim()),
        torrentManagementMode: _torrentManagementMode,
      );

      // Split URLs and add each one
      final urlList = urls.split('\n').where((url) => url.trim().isNotEmpty);
      int addedCount = 0;

      for (final url in urlList) {
        try {
          await context.read<AppState>().addTorrentFromUrl(
            url: url.trim(),
            options: options,
          );
          addedCount++;
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                '${LocaleKeys.failedToAddTorrent.tr()}: ${url.trim()}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if (addedCount > 0) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              '${LocaleKeys.successfullyAddedTorrents.tr()} $addedCount',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${LocaleKeys.errorAddingTorrent.tr()}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
