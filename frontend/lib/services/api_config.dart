// import 'package:flutter/foundation.dart';

// class ApiConfig {
//   // Default base URL based on platform
//   static String get baseUrl {
//     if (kIsWeb) {
//       return 'https://freshguard-ai-vvx9.onrender.com/api';
//     } else if (defaultTargetPlatform == TargetPlatform.android) {
//       // Physical Android phone on the same Wi-Fi network as the Spring Boot server
//       return 'https://freshguard-ai-vvx9.onrender.com/api';
//     } else {
//       // Windows Desktop, macOS, Linux
//       return 'https://freshguard-ai-vvx9.onrender.com/api';
//     }
//   }

//   // Allow runtime custom server IP for physical devices (e.g. 192.168.1.50)
//   static String? _customBaseUrl;

//   static String get activeBaseUrl => _customBaseUrl ?? baseUrl;

//   static void setCustomBaseUrl(String url) {
//     if (url.trim().isNotEmpty) {
//       _customBaseUrl = url.trim();
//     }
//   }

//   static void resetBaseUrl() {
//     _customBaseUrl = null;
//   }
// }
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    return 'https://freshguard-ai-vvx9.onrender.com/api';
  }

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
