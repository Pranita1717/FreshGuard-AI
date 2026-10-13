import 'package:flutter/foundation.dart';

class ApiConfig {
  // Default base URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Physical Android phone on the same Wi-Fi network as the Spring Boot server
      return 'http://172.20.10.6:8080/api';
    } else {
      // Windows Desktop, macOS, Linux
      return 'http://localhost:8080/api';
    }
  }

  // Allow runtime custom server IP for physical devices (e.g. 192.168.1.50)
  static String? _customBaseUrl;

  static String get activeBaseUrl => _customBaseUrl ?? baseUrl;

  static void setCustomBaseUrl(String url) {
    if (url.trim().isNotEmpty) {
      _customBaseUrl = url.trim();
    }
  }

  static void resetBaseUrl() {
    _customBaseUrl = null;
  }
}
