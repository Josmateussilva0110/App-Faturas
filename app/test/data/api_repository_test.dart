import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/api_exception.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/data/api_fatura_repository.dart';
import 'package:fatura/core/utils/formatters.dart';
import 'package:fatura/models/purchase.dart';

import '../support/fake_api.dart';

void main() {
  late ApiFaturaRepository repository;

  setUp(() {
    tokenManager.setTokens('access-1', 'refresh-1');
    repository = ApiFaturaRepository();
  });

  tearDown(tokenManager.clearTokens);

  const draft = Purchase(
    id: '',
    name: 'Notebook',
    amount: 4500,
    installments: 10,
    isOther: false,
    person: '',
    cardId: 'c1',
    startAbs: 24320,
  );

  test('createPurchase devolve a compra completa com o id do servidor', () async {
    api.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'success': true, 'data': {'id': 'p-novo'}}, 201),
    );

    final created = await repository.createPurchase(draft);

    // A API respondeu só com o id; o resto veio do que foi enviado.
    expect(created.id, 'p-novo');
    expect(created.name, 'Notebook');
    expect(created.installments, 10);
    expect(created.cardId, 'c1');
  });

  test('createCard devolve o cartão com o id do servidor', () async {
    final adapter = FakeAdapter(
      (_) => jsonBody({'success': true, 'data': {'id': 'c-novo'}}, 201),
    );
    api.httpClientAdapter = adapter;

    final created = await repository.createCard('Inter', 214);

    expect(created.id, 'c-novo');
    expect(created.name, 'Inter');
    expect(created.hue, 214);
    expect(adapter.calls.single.data, {'name': 'Inter', 'color_hue': 214});
  });

  test('cartão sem cor escolhida cai no matiz do nome', () async {
    api.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'success': true, 'data': {'id': 'c-novo'}}, 201),
    );

    final created = await repository.createCard('Inter', null);

    expect(created.hue, isNull);
    // A cor existe mesmo assim: quem resolve o fallback é o próprio modelo.
    expect(created.resolvedHue, hueForLabel('Inter'));
  });

  test('falha da API vira ApiException com a mensagem do servidor', () async {
    api.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'success': false, 'message': 'Cartão não encontrado.'}, 422),
    );

    expect(
      () => repository.createPurchase(draft),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Cartão não encontrado.')),
    );
  });

  test('fetchCards decodifica a lista da API', () async {
    api.httpClientAdapter = FakeAdapter(defaultHandler);

    final cards = await repository.fetchCards();

    expect(cards.single.name, 'Nubank');
  });

  test('fetchSalaries e fetchExpenses decodificam as listas da API', () async {
    api.httpClientAdapter = FakeAdapter(defaultHandler);

    final salaries = await repository.fetchSalaries();
    final expenses = await repository.fetchExpenses();

    expect(salaries.single.name, 'Mateus');
    expect(salaries.single.value, 650);
    expect(expenses.single.name, 'Internet');
    expect(expenses.single.value, 100);
  });

  test('addSalary devolve o salário com o id do servidor', () async {
    api.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'success': true, 'data': {'id': 's-novo'}}, 201),
    );

    final created = await repository.addSalary('Géssica', 1600);

    // A API respondeu só com o id; nome e valor vieram do que foi enviado.
    expect(created.id, 's-novo');
    expect(created.name, 'Géssica');
    expect(created.value, 1600);
  });

  test('addExpense devolve a despesa com o id do servidor', () async {
    api.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'success': true, 'data': {'id': 'e-novo'}}, 201),
    );

    final created = await repository.addExpense('Água', 93);

    expect(created.id, 'e-novo');
    expect(created.name, 'Água');
    expect(created.value, 93);
  });

  test('falha ao remover despesa vira ApiException', () async {
    api.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'success': false, 'message': 'Despesa não encontrada.'}, 404),
    );

    expect(
      () => repository.removeExpense('e1'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Despesa não encontrada.')),
    );
  });
}
