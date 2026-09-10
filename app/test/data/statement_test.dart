import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/data/api_fatura_repository.dart';
import 'package:fatura/data/services/statement_service.dart' as statement_api;
import 'package:fatura/models/card_model.dart';
import 'package:fatura/models/card_statement.dart';
import 'package:fatura/state/app_state.dart';

import '../support/fake_api.dart';

const _card = CardModel(id: 'c1', name: 'Nubank');

StatementCheck _check({double? billed, required double registered}) {
  return StatementCheck(
    card: _card,
    statement: billed == null
        ? null
        : CardStatement(id: 'st1', cardId: 'c1', monthAbs: 24320, amount: billed),
    registered: registered,
  );
}

void main() {
  setUp(() => tokenManager.setTokens('access-1', 'refresh-1'));
  tearDown(tokenManager.clearTokens);

  group('estados da conferência', () {
    test('sem fatura informada fica unset, sem diferença', () {
      final check = _check(registered: 1194.01);

      expect(check.status, StatementStatus.unset);
      expect(check.difference, isNull);
      expect(check.progress, isNull);
    });

    test('valor exato confere', () {
      final check = _check(billed: 1194.01, registered: 1194.01);

      expect(check.status, StatementStatus.matched);
      expect(check.difference, closeTo(0, 0.001));
    });

    test('a diferença de centavos da planilha confere', () {
      // O caso real que motivou a tolerância: -0,14 de arredondamento.
      final check = _check(billed: 1193.87, registered: 1194.01);

      expect(check.status, StatementStatus.matched);
      expect(check.difference, closeTo(-0.14, 0.001));
    });

    test('fatura maior que o registrado indica compra faltando', () {
      final check = _check(billed: 840, registered: 605);

      expect(check.status, StatementStatus.missing);
      expect(check.difference, closeTo(235, 0.001));
    });

    test('fatura menor que o registrado indica sobra, não erro', () {
      final check = _check(billed: 300, registered: 412.50);

      expect(check.status, StatementStatus.extra);
      expect(check.difference, closeTo(-112.50, 0.001));
    });
  });

  group('limites da tolerância', () {
    test('exatamente na tolerância ainda confere', () {
      expect(_check(billed: 101, registered: 100).status, StatementStatus.matched);
      expect(_check(billed: 99, registered: 100).status, StatementStatus.matched);
    });

    test('um centavo além da tolerância deixa de conferir', () {
      expect(_check(billed: 101.01, registered: 100).status, StatementStatus.missing);
      expect(_check(billed: 98.99, registered: 100).status, StatementStatus.extra);
    });
  });

  group('AppState', () {
    test('total por cartão soma só as parcelas daquele cartão', () async {
      api.httpClientAdapter = FakeAdapter(defaultHandler);
      final appState = AppState(ApiFaturaRepository());
      await appState.load();

      expect(appState.totalForCard(0, 'c1'), 165);
      // Cartão que não existe nas compras não puxa nada de outro cartão.
      expect(appState.totalForCard(0, 'c-outro'), 0);
    });

    test('a conferência do mês casa a fatura com o cartão certo', () async {
      api.httpClientAdapter = FakeAdapter(defaultHandler);
      final appState = AppState(ApiFaturaRepository());
      await appState.load();

      final check = appState.monthlyStatementChecks.single;

      expect(check.card.name, 'Nubank');
      expect(check.registered, 165);
      expect(check.billed, 165);
      expect(check.status, StatementStatus.matched);
    });

    test('cartão sem parcelas e sem fatura no mês não aparece', () async {
      api.httpClientAdapter = FakeAdapter(defaultHandler);
      final appState = AppState(ApiFaturaRepository());
      await appState.load();

      // A compra tem 10 parcelas (offsets 0 a 9) e a fatura informada é só
      // do mês corrente. Passado o parcelamento não sobra nada a conferir —
      // senão todo cartão criado apareceria em todo mês, para sempre.
      expect(appState.statementChecksFor(12), isEmpty);
      // E enquanto as parcelas correm, o cartão continua aparecendo.
      expect(appState.statementChecksFor(5), hasLength(1));
    });
  });

  group('rede', () {
    test('fromJson lê o snake_case da API', () {
      final statement = CardStatement.fromJson({
        'id': 'st1',
        'card_id': 'c1',
        'month_abs': 24320,
        'amount': 1193.87,
      });

      expect(statement.cardId, 'c1');
      expect(statement.monthAbs, 24320);
      expect(statement.amount, 1193.87);
    });

    test('saveStatement usa PUT sem id no caminho e omite o id no corpo', () async {
      final adapter = FakeAdapter(
        (_) => jsonBody({
          'success': true,
          'data': {'id': 'st-novo'},
        }, 200),
      );
      api.httpClientAdapter = adapter;

      const draft = CardStatement(id: '', cardId: 'c1', monthAbs: 24320, amount: 1193.87);
      final response = await statement_api.saveStatement(draft);

      expect(response.data, 'st-novo');
      expect(adapter.calls.single.method, 'PUT');
      expect(adapter.calls.single.path, '/statements');
      expect(adapter.calls.single.data, {
        'card_id': 'c1',
        'month_abs': 24320,
        'amount': 1193.87,
      });
    });

    test('repositório remonta a fatura com o id do servidor', () async {
      api.httpClientAdapter = FakeAdapter(
        (_) => jsonBody({
          'success': true,
          'data': {'id': 'st-novo'},
        }, 200),
      );

      final saved = await ApiFaturaRepository().saveStatement('c1', 24320, 1193.87);

      expect(saved.id, 'st-novo');
      expect(saved.cardId, 'c1');
      expect(saved.amount, 1193.87);
    });
  });
}
