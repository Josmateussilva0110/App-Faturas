import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/data/api_fatura_repository.dart';
import 'package:fatura/state/app_state.dart';

import '../support/fake_api.dart';

Future<AppState> _loadWith({
  required List<Map<String, dynamic>> salaries,
  required List<Map<String, dynamic>> expenses,
}) async {
  api.httpClientAdapter = FakeAdapter((options) {
    // Sem compras: o crédito no cartão não entra na conta destes testes.
    if (options.path.contains('/purchases')) {
      return jsonBody({'success': true, 'data': <Map<String, dynamic>>[]}, 200);
    }
    if (options.path.contains('/salaries')) {
      return jsonBody({'success': true, 'data': salaries}, 200);
    }
    if (options.path.contains('/expenses')) {
      return jsonBody({'success': true, 'data': expenses}, 200);
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

  test('a porcentagem é o que sobra sobre o total de salários', () async {
    final appState = await _loadWith(
      salaries: [
        {'id': 's1', 'name': 'Salário', 'amount': 4000},
      ],
      expenses: [
        {'id': 'e1', 'name': 'Aluguel', 'amount': 3000},
      ],
    );

    expect(appState.guardarFor(0), 1000);
    expect(appState.savingsRateFor(0), 0.25);
  });

  test('despesa acima do salário dá porcentagem negativa', () async {
    final appState = await _loadWith(
      salaries: [
        {'id': 's1', 'name': 'Salário', 'amount': 1000},
      ],
      expenses: [
        {'id': 'e1', 'name': 'Aluguel', 'amount': 1500},
      ],
    );

    expect(appState.savingsRateFor(0), lessThan(0));
  });

  test('sem salário não há porcentagem', () async {
    final appState = await _loadWith(salaries: [], expenses: []);

    expect(appState.savingsRateFor(0), isNull);
  });
}
