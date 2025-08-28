class ErrorHandler {
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    final errorString = error.toString().toLowerCase();

    // Connection timeout errors
    if (errorString.contains('connection timeout') ||
        errorString.contains('connect timeout')) {
      return 'Connection timed out. Please check:\n'
          '• Your internet connection\n'
          '• The server URL is correct\n'
          '• The qBittorrent server is running\n'
          '• The port is accessible';
    }

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection refused')) {
      return 'Network error. Please check:\n'
          '• Your internet connection\n'
          '• The server URL and port\n'
          '• qBittorrent is running and accessible';
    }

    // DNS resolution errors
    if (errorString.contains('dns') ||
        errorString.contains('host not found') ||
        errorString.contains('name resolution')) {
      return 'Cannot find the server. Please check:\n'
          '• The server URL is correct\n'
          '• Your internet connection\n'
          '• Try using IP address instead of hostname';
    }

    // SSL/TLS errors
    if (errorString.contains('ssl') ||
        errorString.contains('certificate') ||
        errorString.contains('tls') ||
        errorString.contains('handshake')) {
      return 'SSL/TLS connection error. Please check:\n'
          '• Use https:// for secure connections\n'
          '• Use http:// for non-secure connections\n'
          '• Server certificate is valid';
    }

    // Authentication errors
    if (errorString.contains('login failed') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('403')) {
      return 'Authentication failed. Please check:\n'
          '• Username and password are correct\n'
          '• You have permission to access qBittorrent\n'
          '• Authentication is enabled in qBittorrent settings';
    }

    // Server not found errors
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Server not found. Please check:\n'
          '• The server URL is correct\n'
          '• qBittorrent is running\n'
          '• The web UI is enabled in qBittorrent settings';
    }

    // Server error responses
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return 'Server error. Please check:\n'
          '• qBittorrent is running properly\n'
          '• Try restarting qBittorrent\n'
          '• Check qBittorrent logs for errors';
    }

    // Malformed URL errors
    if (errorString.contains('invalid url') ||
        errorString.contains('malformed')) {
      return 'Invalid URL format. Please check:\n'
          '• URL starts with http:// or https://\n'
          '• Port number is correct (e.g., :8080)\n'
          '• No extra spaces or special characters';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timed out. Please check:\n'
          '• Your internet connection\n'
          '• The server is responding\n'
          '• Try again in a few moments';
    }

    // Generic Dio errors
    if (errorString.contains('dioexception')) {
      return 'Connection error. Please check:\n'
          '• Server URL and port are correct\n'
          '• qBittorrent is running\n'
          '• Your internet connection';
    }

    // If we can't identify the specific error, provide a generic message
    return 'Connection failed. Please check:\n'
        '• Server URL and port are correct\n'
        '• Username and password are correct\n'
        '• qBittorrent is running and accessible\n'
        '• Your internet connection';
  }

  static String getShortErrorMessage(dynamic error) {
    if (error == null) return 'Connection failed';

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('connection timeout') ||
        errorString.contains('connect timeout')) {
      return 'Connection timed out';
    }

    if (errorString.contains('login failed') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('403')) {
      return 'Authentication failed';
    }

    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Server not found';
    }

    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection refused')) {
      return 'Network error';
    }

    if (errorString.contains('dns') || errorString.contains('host not found')) {
      return 'Cannot find server';
    }

    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timed out';
    }

    return 'Connection failed';
  }
}
