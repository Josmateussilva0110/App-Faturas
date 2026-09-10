import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/data/services/expense_service.dart' as expense_api;
import 'package:fatura/data/services/salary_service.dart' as salary_api;
import 'package:fatura/models/expense.dart';
import 'package:fatura/models/salary.dart';
import 'package:fatura/models/user_profile.dart';

import '../support/fake_api.dart';

void main() {
  setUp(() => tokenManager.setTokens('access-1', 'refresh-1'));
  tearDown(tokenManager.clearTokens);

  test('fromJson traduz `amount` da API para o `value` do app', () {
    final salary = Salary.fromJson({'id': 's1', 'name': 'Mateus', 'amount': 650.5});
    final expense = Expense.fromJson({'id': 'e1', 'name': 'Água', 'amount': 93.0});

    expect(salary.value, 650.5);
    expect(expense.value, 93);
  });

  test('campo ausente não quebra o parse', () {
    final salary = Salary.fromJson({'id': 's1', 'name': 'Mateus'});

    expect(salary.value, 0);
  });

  test('toJson manda `amount` e omite o id', () {
    const salary = Salary(id: 's1', name: 'Mateus', value: 650);

    expect(salary.toJson(), {'name': 'Mateus', 'amount': 650.0});
  });

  test('createSalary envia nome e valor, e devolve o id do servidor', () async {
    final adapter = FakeAdapter(
      (_) => jsonBody({
        'success': true,
        'data': {'id': 's-novo'},
      }, 201),
    );
    api.httpClientAdapter = adapter;

    const draft = Salary(id: '', name: 'Géssica', value: 1600);
    final response = await salary_api.createSalary(draft);

    expect(response.data, 's-novo');
    expect(adapter.calls.single.data, {'name': 'Géssica', 'amount': 1600.0});
    expect(adapter.calls.single.path, '/salaries');
  });

  test('updateExpense usa PUT no id da despesa', () async {
    final adapter = FakeAdapter(
      (_) => jsonBody({
        'success': true,
        'data': {'id': 'e1'},
      }, 200),
    );
    api.httpClientAdapter = adapter;

    const expense = Expense(id: 'e1', name: 'Internet', value: 120);
    await expense_api.updateExpense(expense);

    expect(adapter.calls.single.method, 'PUT');
    expect(adapter.calls.single.path, '/expenses/e1');
  });

  test('perfil lê a meta de gastos, e a ausência dela vira null', () {
    final withLimit = UserProfile.fromJson(fakeProfile(spendingLimit: 1500));
    final without = UserProfile.fromJson(fakeProfile());

    expect(withLimit.spendingLimit, 1500);
    expect(without.spendingLimit, isNull);
  });
}
