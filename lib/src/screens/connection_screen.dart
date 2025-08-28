import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../services/prefs.dart';
import '../services/firebase_service.dart';
import '../utils/error_handler.dart';
import 'custom_headers_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  final _pathController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverNameController = TextEditingController();
  final _headersController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _useHttps = false;
  bool _savePassword = false;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _pathController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _serverNameController.dispose();
    _headersController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Build the base URL from separate fields
      final host = _hostController.text.trim();
      final port = _portController.text.trim();
      final path = _pathController.text.trim();

      // Detect and handle protocol in host field
      String cleanHost = host;
      String scheme = _useHttps ? 'https' : 'http';

      // Check if user included protocol in host field
      if (host.toLowerCase().startsWith('http://')) {
        cleanHost = host.substring(7); // Remove 'http://'
        scheme = 'http';
        // Update UI to reflect detected protocol
        if (_useHttps) {
          setState(() {
            _useHttps = false;
          });
        }
      } else if (host.toLowerCase().startsWith('https://')) {
        cleanHost = host.substring(8); // Remove 'https://'
        scheme = 'https';
        // Update UI to reflect detected protocol
        if (!_useHttps) {
          setState(() {
            _useHttps = true;
          });
        }
      }

      String baseUrl = '$scheme://$cleanHost';
      if (port.isNotEmpty && port != '80' && port != '443') {
        baseUrl += ':$port';
      }
      if (path.isNotEmpty) {
        if (!path.startsWith('/')) {
          baseUrl += '/';
        }
        baseUrl += path;
      }

      await context.read<AppState>().connect(
        baseUrl: baseUrl,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        serverName: _serverNameController.text.trim().isEmpty
            ? null
            : _serverNameController.text.trim(),
        customHeaders: _parseHeaders(_headersController.text),
      );

      // Log successful connection
      FirebaseService.instance.logEvent(
        name: 'connection_success',
        parameters: {
          'protocol': scheme,
          'has_custom_headers': _headersController.text.isNotEmpty,
          'save_password': _savePassword,
        },
      );

      // Persist convenience fields
      await Prefs.saveBaseUrl(baseUrl);
      await Prefs.saveUsername(_usernameController.text.trim());
      // Only save password if user explicitly chooses to
      if (_savePassword) {
        await Prefs.savePassword(_passwordController.text);
      } else {
        // Clear any previously saved password
        await Prefs.savePassword('');
      }
      // Save the save password preference
      await Prefs.saveSavePasswordPreference(_savePassword);
      await Prefs.saveServerName(_serverNameController.text.trim());
      await Prefs.saveCustomHeadersText(_headersController.text);
    } catch (e) {
      // Log connection error
      FirebaseService.instance.logEvent(
        name: 'connection_error',
        parameters: {
          'error_type': e.runtimeType.toString(),
          'error_message': e.toString(),
        },
      );

      setState(() {
        _error = ErrorHandler.getUserFriendlyMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Scaffold(
          appBar: AppBar(title: const Text('Connect to qBittorrent')),
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: Platform.isIOS ? 24 : 16,
              top: 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: const Icon(Icons.login),
                label: Text(_isLoading ? 'Connecting…' : 'Connect'),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _serverNameController,
                    decoration: const InputDecoration(
                      labelText: 'Server name (optional)',
                      hintText: 'e.g., Home NAS',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Protocol selection
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Use HTTPS'),
                          value: _useHttps,
                          onChanged: (value) {
                            setState(() {
                              _useHttps = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Host field
                  TextFormField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'Host/IP Address',
                      hintText: 'e.g., 192.168.1.100 or nas.local',
                      helperText:
                          'Protocol (http:// or https://) will be detected automatically',
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Required';

                      // Check for valid host format (with or without protocol)
                      final cleanValue = value
                          .toLowerCase()
                          .replaceAll('http://', '')
                          .replaceAll('https://', '');

                      if (cleanValue.isEmpty) return 'Invalid host address';

                      // Basic validation for host format
                      if (cleanValue.contains('://')) {
                        return 'Invalid protocol format';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Port field
                  TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: 'e.g., 8080',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Required';
                      final port = int.tryParse(value);
                      if (port == null || port <= 0 || port > 65535) {
                        return 'Invalid port (1-65535)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Path field
                  TextFormField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'Path (optional)',
                      hintText: 'e.g., /qbittorrent',
                    ),
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  // Save Password Checkbox
                  CheckboxListTile(
                    title: const Text('Save password'),
                    subtitle: const Text(
                      'Remember password for future connections',
                    ),
                    value: _savePassword,
                    onChanged: (value) {
                      setState(() {
                        _savePassword = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: 16),
                  // Custom Headers Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.http,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Custom Headers',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomHeadersScreen(
                                      initialHeaders: _headersController.text,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  setState(() {
                                    _headersController.text = result;
                                  });
                                }
                              },
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomHeadersScreen(
                                  initialHeaders: _headersController.text,
                                ),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _headersController.text = result;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: _headersController.text.isEmpty
                                ? Text(
                                    'No custom headers added',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                          fontStyle: FontStyle.italic,
                                        ),
                                  )
                                : Text(
                                    _headersController.text,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Log screen view
    FirebaseService.instance.logScreenView(
      screenName: 'connection_screen',
      screenClass: 'ConnectionScreen',
    );
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final savedUrl = await Prefs.loadBaseUrl();
    final savedUser = await Prefs.loadUsername();
    final savedPassword = await Prefs.loadPassword();
    final savedName = await Prefs.loadServerName();
    final savedHeaders = await Prefs.loadCustomHeadersText();
    final savePasswordPreference = await Prefs.loadSavePasswordPreference();

    if (!mounted) return;
    setState(() {
      if (savedUrl != null) _parseAndSetUrl(savedUrl);
      if (savedUser != null) _usernameController.text = savedUser;
      if (savedName != null) _serverNameController.text = savedName;
      if (savedHeaders != null) _headersController.text = savedHeaders;

      // Handle password loading and save preference
      _savePassword = savePasswordPreference;
      // Only load password if the field is currently empty (first load)
      if (_passwordController.text.isEmpty) {
        if (savePasswordPreference &&
            savedPassword != null &&
            savedPassword.isNotEmpty) {
          _passwordController.text = savedPassword;
        }
      }
    });
  }

  void _parseAndSetUrl(String url) {
    try {
      final uri = Uri.parse(url);
      _useHttps = uri.scheme == 'https';
      _hostController.text = uri.host;
      _portController.text = uri.hasPort ? uri.port.toString() : '';
      _pathController.text = uri.path.isNotEmpty && uri.path != '/'
          ? uri.path
          : '';
    } catch (e) {
      // If parsing fails, try to extract host from common patterns
      String cleanUrl = url.trim();

      // Remove protocol if present
      if (cleanUrl.toLowerCase().startsWith('http://')) {
        cleanUrl = cleanUrl.substring(7);
        _useHttps = false;
      } else if (cleanUrl.toLowerCase().startsWith('https://')) {
        cleanUrl = cleanUrl.substring(8);
        _useHttps = true;
      }

      // Try to extract host and port
      final colonIndex = cleanUrl.indexOf(':');
      if (colonIndex > 0) {
        final hostPart = cleanUrl.substring(0, colonIndex);
        final remaining = cleanUrl.substring(colonIndex + 1);

        // Check if remaining part contains port
        final slashIndex = remaining.indexOf('/');
        if (slashIndex > 0) {
          final portPart = remaining.substring(0, slashIndex);
          final pathPart = remaining.substring(slashIndex);

          if (int.tryParse(portPart) != null) {
            _hostController.text = hostPart;
            _portController.text = portPart;
            _pathController.text = pathPart;
            return;
          }
        } else if (int.tryParse(remaining) != null) {
          _hostController.text = hostPart;
          _portController.text = remaining;
          _pathController.text = '';
          return;
        }
      }

      // Fallback to default values
      _hostController.text = '127.0.0.1';
      _portController.text = '8080';
      _pathController.text = '';
    }
  }

  Map<String, String> _parseHeaders(String text) {
    final Map<String, String> headers = {};
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final key = line.substring(0, idx).trim();
      final value = line.substring(idx + 1).trim();
      if (key.isNotEmpty) headers[key] = value;
    }
    return headers;
  }
}
