import 'dart:io';

/// Utility functions for network-related operations
class NetworkUtils {
  /// Check if a host address is on a local network
  /// Returns true if the host is on a private/local network
  static bool isLocalNetwork(String host) {
    try {
      // Remove protocol if present
      final cleanHost = host
          .toLowerCase()
          .replaceAll('http://', '')
          .replaceAll('https://', '')
          .split('/')[0] // Remove path
          .split(':')[0]; // Remove port

      // Handle localhost
      if (cleanHost == 'localhost' || cleanHost == '127.0.0.1') {
        return true;
      }

      // Handle .local domains (mDNS)
      if (cleanHost.endsWith('.local')) {
        return true;
      }

      // Parse IP address
      final ip = InternetAddress(cleanHost);
      if (ip.type != InternetAddressType.IPv4) {
        return false;
      }

      final parts = cleanHost.split('.');
      if (parts.length != 4) {
        return false;
      }

      final octets = parts.map(int.parse).toList();

      // Check for private IP ranges:
      // 10.0.0.0/8 (10.0.0.0 - 10.255.255.255)
      if (octets[0] == 10) {
        return true;
      }

      // 172.16.0.0/12 (172.16.0.0 - 172.31.255.255)
      if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) {
        return true;
      }

      // 192.168.0.0/16 (192.168.0.0 - 192.168.255.255)
      if (octets[0] == 192 && octets[1] == 168) {
        return true;
      }

      // 169.254.0.0/16 (169.254.0.0 - 169.254.255.255) - Link-local
      if (octets[0] == 169 && octets[1] == 254) {
        return true;
      }

      return false;
    } catch (e) {
      // If we can't parse the address, assume it's not local
      return false;
    }
  }

  /// Check if the current device is likely on a local network
  /// This is a simple heuristic based on common local network patterns
  static Future<bool> isDeviceOnLocalNetwork() async {
    try {
      // Try to get the local IP address
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              isLocalNetwork(addr.address)) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
