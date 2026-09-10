import '../models/card_model.dart';
import '../models/card_statement.dart';
import '../models/expense.dart';
import '../models/purchase.dart';
import '../models/salary.dart';
import 'api/api_exception.dart';
import 'api/api_response.dart';
import 'fatura_repository.dart';
import 'services/card_service.dart' as card_api;
import 'services/expense_service.dart' as expense_api;
import 'services/profile_service.dart' as profile_api;
import 'services/purchase_service.dart' as purchase_api;
import 'services/salary_service.dart' as salary_api;
import 'services/statement_service.dart' as statement_api;

/// Repositório que fala com o backend. Todo o contrato de
/// [FaturaRepository] tem endpoint — nada aqui é servido de memória.
class ApiFaturaRepository implements FaturaRepository {
  /// Converte o envelope em valor, ou lança com a mensagem do servidor.
  T _unwrap<T>(ApiResponse<T> response) {
    if (!response.success || response.data == null) {
      throw ApiException(response.message);
    }
    return response.data as T;
  }

  void _ensureOk(ApiResponse<Object?> response) {
    if (!response.success) throw ApiException(response.message);
  }

  // ── Cartões ──────────────────────────────────────────────────────────
  @override
  Future<List<CardModel>> fetchCards() async {
    return _unwrap(await card_api.fetchCards());
  }

  @override
  Future<CardModel> createCard(String name, int? hue) async {
    final draft = CardModel(id: '', name: name, hue: hue);
    final id = _unwrap(await card_api.createCard(draft));
    // A API responde só com o id; o resto já está no draft.
    return draft.withId(id);
  }

  @override
  Future<CardModel> updateCard(String id, String name, int? hue) async {
    final card = CardModel(id: id, name: name, hue: hue);
    _unwrap(await card_api.updateCard(card));
    return card;
  }

  @override
  Future<void> deleteCard(String id) async {
    _ensureOk(await card_api.deleteCard(id));
  }

  // ── Compras ──────────────────────────────────────────────────────────
  @override
  Future<List<Purchase>> fetchPurchases() async {
    return _unwrap(await purchase_api.fetchPurchases());
  }

  @override
  Future<Purchase> createPurchase(Purchase draft) async {
    final id = _unwrap(await purchase_api.createPurchase(draft));
    return draft.withId(id);
  }

  @override
  Future<Purchase> updatePurchase(Purchase purchase) async {
    _unwrap(await purchase_api.updatePurchase(purchase));
    return purchase;
  }

  @override
  Future<void> deletePurchase(String id) async {
    _ensureOk(await purchase_api.deletePurchase(id));
  }

  // ── Salários ─────────────────────────────────────────────────────────
  @override
  Future<List<Salary>> fetchSalaries() async {
    return _unwrap(await salary_api.fetchSalaries());
  }

  @override
  Future<Salary> addSalary(String name, double value) async {
    final draft = Salary(id: '', name: name, value: value);
    final id = _unwrap(await salary_api.createSalary(draft));
    // A API responde só com o id; o resto já está no draft.
    return draft.withId(id);
  }

  @override
  Future<Salary> updateSalary(String id, String name, double value) async {
    final salary = Salary(id: id, name: name, value: value);
    _unwrap(await salary_api.updateSalary(salary));
    return salary;
  }

  @override
  Future<void> removeSalary(String id) async {
    _ensureOk(await salary_api.deleteSalary(id));
  }

  // ── Despesas ─────────────────────────────────────────────────────────
  @override
  Future<List<Expense>> fetchExpenses() async {
    return _unwrap(await expense_api.fetchExpenses());
  }

  @override
  Future<Expense> addExpense(String name, double value) async {
    final draft = Expense(id: '', name: name, value: value);
    final id = _unwrap(await expense_api.createExpense(draft));
    return draft.withId(id);
  }

  @override
  Future<Expense> updateExpense(String id, String name, double value) async {
    final expense = Expense(id: id, name: name, value: value);
    _unwrap(await expense_api.updateExpense(expense));
    return expense;
  }

  @override
  Future<void> removeExpense(String id) async {
    _ensureOk(await expense_api.deleteExpense(id));
  }

  // ── Faturas (conferência) ────────────────────────────────────────────
  @override
  Future<List<CardStatement>> fetchStatements() async {
    return _unwrap(await statement_api.fetchStatements());
  }

  @override
  Future<CardStatement> saveStatement(String cardId, int monthAbs, double amount) async {
    final draft = CardStatement(id: '', cardId: cardId, monthAbs: monthAbs, amount: amount);
    final id = _unwrap(await statement_api.saveStatement(draft));
    // A API responde só com o id, seja criação ou atualização.
    return draft.withId(id);
  }

  @override
  Future<void> removeStatement(String id) async {
    _ensureOk(await statement_api.deleteStatement(id));
  }

  // ── Limite de gastos ─────────────────────────────────────────────────
  // Só a escrita: a leitura vem junto de `GET /profile`.
  @override
  Future<void> setSpendingLimit(double? limit) async {
    _ensureOk(await profile_api.updateSpendingLimit(limit));
  }
}
