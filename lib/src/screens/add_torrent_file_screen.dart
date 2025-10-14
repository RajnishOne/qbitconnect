import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';
import '../state/app_state_manager.dart';
import '../models/torrent_add_options.dart';
import '../services/firebase_service.dart';

class AddTorrentFileScreen extends StatefulWidget {
  final String? filePath;

  const AddTorrentFileScreen({super.key, this.filePath});

  @override
  State<AddTorrentFileScreen> createState() => _AddTorrentFileScreenState();
}

class _AddTorrentFileScreenState extends State<AddTorrentFileScreen>
    with AutomaticKeepAliveClientMixin {
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

  PlatformFile? _selectedFile;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Log screen view
    FirebaseService.instance.logScreenView(
      screenName: 'add_torrent_file_screen',
      screenClass: 'AddTorrentFileScreen',
    );
    _initializeDefaults();

    // Handle prefilled file path if provided
    if (widget.filePath != null) {
      _handlePrefilledFile(widget.filePath!);
    }
  }

  void _initializeDefaults() {
    _initializeDefaultSavePath();
    _initializeDefaultOptions();
  }

  void _handlePrefilledFile(String filePath) {
    // Handle different types of file paths
    if (filePath.startsWith('content://')) {
      // For content URIs, we need to handle them specially
      // Extract filename from the URI or use a default name
      final uri = Uri.parse(filePath);
      final fileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'torrent_file.torrent';

      _selectedFile = PlatformFile(
        path: filePath,
        name: fileName,
        size: 0, // We can't get size for content URIs without reading the file
        bytes: null, // Will be loaded when needed
      );

      // Show a message that the file is pre-selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleKeys.torrentFilePreselected.tr()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    } else {
      // For regular file paths, use the standard File approach
      final file = File(filePath);
      if (file.existsSync()) {
        _selectedFile = PlatformFile(
          path: filePath,
          name: file.path.split('/').last,
          size: file.lengthSync(),
        );
      }
    }
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
              onPressed: (_selectedFile != null && !_isLoading)
                  ? _addTorrent
                  : null,
              child: Text(LocaleKeys.addTorrent.tr()),
            ),
          ),
          appBar: AppBar(
            title: Text(LocaleKeys.addTorrentFile.tr()),
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
                // File Selection Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleKeys.torrentFile.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _selectedFile?.name ??
                                      LocaleKeys.pleaseSelectFile.tr(),
                                  style: TextStyle(
                                    color: _selectedFile != null
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _pickFile,
                              icon: const Icon(Icons.upload_file),
                              label: Text(LocaleKeys.select.tr()),
                            ),
                          ],
                        ),
                        if (_selectedFile != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${LocaleKeys.fileSize.tr()}: ${_formatFileSize(_selectedFile!.size)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['torrent'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
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
                      .toSet()
                      .toList(),
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
                'Download in sequential order',
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
                'Download first and last pieces first',
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
                'Limit download rate:',
                _downloadLimitController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRateLimitOption(
                'Limit upload rate:',
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
        const SizedBox(height: 8),
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
            const Text(
              'Save files to location:',
              style: TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
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
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.pleaseSelectValidTorrentFile.tr())),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get file bytes based on the file type
      List<int> fileBytes;

      if (_selectedFile!.path?.startsWith('content://') == true) {
        // For content URIs, we need to use a different approach
        // The file_picker plugin can handle content URIs when used properly
        // We'll use the file picker to get the file data
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['torrent'],
          withData: true,
        );

        if (result == null ||
            result.files.isEmpty ||
            result.files.first.bytes == null) {
          throw Exception(LocaleKeys.failedToReadTorrentFile.tr());
        }

        fileBytes = result.files.first.bytes!;
        // Update the selected file with the new data
        _selectedFile = result.files.first;
      } else {
        // For regular files, use the bytes from the selected file
        if (_selectedFile!.bytes == null) {
          // If bytes are not available, read from file path
          final file = File(_selectedFile!.path!);
          fileBytes = await file.readAsBytes();
        } else {
          fileBytes = _selectedFile!.bytes!;
        }
      }

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

      await context.read<AppState>().addTorrentFromFile(
        fileName: _selectedFile!.name,
        bytes: fileBytes,
        options: options,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Torrent added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding torrent: $e'),
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
