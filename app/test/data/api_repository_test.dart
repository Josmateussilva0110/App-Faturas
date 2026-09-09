import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/api_exception.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/data/api_fatura_repository.dart';
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
    api.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'success': true, 'data': {'id': 'c-novo'}}, 201),
    );

    final created = await repository.createCard('Inter');

    expect(created.id, 'c-novo');
    expect(created.name, 'Inter');
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

  test('salários seguem locais enquanto não houver endpoint', () async {
    api.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'success': false, 'message': 'não deveria ser chamado'}, 500),
    );

    // Não passa pela rede: delegado ao repositório em memória.
    final salaries = await repository.fetchSalaries();

    expect(salaries, isNotEmpty);
  });
}
