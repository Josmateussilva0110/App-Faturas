import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/main.dart';

/// Boots the app and lets `AppState.load` finish. The welcome screen is
/// static, so `pumpAndSettle` alone would return before the repository's
/// simulated latency has elapsed and leave its timers pending.
Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const FaturaApp());
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
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

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Compras ativas'.toUpperCase()), findsOneWidget);

    await tester.tap(find.text('Cartões'));
    await tester.pumpAndSettle();
    expect(find.text('Nubank'), findsOneWidget);

    // Let the success toast time out so its timer doesn't outlive the test.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
