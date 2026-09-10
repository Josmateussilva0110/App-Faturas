import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'settings_storage.dart';

/// Grava a preferência de tema no armazenamento da plataforma.
///
/// Tema não é credencial e não precisaria de criptografia — mas usar o
/// `flutter_secure_storage`, que já é dependência por causa da sessão, evita
/// somar `shared_preferences` ao projeto só para guardar uma string.
class SecureSettingsStorage implements SettingsStorage {
  SecureSettingsStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String _themeKey = 'theme_mode';

  final FlutterSecureStorage _storage;

  @override
  Future<ThemeMode?> readThemeMode() async {
    try {
      final raw = await _storage.read(key: _themeKey);
      for (final mode in ThemeMode.values) {
        if (mode.name == raw) return mode;
      }
      return null;
    } catch (_) {
      // Entrada ilegível (app reinstalado, formato antigo): cai no padrão em
      // vez de impedir o app de abrir.
      return null;
    }
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      await _storage.write(key: _themeKey, value: mode.name);
    } catch (_) {
      // Perder a preferência é aceitável; travar o app ao trocar de tema não.
    }
  }
}
