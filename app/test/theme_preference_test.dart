import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/core/settings/settings_storage.dart';
import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/auth_storage.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/data/api_fatura_repository.dart';
import 'package:fatura/main.dart';
import 'package:fatura/state/app_state.dart';

import 'support/fake_api.dart';

void main() {
  setUp(() {
    tokenManager.clearTokens();
    authStorage = InMemoryAuthStorage();
    settingsStorage = InMemorySettingsStorage();
    api.httpClientAdapter = FakeAdapter(defaultHandler);
  });

  tearDown(tokenManager.clearTokens);

  test('sem escolha gravada, o app segue o sistema', () {
    expect(AppState(ApiFaturaRepository()).themeMode, ThemeMode.system);
  });

  test('escolher um tema grava a preferência', () async {
    final appState = AppState(ApiFaturaRepository());

    appState.setThemeMode(ThemeMode.dark);

    expect(appState.themeMode, ThemeMode.dark);
    expect(await settingsStorage.readThemeMode(), ThemeMode.dark);
  });

  testWidgets('a escolha sobrevive a reabrir o app', (tester) async {
    await settingsStorage.saveThemeMode(ThemeMode.dark);

    // O que o `main()` faz: lê antes de construir, para não piscar.
    final stored = await settingsStorage.readThemeMode();
    await tester.pumpWidget(FaturaApp(initialThemeMode: stored));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
