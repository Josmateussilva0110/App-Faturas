import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/auth_storage.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/main.dart';

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
    // Default: the backend accepts the login. Individual tests override it.
    api.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'success': true, 'message': 'ok', 'data': fakeSession()}, 200),
    );
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
}
