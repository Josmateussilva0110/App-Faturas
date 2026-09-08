import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/auth_data.dart';
import 'auth_storage.dart';

/// Keeps the session on the device between launches, encrypted by the
/// platform keystore. The refresh token is a long-lived credential, so it
/// doesn't belong in plain shared preferences.
class SecureAuthStorage implements AuthStorage {
  SecureAuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String _key = 'auth_session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthData?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      return AuthData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // The keystore entry can become unreadable (app reinstalled, keys
      // rotated, payload from an older format). Drop it and treat the user
      // as signed out — better than crashing on the splash screen.
      await remove();
      return null;
    }
  }

  @override
  Future<void> save(AuthData auth) {
    return _storage.write(key: _key, value: jsonEncode(auth.toJson()));
  }

  @override
  Future<void> remove() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Nothing to do: the session is already gone from memory.
    }
  }
}
