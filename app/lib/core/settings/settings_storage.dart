import 'package:flutter/material.dart';

/// Onde as preferências de interface sobrevivem entre aberturas do app.
///
/// Mesmo desenho do `AuthStorage` em `data/api/auth_storage.dart`: interface,
/// uma implementação real e uma em memória — é o que deixa os testes
/// trocarem a persistência em `setUp` sem tocar no disco.
abstract class SettingsStorage {
  Future<ThemeMode?> readThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
}

class InMemorySettingsStorage implements SettingsStorage {
  ThemeMode? _mode;

  @override
  Future<ThemeMode?> readThemeMode() async => _mode;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async => _mode = mode;
}

/// Trocada no boot por `SecureSettingsStorage`; nos testes fica a de memória.
SettingsStorage settingsStorage = InMemorySettingsStorage();
