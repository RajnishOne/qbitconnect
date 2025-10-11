import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import '../api/qbittorrent_api.dart';
import '../utils/error_handler.dart';
import '../utils/network_utils.dart';
import '../constants/app_strings.dart';
import '../state/app_state_manager.dart';
import 'custom_headers_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _serverNameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  final _pathController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _headersController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _useHttps = false;
  bool _savePassword = true;

  @override
  void initState() {
    super.initState();
    // Log screen view
    FirebaseService.instance.logScreenView(
      screenName: 'connection_screen',
      screenClass: 'ConnectionScreen',
    );

    _setupErrorClearingListeners();
  }

  void _setupErrorClearingListeners() {
    // Clear error when any form field changes
    _serverNameController.addListener(_clearError);
    _hostController.addListener(_clearError);
    _portController.addListener(_clearError);
    _pathController.addListener(_clearError);
    _usernameController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _headersController.addListener(_clearError);
  }

  void _clearError() {
    if (_error != null && mounted) {
      setState(() {
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    // Remove listeners to prevent memory leaks
    _serverNameController.removeListener(_clearError);
    _hostController.removeListener(_clearError);
    _portController.removeListener(_clearError);
    _pathController.removeListener(_clearError);
    _usernameController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _headersController.removeListener(_clearError);

    _scrollController.dispose();
    _serverNameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _pathController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _headersController.dispose();
    super.dispose();
  }

  Future<bool> _checkNetworkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return true;
    }
  }

  /// Check if the current host is on a local network
  bool _isLocalNetwork() {
    final host = _hostController.text.trim();
    if (host.isEmpty) return false;
    return NetworkUtils.isLocalNetwork(host);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Map<String, String>? _parseHeaders(String text) {
    if (text.isEmpty) return null;

    final Map<String, String> headers = {};
    final lines = text.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final colonIndex = trimmed.indexOf(':');
      if (colonIndex > 0 && colonIndex < trimmed.length - 1) {
        final key = trimmed.substring(0, colonIndex).trim();
        final value = trimmed.substring(colonIndex + 1).trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          headers[key] = value;
        }
      }
    }

    return headers.isEmpty ? null : headers;
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    // Check network connectivity first
    final hasNetwork = await _checkNetworkConnectivity();
    if (!hasNetwork) {
      setState(() {
        _error =
            'No network connection available. Please check your internet connection and try again.';
      });
      _scrollToBottom();
      return;
    }

    // Set loading state and clear any previous errors
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

      if (host.startsWith('http://') || host.startsWith('https://')) {
        final uri = Uri.parse(host);
        scheme = uri.scheme;
        cleanHost = uri.host;
        if (uri.hasPort && port == '8080') {
          _portController.text = uri.port.toString();
        }
      }

      // Build the full URL
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

      // Get connection parameters
      final isLocal = _isLocalNetwork();
      final hasCredentials =
          _usernameController.text.trim().isNotEmpty &&
          _passwordController.text.isNotEmpty;

      try {
        // Create a temporary API client to test the connection
        final tempApiClient = QbittorrentApiClient(
          baseUrl: baseUrl,
          defaultHeaders: _parseHeaders(_headersController.text),
          enableLogging: false, // Disable logging for validation
        );

        // Test connection based on available credentials and network type
        if (hasCredentials) {
          // Test login with provided credentials with timeout
          await Future.any([
            tempApiClient.login(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            ),
            Future.delayed(const Duration(seconds: 10), () {
              throw Exception(
                'Connection timeout - server did not respond within 10 seconds',
              );
            }),
          ]);
        } else if (isLocal) {
          // Try to connect without authentication for local network
          try {
            await Future.any([
              tempApiClient.loginWithoutAuth(),
              Future.delayed(const Duration(seconds: 10), () {
                throw Exception(
                  'Connection timeout - server did not respond within 10 seconds',
                );
              }),
            ]);
          } catch (e) {
            // If no-auth fails on local network, provide helpful message
            if (e.toString().contains('Authentication required') ||
                e.toString().contains('403')) {
              throw Exception(
                'This qBittorrent instance requires authentication. Please provide username and password.',
              );
            }
            rethrow;
          }
        } else {
          throw Exception(
            'Username and password are required for remote connections',
          );
        }

        // Logout from the test connection if we used authentication
        if (hasCredentials) {
          await tempApiClient.logout();
        }
      } catch (e) {
        // Log the actual error for debugging
        debugPrint('ConnectionScreen validation error: $e');

        // Determine error message
        String errorMessage;
        if (e.toString().contains('Username and password are required')) {
          errorMessage =
              'Username and password are required for remote connections.';
        } else if (e.toString().contains('Authentication required') ||
            e.toString().contains('403')) {
          errorMessage =
              'This qBittorrent instance requires authentication. Please provide username and password.';
        } else if (e.toString().contains('Login failed') ||
            e.toString().contains('Fails.') ||
            e.toString().contains('401') ||
            e.toString().contains('403')) {
          errorMessage =
              'Invalid username or password. Please check your credentials and try again.';
        } else if (e.toString().contains('Connection refused') ||
            e.toString().contains('timeout') ||
            e.toString().contains('Network is unreachable') ||
            e.toString().contains('Connection timeout')) {
          errorMessage =
              'Cannot connect to qBittorrent. Please check the address and port, and ensure qBittorrent is running.';
        } else {
          errorMessage =
              'Failed to connect to qBittorrent: ${e.toString()}. Please check your connection details and try again.';
        }

        // Update state once with error message and loading state
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      // Log successful connection
      FirebaseService.instance.logEvent(
        name: 'connection_established',
        parameters: {
          'protocol': scheme,
          'has_custom_headers': _headersController.text.isNotEmpty
              ? 'yes'
              : 'no',
          'save_password': _savePassword ? 'yes' : 'no',
        },
      );

      // Connect to the server
      final appState = context.read<AppState>();
      await appState.connect(
        baseUrl: baseUrl,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        serverName: _serverNameController.text.trim().isNotEmpty
            ? _serverNameController.text.trim()
            : cleanHost,
        customHeaders: _parseHeaders(_headersController.text),
        allowNoAuth: isLocal && !hasCredentials,
      );

      // Fetch initial data from the new server
      // This is important especially when polling is disabled
      await appState.refreshNow();

      // Connection successful
      if (mounted) {
        // Pop back to previous screen if this was opened as a modal
        // (e.g., from server list). The navigator will check if we can pop.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Log error
      FirebaseService.instance.logEvent(
        name: 'connection_error',
        parameters: {
          'error_type': e.runtimeType.toString(),
          'error_message': e.toString(),
        },
      );

      // Update state once with error and loading state
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getUserFriendlyMessage(e);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } finally {
      // Only update loading state if no error was set above
      if (mounted && _error == null) {
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
        bottom: Platform.isAndroid,
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
                onPressed: _isLoading ? null : _connect,
                icon: const Icon(Icons.link),
                label: Text(_isLoading ? 'Connecting...' : 'Connect'),
              ),
            ),
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
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
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  // Protocol selection
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text(AppStrings.useHttps),
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
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return AppStrings.required;

                      // Check for valid host format (with or without protocol)
                      final cleanValue = value
                          .toLowerCase()
                          .replaceAll('http://', '')
                          .replaceAll('https://', '');

                      if (cleanValue.isEmpty)
                        return AppStrings.invalidHostAddress;

                      // Basic validation for host format
                      if (cleanValue.contains('://')) {
                        return AppStrings.invalidProtocolFormat;
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Port field
                  TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.port,
                      hintText: 'e.g., 8080',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return AppStrings.required;
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
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: AppStrings.username),
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final isLocal = _isLocalNetwork();
                      if (isLocal) {
                        // For local network, username is optional
                        return null;
                      }
                      return (v == null || v.trim().isEmpty)
                          ? AppStrings.required
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: AppStrings.password,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? AppStrings.showPassword
                            : AppStrings.hidePassword,
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
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      final isLocal = _isLocalNetwork();
                      if (isLocal) {
                        // For local network, password is optional
                        return null;
                      }
                      return (v == null || v.isEmpty)
                          ? AppStrings.required
                          : null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Save Password Checkbox
                  CheckboxListTile(
                    title: const Text(AppStrings.savePassword),
                    subtitle: const Text(
                      AppStrings.rememberPasswordForFutureConnections,
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
                              AppStrings.customHeaders,
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
                              label: const Text(AppStrings.edit),
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
                                    AppStrings.noCustomHeadersAdded,
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
}
