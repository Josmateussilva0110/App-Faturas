import '../models/app_user.dart';
import '../models/card_model.dart';
import '../models/expense.dart';
import '../models/purchase.dart';
import '../models/salary.dart';

/// Data source contract for the whole app.
///
/// [MockFaturaRepository] is the only implementation today. When a backend
/// exists, add e.g. `HttpFaturaRepository implements FaturaRepository` and
/// swap the single instantiation in `main.dart` — nothing else needs to
/// change, since [AppState] only ever talks to this interface.
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
  Future<void> removeSalary(String id);

  Future<List<Expense>> fetchExpenses();
  Future<Expense> addExpense(String name, double value);
  Future<void> removeExpense(String id);

  /// The user's monthly spending goal for their own card purchases (`null`
  /// when none is set). Purchases made by other people don't count toward
  /// it, so this is intentionally separate from any per-card credit limit.
  Future<double?> fetchSpendingLimit();
  Future<void> setSpendingLimit(double? limit);

  /// The logged-in user, shown on the Profile screen.
  Future<AppUser> fetchCurrentUser();
}
