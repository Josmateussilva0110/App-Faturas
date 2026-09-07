import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Where the Express backend lives, mirroring the React Native project's
/// `@/config/env`.
///
/// Override it at build/run time instead of editing this file:
/// `flutter run --dart-define=API_URL=https://api.exemplo.com/api`.
class ApiConfig {
  const ApiConfig._();

  static const String _override = String.fromEnvironment('API_URL');

  /// The backend's port, from the repo's `.env` (`PORT=3001`).
  static const int _devPort = 3001;

  /// Base URL every request is resolved against. Ends without a trailing
  /// slash so endpoints read as `/login`, `/profile`, ... just like the
  /// route constants in `api_routes.dart`.
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // The Android emulator reaches the host machine through 10.0.2.2;
    // localhost there would be the device itself.
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:$_devPort/api';
    return 'http://localhost:$_devPort/api';
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Refresh gets a shorter leash than regular calls: it runs while the user
  /// is waiting on the boot screen.
  static const Duration refreshTimeout = Duration(seconds: 15);
}
