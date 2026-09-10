import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/data/api_fatura_repository.dart';
import 'package:fatura/state/app_state.dart';

import '../support/fake_api.dart';

final _thisMonth = DateTime.now().year * 12 + DateTime.now().month - 1;

Map<String, dynamic> _purchase(String id, String name, double amount, {int? startAbs}) {
  return {
    'id': id,
    'card_id': 'c1',
    'name': name,
    'amount': amount,
    'installments': 10,
    'is_other': false,
    'person': '',
    'start_abs': startAbs ?? _thisMonth,
  };
}

Future<AppState> _loadWith(List<Map<String, dynamic>> purchases) async {
  api.httpClientAdapter = FakeAdapter((options) {
    if (options.path.contains('/purchases')) {
      return jsonBody({'success': true, 'data': purchases}, 200);
    }
    return defaultHandler(options);
  });

  final appState = AppState(ApiFaturaRepository());
  await appState.load();
  return appState;
}

void main() {
  setUp(() => tokenManager.setTokens('access-1', 'refresh-1'));
  tearDown(tokenManager.clearTokens);

  test('a lista vem da maior parcela para a menor', () async {
    final appState = await _loadWith([
      _purchase('p1', 'Barata', 28.56),
      _purchase('p2', 'Cara', 500),
      _purchase('p3', 'Média', 165),
    ]);

    expect(
      appState.homeEntries.map((e) => e.purchase.name),
      ['Cara', 'Média', 'Barata'],
    );
  });

  test('valores iguais têm ordem estável, e não sorteada a cada rebuild', () async {
    final appState = await _loadWith([
      _purchase('p1', 'Zebra', 100, startAbs: _thisMonth - 2),
      _purchase('p2', 'Abacate', 100, startAbs: _thisMonth),
      _purchase('p3', 'Caju', 100, startAbs: _thisMonth),
    ]);

    // Desempate: mês mais recente primeiro, depois nome. Sem isso o sort do
    // Dart pode devolver ordens diferentes para a mesma lista.
    final names = appState.homeEntries.map((e) => e.purchase.name).toList();
    expect(names, ['Abacate', 'Caju', 'Zebra']);
    expect(appState.homeEntries.map((e) => e.purchase.name), names);
  });

  test('a ordem vale também para os meses seguintes e para a aba Pessoas', () async {
    final appState = await _loadWith([
      _purchase('p1', 'Barata', 28.56),
      _purchase('p2', 'Cara', 500),
    ]);

    expect(appState.activePurchases(3).map((e) => e.purchase.name), ['Cara', 'Barata']);
    expect(
      appState.transactionsForPerson('Nós').map((e) => e.purchase.name),
      ['Cara', 'Barata'],
    );
  });
}
