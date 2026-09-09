import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/data/services/purchase_service.dart';
import 'package:fatura/models/purchase.dart';

import '../support/fake_api.dart';

Map<String, dynamic> purchaseJson({String id = 'p1', Object? cardId = 'c1'}) {
  return {
    'id': id,
    'card_id': cardId,
    'name': 'Notebook',
    'amount': 4500.5,
    'installments': 10,
    'is_other': true,
    'person': 'Ana',
    'start_abs': 24320,
  };
}

void main() {
  setUp(() => tokenManager.setTokens('access-1', 'refresh-1'));
  tearDown(tokenManager.clearTokens);

  test('fromJson lê o snake_case da API nos campos camelCase do Dart', () {
    final purchase = Purchase.fromJson(purchaseJson());

    expect(purchase.cardId, 'c1');
    expect(purchase.isOther, isTrue);
    expect(purchase.startAbs, 24320);
    expect(purchase.amount, 4500.5);
    expect(purchase.person, 'Ana');
  });

  test('cartão removido (card_id nulo) vira string vazia', () {
    final purchase = Purchase.fromJson(purchaseJson(cardId: null));

    expect(purchase.cardId, isEmpty);
  });

  test('toJson escreve em snake_case e não manda o id', () {
    final body = Purchase.fromJson(purchaseJson()).toJson();

    expect(body.keys, containsAll(['card_id', 'is_other', 'start_abs']));
    expect(body.containsKey('id'), isFalse, reason: 'quem define o id é o servidor');
    expect(body['is_other'], isTrue);
  });

  test('createPurchase envia snake_case e devolve o id do servidor', () async {
    final adapter = FakeAdapter(
      (_) => jsonBody({'success': true, 'data': {'id': 'gerado-no-servidor'}}, 201),
    );
    api.httpClientAdapter = adapter;

    final draft = Purchase.fromJson(purchaseJson(id: ''));
    final response = await createPurchase(draft);

    expect(response.success, isTrue);
    expect(response.data, 'gerado-no-servidor');

    // O dio guarda o corpo como objeto; a serialização acontece depois.
    final enviado = adapter.calls.single.data as Map<String, dynamic>;
    expect(enviado['start_abs'], 24320);
    expect(enviado['card_id'], 'c1');

    // A resposta traz só o id: o objeto completo é remontado localmente.
    final criado = draft.withId(response.data!);
    expect(criado.id, 'gerado-no-servidor');
    expect(criado.name, 'Notebook');
    expect(criado.startAbs, 24320);
  });

  test('fetchPurchases decodifica a lista', () async {
    api.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({
        'success': true,
        'data': [purchaseJson(id: 'p1'), purchaseJson(id: 'p2', cardId: null)],
      }, 200),
    );

    final response = await fetchPurchases();

    expect(response.success, isTrue);
    expect(response.data!.map((p) => p.id), ['p1', 'p2']);
    expect(response.data!.last.cardId, isEmpty);
  });
}
