import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/auth_storage.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/main.dart';
import 'package:fatura/models/auth_data.dart';

import 'support/fake_api.dart';

/// Boots the app and lets `AppState.load` finish. The welcome screen is
/// static, so `pumpAndSettle` alone would return before the repository's
/// simulated latency has elapsed and leave its timers pending.
Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const FaturaApp());
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    tokenManager.clearTokens();
    authStorage = InMemoryAuthStorage();
    // Default: the backend accepts the login and serves the profile.
    // Individual tests override it.
    api.httpClientAdapter = FakeAdapter(defaultHandler);
  });

  tearDown(tokenManager.clearTokens);

  testWidgets('App opens on the welcome screen', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Fatura'), findsOneWidget);
    expect(find.text('Suas contas do mês,\nsob controle.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('Login requires an email and a password', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo de volta'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu email.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    // Still on the login screen — nothing was submitted.
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });

  testWidgets('Signing in shows the Home tab with bottom navigation', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'voce@email.com');
    await tester.enterText(find.byType(TextField).last, 'senha123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    // The session returned by the backend is now the active one.
    expect(tokenManager.accessToken, 'access-1');
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Compras ativas'.toUpperCase()), findsOneWidget);

    await tester.tap(find.text('Cartões'));
    await tester.pumpAndSettle();
    expect(find.text('Nubank'), findsOneWidget);

    // Let the success toast time out so its timer doesn't outlive the test.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('A aba Meses confere a fatura informada contra o registrado', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'voce@email.com');
    await tester.enterText(find.byType(TextField).last, 'senha123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meses'));
    await tester.pumpAndSettle();

    // Fatura (165) e registrado (165) batem: estado "Confere".
    expect(find.text('Conferência da fatura'.toUpperCase()), findsOneWidget);
    expect(find.text('Confere'), findsOneWidget);
    expect(find.text('Bateu exatamente com a fatura.'), findsOneWidget);

    // O diálogo abre com o valor atual e mostra o total registrado.
    await tester.tap(find.text('Confere'));
    await tester.pumpAndSettle();
    expect(find.text('Fatura · Nubank'), findsOneWidget);
    expect(find.text('Registrado no app: R\$ 165,00'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('Wrong credentials keep the user on the login screen', (tester) async {
    api.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'success': false, 'message': 'Email ou senha incorreto'}, 401),
    );

    await _pumpApp(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'voce@email.com');
    await tester.enterText(find.byType(TextField).last, 'errada');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.text('Email ou senha incorreto'), findsOneWidget);
    expect(tokenManager.accessToken, isNull);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('A 422 puts the backend message under the field', (tester) async {
    api.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({
        'success': false,
        'message': 'Erro de validação',
        'errors': [
          {'field': 'password', 'message': 'Senha é obrigatória.'},
        ],
      }, 422),
    );

    await _pumpApp(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'voce@email.com');
    await tester.enterText(find.byType(TextField).last, 'x');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Senha é obrigatória.'), findsWidgets);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('A stored session opens straight into the app', (tester) async {
    await authStorage.save(AuthData.fromJson(fakeSession()));

    await _pumpApp(tester);

    // No welcome screen, no login: the session was restored at boot.
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsNothing);
    expect(find.text('Início'), findsOneWidget);
    expect(tokenManager.accessToken, 'access-1');
  });

  testWidgets('The profile shows the account from the backend', (tester) async {
    await authStorage.save(AuthData.fromJson(fakeSession()));
    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('Mateus'), findsOneWidget);
    expect(find.text('mateus@email.com'), findsOneWidget);
  });

  testWidgets('Signing out clears the session and returns to the welcome screen',
      (tester) async {
    await authStorage.save(AuthData.fromJson(fakeSession()));
    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
    expect(tokenManager.accessToken, isNull);
    expect(tokenManager.refreshToken, isNull);
    // Nothing left on disk — the next launch lands on the welcome screen.
    expect(await authStorage.read(), isNull);
  });

  testWidgets('An account without a username falls back to the email', (tester) async {
    api.httpClientAdapter = FakeAdapter((options) {
      if (options.path.contains('/profile')) {
        return jsonBody({
          'success': true,
          'data': fakeProfile(username: '', email: 'semnome@email.com'),
        }, 200);
      }
      // O resto (cartões, compras) segue o handler padrão.
      return defaultHandler(options);
    });
    await authStorage.save(AuthData.fromJson(fakeSession()));
    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    // Shown once as the name, not duplicated on the line below it.
    expect(find.text('semnome@email.com'), findsOneWidget);
  });
}
