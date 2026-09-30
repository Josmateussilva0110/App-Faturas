import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/core/utils/formatters.dart';
import 'package:fatura/data/api_fatura_repository.dart';
import 'package:fatura/models/purchase.dart';
import 'package:fatura/state/app_state.dart';

// Setembro de 2026, fixo: o texto não pode depender do mês corrente.
const _september2026 = 2026 * 12 + 8;

PurchaseEntry _entry(String name, double amount, {int installments = 1, int number = 1}) {
  return (
    purchase: Purchase(
      id: name,
      name: name,
      amount: amount,
      installments: installments,
      isOther: true,
      person: 'Maria',
      cardId: 'c1',
      startAbs: _september2026,
    ),
    status: PurchaseStatus(active: true, installmentNumber: number),
  );
}

void main() {
  final appState = AppState(ApiFaturaRepository());

  String build({int monthAbs = _september2026, double discount = 0}) {
    return appState.buildShareText(
      label: 'Maria',
      monthAbs: monthAbs,
      rows: [
        _entry('Mercado', 120),
        _entry('Tênis', 80, installments: 5, number: 2),
      ],
      subtotal: 200,
      discount: discount,
    );
  }

  test('cabeçalho traz o mês da fatura e o vencimento desse mês', () {
    final text = build();

    expect(text, contains('*Fatura · ${formatMonthLabel(_september2026)}*'));
    expect(text, contains('Vence em 10/09/2026'));
    expect(text, contains('*Compras (2)*'));
  });

  test('outro mês muda título e vencimento, sem olhar o mês corrente', () {
    final text = build(monthAbs: _september2026 + 4);

    expect(text, contains(formatMonthLabel(_september2026 + 4)));
    expect(text, contains('Vence em 10/01/2027'));
  });

  /// Linhas do bloco ``` — o trecho que o WhatsApp mostra monoespaçado.
  List<String> block(String text) {
    final lines = text.split('\n');
    final open = lines.indexOf('```');
    final close = lines.lastIndexOf('```');
    return lines.sublist(open + 1, close);
  }

  test('compras e totais ficam num bloco monoespaçado', () {
    final text = build(discount: 20);

    expect('```'.allMatches(text).length, 2);
    expect(block(text).where((l) => l.startsWith('Mercado')), hasLength(1));
    expect(block(text).where((l) => l.startsWith('Total')), hasLength(1));
  });

  test('os valores terminam todos na mesma coluna', () {
    final lines = block(build(discount: 20)).where((l) => l.contains(r'R$')).toList();

    // Fim do valor = fim dos centavos. Tem de ser igual em toda linha,
    // compras e totais, senão a coluna fica torta no WhatsApp.
    final ends = lines.map((l) => l.indexOf(',') + 3).toSet();
    expect(lines, hasLength(5));
    expect(ends, hasLength(1));
  });

  test('parcela só aparece em compra parcelada', () {
    final lines = block(build());

    expect(lines.firstWhere((l) => l.startsWith('Mercado')), endsWith(formatMoney(120)));
    expect(lines.firstWhere((l) => l.startsWith('Tênis')), endsWith('2/5'));
    expect(lines.join('\n'), isNot(contains('1/1')));
  });

  test('nome comprido é cortado para não quebrar a linha', () {
    final text = appState.buildShareText(
      label: 'Maria',
      monthAbs: _september2026,
      rows: [_entry('Assinatura streaming anual', 50)],
      subtotal: 50,
      discount: 0,
    );

    expect(block(text).first, startsWith('Assinatura st…'));
  });

  test('sem desconto, só o total', () {
    final lines = block(build());

    expect(lines.join('\n'), isNot(contains('Subtotal')));
    expect(lines.join('\n'), isNot(contains('Desconto')));
    expect(lines.last, matches(RegExp('^Total +${RegExp.escape(formatMoney(200))}\$')));
  });

  test('com desconto, subtotal, desconto e total já descontado', () {
    final lines = block(build(discount: 20));

    expect(lines, contains(matches(RegExp('^Subtotal +${RegExp.escape(formatMoney(200))}\$'))));
    expect(lines, contains(matches(RegExp('^Desconto +-${RegExp.escape(formatMoney(20))}\$'))));
    expect(lines.last, matches(RegExp('^Total +${RegExp.escape(formatMoney(180))}\$')));
  });
}
