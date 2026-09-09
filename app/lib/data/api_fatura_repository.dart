import '../models/card_model.dart';
import '../models/expense.dart';
import '../models/purchase.dart';
import '../models/salary.dart';
import 'api/api_exception.dart';
import 'api/api_response.dart';
import 'fatura_repository.dart';
import 'mock_fatura_repository.dart';
import 'services/card_service.dart' as card_api;
import 'services/purchase_service.dart' as purchase_api;

/// Repositório que fala com o backend.
///
/// Hoje só cartões e compras têm endpoint. Salários, despesas e o limite de
/// gastos continuam em memória, delegados a [_local] — quando as rotas
/// existirem, é só trocar cada método aqui e apagar a delegação.
class ApiFaturaRepository implements FaturaRepository {
  ApiFaturaRepository({FaturaRepository? local}) : _local = local ?? MockFaturaRepository();

  final FaturaRepository _local;

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
  Future<CardModel> createCard(String name) async {
    final draft = CardModel(id: '', name: name);
    final id = _unwrap(await card_api.createCard(draft));
    // A API responde só com o id; o resto já está no draft.
    return draft.withId(id);
  }

  @override
  Future<CardModel> renameCard(String id, String name) async {
    final card = CardModel(id: id, name: name);
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

  // ── Ainda sem endpoint no backend ────────────────────────────────────
  @override
  Future<List<Salary>> fetchSalaries() => _local.fetchSalaries();

  @override
  Future<Salary> addSalary(String name, double value) => _local.addSalary(name, value);

  @override
  Future<void> removeSalary(String id) => _local.removeSalary(id);

  @override
  Future<List<Expense>> fetchExpenses() => _local.fetchExpenses();

  @override
  Future<Expense> addExpense(String name, double value) => _local.addExpense(name, value);

  @override
  Future<void> removeExpense(String id) => _local.removeExpense(id);

  @override
  Future<double?> fetchSpendingLimit() => _local.fetchSpendingLimit();

  @override
  Future<void> setSpendingLimit(double? limit) => _local.setSpendingLimit(limit);
}
