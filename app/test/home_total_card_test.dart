import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/core/utils/formatters.dart';
import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/auth_storage.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/main.dart';

import 'support/fake_api.dart';

/// Sobe o app com a meta de gastos [spendingLimit] no perfil e entra na conta.
/// As compras são as do [defaultHandler]: uma só, própria, de R$ 165,00.
Future<void> _openHomeWithLimit(WidgetTester tester, double? spendingLimit) async {
  api.httpClientAdapter = FakeAdapter((options) {
    if (options.path.contains('/profile')) {
      return jsonBody({'success': true, 'data': fakeProfile(spendingLimit: spendingLimit)}, 200);
    }
    return defaultHandler(options);
  });

  await tester.pumpWidget(const FaturaApp());
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'voce@email.com');
  await tester.enterText(find.byType(TextField).last, 'senha123');
  await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
  await tester.pumpAndSettle();
  // O toast de boas-vindas some sozinho em 3 s; sem esperar por ele, o
  // teste termina com o timer pendente e falha por um motivo alheio.
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    tokenManager.clearTokens();
    authStorage = InMemoryAuthStorage();
  });

  tearDown(tokenManager.clearTokens);

  testWidgets('o mês vira pílula e a contagem fica sob o valor', (tester) async {
    await _openHomeWithLimit(tester, null);

    expect(find.text('Total do mês'), findsOneWidget);
    expect(find.text(formatMonthLabel(currentAbsoluteMonth())), findsOneWidget);
    expect(find.text('1 compra ativa'), findsOneWidget);
  });

  testWidgets('sem meta, o card convida a definir uma', (tester) async {
    await _openHomeWithLimit(tester, null);

    expect(find.text('Definir meta de gastos'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('com folga, mostra a porcentagem e quanto resta', (tester) async {
    await _openHomeWithLimit(tester, 1000);

    expect(find.text('17%'), findsOneWidget);
    expect(find.text('Restam ${formatMoney(835)} de ${formatMoney(1000)}'), findsOneWidget);
  });

  testWidgets('perto do limite, avisa', (tester) async {
    await _openHomeWithLimit(tester, 200);

    expect(find.text('Quase no limite · restam ${formatMoney(35)}'), findsOneWidget);
  });

  testWidgets('depois do limite, diz quanto passou', (tester) async {
    await _openHomeWithLimit(tester, 100);

    expect(find.text('165%'), findsOneWidget);
    expect(find.text('Passou ${formatMoney(65)} do limite'), findsOneWidget);
  });
}
