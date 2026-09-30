import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/core/theme/app_theme.dart';
import 'package:fatura/features/monthly/widgets/statement_wallet.dart';
import 'package:fatura/models/card_model.dart';
import 'package:fatura/models/card_statement.dart';
import 'package:fatura/state/app_state.dart';

StatementCheck _check(String id, String name, {double? billed, required double registered}) {
  return StatementCheck(
    card: CardModel(id: id, name: name),
    statement: billed == null ? null : CardStatement(id: 's$id', cardId: id, monthAbs: 0, amount: billed),
    registered: registered,
  );
}

Future<void> _pump(WidgetTester tester, List<StatementCheck> checks, {void Function(StatementCheck)? onTap}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: StatementWallet(checks: checks, onTap: onTap ?? (_) {}),
        ),
      ),
    ),
  );
}

/// O toque vai na faixa do topo, que é o que fica à mostra de um cartão
/// guardado — o centro dele está coberto pelos da frente.
Future<void> _tapCard(WidgetTester tester, String name) async {
  final card = find.bySemanticsLabel(RegExp('^Cartão $name'));
  await tester.tapAt(tester.getTopLeft(card) + const Offset(40, 12));
  await tester.pumpAndSettle();
}

void main() {
  final checks = [
    _check('c1', 'Mercado Pago', billed: 139.24, registered: 139.24),
    _check('c2', 'Nubank', billed: 1650.82, registered: 1601.27),
    _check('c3', 'Itaú', registered: 310.5),
  ];

  testWidgets('abre no primeiro cartão que pede atenção, não no primeiro da lista', (tester) async {
    await _pump(tester, checks);
    await tester.pumpAndSettle();

    // Mercado Pago confere; o Nubank é o que falta lançar.
    expect(find.text('Faltam R\$ 49,55 em compras para lançar no app.'), findsOneWidget);
    expect(find.text('Bateu exatamente com a fatura.'), findsNothing);
  });

  testWidgets('tocar num cartão guardado troca o detalhe', (tester) async {
    await _pump(tester, checks);
    await tester.pumpAndSettle();

    await _tapCard(tester, 'Mercado Pago');
    expect(find.text('Bateu exatamente com a fatura.'), findsOneWidget);

    await _tapCard(tester, 'Itaú');
    expect(find.text('Toque para informar o valor da fatura e conferir.'), findsOneWidget);
  });

  testWidgets('o toque no detalhe devolve o cartão aberto', (tester) async {
    StatementCheck? tapped;
    await _pump(tester, checks, onTap: (check) => tapped = check);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Faltam R\$ 49,55 em compras para lançar no app.'));
    expect(tapped?.card.id, 'c2');
  });

  testWidgets('com todos conferindo, abre no primeiro', (tester) async {
    await _pump(tester, [
      _check('c1', 'Mercado Pago', billed: 100, registered: 100),
      _check('c2', 'Nubank', billed: 50, registered: 50),
    ]);
    await tester.pumpAndSettle();

    // "Mercado Pago" no cartão, no bolso e no detalhe.
    expect(find.text('Mercado Pago'), findsNWidgets(3));
  });
}
