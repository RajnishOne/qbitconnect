import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/torrent_add_options.dart';

class AddTorrentFileScreen extends StatefulWidget {
  const AddTorrentFileScreen({super.key});

  @override
  State<AddTorrentFileScreen> createState() => _AddTorrentFileScreenState();
}

class _AddTorrentFileScreenState extends State<AddTorrentFileScreen> {
  final TextEditingController _savePathController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _downloadLimitController =
      TextEditingController();
  final TextEditingController _uploadLimitController = TextEditingController();

  String _torrentManagementMode = 'Manual';
  String _stopCondition = 'None';
  String _contentLayout = 'Original';

  bool _startTorrent = true;
  bool _addToTopOfQueue = false;
  bool _skipHashCheck = false;
  bool _sequentialDownload = false;
  bool _firstLastPiecePriority = false;
  bool _isLoading = false;

  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
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
        _torrentManagementMode = mostUsedTmm ? 'Automatic' : 'Manual';
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        bottom: true,
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
              child: const Text('Add Torrent'),
            ),
          ),
          appBar: AppBar(
            title: const Text('Add Torrent from File'),
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
                        const Text(
                          'Torrent File',
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
                                  _selectedFile?.name ?? 'No file chosen',
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
                              label: const Text('Choose File'),
                            ),
                          ],
                        ),
                        if (_selectedFile != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'File size: ${_formatFileSize(_selectedFile!.size)}',
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
                        const Text(
                          'Torrent Options',
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
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
                'Torrent Management Mode:',
                _torrentManagementMode,
                ['Manual', 'Automatic'],
                (value) => setState(() => _torrentManagementMode = value!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextOption(
                'Save files to location:',
                _savePathController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 2
        Row(
          children: [
            Expanded(
              child: _buildTextOption('Rename torrent:', _nameController),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownOption(
                'Category:',
                _categoryController.text.isEmpty
                    ? 'None'
                    : _categoryController.text,
                [
                  'None',
                  ...context.read<AppState>().allCategories.where(
                    (category) => category != 'Uncategorized',
                  ),
                ],
                (value) => setState(
                  () =>
                      _categoryController.text = value == 'None' ? '' : value!,
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
                'Start torrent',
                _startTorrent,
                (value) => setState(() => _startTorrent = value!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCheckboxOption(
                'Add to top of queue',
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
                'Stop condition:',
                _stopCondition,
                ['None', 'Metadata received', 'Files checked'],
                (value) => setState(() => _stopCondition = value!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCheckboxOption(
                'Skip hash check',
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
                'Content layout:',
                _contentLayout,
                ['Original', 'Create subfolder', 'Don\'t create subfolder'],
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
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid torrent file')),
      );
      return;
    }

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
        stopCondition: _stopCondition == 'None' ? null : _stopCondition,
        skipHashCheck: _skipHashCheck,
        contentLayout: _contentLayout == 'Original' ? null : _contentLayout,
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
        bytes: _selectedFile!.bytes!,
        options: options,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Torrent added successfully'),
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
