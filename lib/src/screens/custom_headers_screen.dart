import 'package:flutter/material.dart';

class CustomHeadersScreen extends StatefulWidget {
  final String? initialHeaders;

  const CustomHeadersScreen({super.key, this.initialHeaders});

  @override
  State<CustomHeadersScreen> createState() => _CustomHeadersScreenState();
}

class _CustomHeadersScreenState extends State<CustomHeadersScreen> {
  final List<MapEntry<String, String>> _headers = [];

  @override
  void initState() {
    super.initState();
    _loadInitialHeaders();
  }

  void _loadInitialHeaders() {
    if (widget.initialHeaders != null && widget.initialHeaders!.isNotEmpty) {
      try {
        final headers = _parseHeaders(widget.initialHeaders!);
        _headers.addAll(headers.entries);
      } catch (e) {
        // If parsing fails, start with empty list
      }
    }
  }

  Map<String, String> _parseHeaders(String headersText) {
    final Map<String, String> headers = {};
    final lines = headersText.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty) {
        final colonIndex = trimmedLine.indexOf(':');
        if (colonIndex > 0) {
          final key = trimmedLine.substring(0, colonIndex).trim();
          final value = trimmedLine.substring(colonIndex + 1).trim();
          if (key.isNotEmpty) {
            headers[key] = value;
          }
        }
      }
    }

    return headers;
  }

  String _formatHeaders() {
    return _headers.map((entry) => '${entry.key}: ${entry.value}').join('\n');
  }

  void _addHeader() {
    showDialog(
      context: context,
      builder: (context) => _HeaderDialog(
        onSave: (key, value) {
          setState(() {
            _headers.add(MapEntry(key, value));
          });
        },
      ),
    );
  }

  void _editHeader(int index) {
    final header = _headers[index];
    showDialog(
      context: context,
      builder: (context) => _HeaderDialog(
        initialKey: header.key,
        initialValue: header.value,
        onSave: (key, value) {
          setState(() {
            _headers[index] = MapEntry(key, value);
          });
        },
      ),
    );
  }

  void _deleteHeader(int index) {
    setState(() {
      _headers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Custom Headers'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, _formatHeaders());
              },
              child: const Text('Save'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Preview section
            if (_headers.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.preview,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Headers Preview',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatHeaders(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],

            // Headers list
            Expanded(
              child: _headers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.http,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No custom headers added',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first header',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _headers.length,
                      itemBuilder: (context, index) {
                        final header = _headers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(
                              header.key,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(header.value),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editHeader(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteHeader(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addHeader,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _HeaderDialog extends StatefulWidget {
  final String? initialKey;
  final String? initialValue;
  final Function(String key, String value) onSave;

  const _HeaderDialog({
    this.initialKey,
    this.initialValue,
    required this.onSave,
  });

  @override
  State<_HeaderDialog> createState() => _HeaderDialogState();
}

class _HeaderDialogState extends State<_HeaderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _keyController.text = widget.initialKey ?? '';
    _valueController.text = widget.initialValue ?? '';
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(_keyController.text.trim(), _valueController.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialKey != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Header' : 'Add Header'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Header Key',
                hintText: 'e.g., Authorization, User-Agent',
                helperText: 'The header name (case-insensitive)',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Header key is required';
                }
                if (value.contains(':')) {
                  return 'Header key cannot contain colons';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Header Value',
                hintText: 'e.g., Bearer token123, MyApp/1.0',
                helperText: 'The header value',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Header value is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
