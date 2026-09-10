import '../models/card_model.dart';
import '../models/expense.dart';
import '../models/purchase.dart';
import '../models/salary.dart';

/// Data source contract for the whole app.
///
/// [ApiFaturaRepository] is the only implementation. Swapping in another one
/// (a fake for tests, an offline cache) is the single instantiation in
/// `main.dart` — nothing else needs to change, since [AppState] only ever
/// talks to this interface.
abstract class FaturaRepository {
  Future<List<CardModel>> fetchCards();
  Future<CardModel> createCard(String name);
  Future<CardModel> renameCard(String id, String name);
  Future<void> deleteCard(String id);

  Future<List<Purchase>> fetchPurchases();
  Future<Purchase> createPurchase(Purchase draft);
  Future<Purchase> updatePurchase(Purchase purchase);
  Future<void> deletePurchase(String id);

  Future<List<Salary>> fetchSalaries();
  Future<Salary> addSalary(String name, double value);
  Future<Salary> updateSalary(String id, String name, double value);
  Future<void> removeSalary(String id);

  Future<List<Expense>> fetchExpenses();
  Future<Expense> addExpense(String name, double value);
  Future<Expense> updateExpense(String id, String name, double value);
  Future<void> removeExpense(String id);

  /// Grava a meta mensal de gastos do usuário com o próprio cartão (`null`
  /// limpa a meta). Compras de outras pessoas não contam para ela, então
  /// isso é de propósito separado do limite de crédito de cada cartão.
  ///
  /// Não há `fetchSpendingLimit`: o valor atual chega junto de `GET
  /// /profile`, que [AppState.load] já dispara — buscá-lo à parte custaria
  /// um segundo round trip idêntico em todo boot do app.
  Future<void> setSpendingLimit(double? limit);
}
