import '../core/utils/formatters.dart';
import '../models/app_user.dart';
import '../models/card_model.dart';
import '../models/expense.dart';
import '../models/purchase.dart';
import '../models/salary.dart';
import 'fatura_repository.dart';

/// In-memory stand-in for a real backend. Seeded with the same sample data
/// used in the design prototype, mutated in place so the rest of the app can
/// already work against a realistic, evolving dataset.
class MockFaturaRepository implements FaturaRepository {
  MockFaturaRepository() {
    final currentAbs = currentAbsoluteMonth();
    _cards.add(const CardModel(id: 'c1', name: 'Nubank'));
    _purchases.addAll([
      Purchase(
        id: 'p1',
        name: 'Compra 1',
        amount: 165,
        installments: 10,
        isOther: false,
        person: '',
        cardId: 'c1',
        startAbs: currentAbs - 4,
      ),
      Purchase(
        id: 'p2',
        name: 'Compra 2',
        amount: 237.6,
        installments: 10,
        isOther: false,
        person: '',
        cardId: 'c1',
        startAbs: currentAbs - 1,
      ),
      Purchase(
        id: 'p3',
        name: 'Compra 3',
        amount: 500,
        installments: 3,
        isOther: false,
        person: '',
        cardId: 'c1',
        startAbs: currentAbs - 1,
      ),
      Purchase(
        id: 'p4',
        name: 'Compra 4',
        amount: 114.4,
        installments: 10,
        isOther: false,
        person: '',
        cardId: 'c1',
        startAbs: currentAbs,
      ),
      Purchase(
        id: 'p5',
        name: 'Compra 5',
        amount: 28.56,
        installments: 1,
        isOther: false,
        person: '',
        cardId: 'c1',
        startAbs: currentAbs,
      ),
    ]);
    _salaries.addAll(const [
      Salary(id: 's1', name: 'Géssica', value: 1600),
      Salary(id: 's2', name: 'Mateus', value: 650),
    ]);
    _expenses.addAll(const [
      Expense(id: 'e1', name: 'Água', value: 93),
      Expense(id: 'e2', name: 'Netflix', value: 70),
      Expense(id: 'e3', name: 'Internet', value: 100),
      Expense(id: 'e4', name: 'Lista', value: 300),
      Expense(id: 'e5', name: 'Ki preço', value: 320),
    ]);
  }

  final List<CardModel> _cards = [];
  final List<Purchase> _purchases = [];
  final List<Salary> _salaries = [];
  final List<Expense> _expenses = [];
  double? _spendingLimit;
  final _currentUser = const AppUser(id: 'u1', name: 'Você', email: 'voce@email.com');

  int _nextId = 1000;
  String _generateId(String prefix) => '$prefix${_nextId++}';

  /// A tiny artificial delay so the UI's loading states are exercised now,
  /// the same way they will be once these calls hit a real network.
  Future<void> _simulateLatency() => Future.delayed(const Duration(milliseconds: 120));

  @override
  Future<List<CardModel>> fetchCards() async {
    await _simulateLatency();
    return List.unmodifiable(_cards);
  }

  @override
  Future<CardModel> createCard(String name) async {
    await _simulateLatency();
    final card = CardModel(id: _generateId('c'), name: name);
    _cards.add(card);
    return card;
  }

  @override
  Future<CardModel> renameCard(String id, String name) async {
    await _simulateLatency();
    final index = _cards.indexWhere((c) => c.id == id);
    final renamed = _cards[index].copyWith(name: name);
    _cards[index] = renamed;
    return renamed;
  }

  @override
  Future<void> deleteCard(String id) async {
    await _simulateLatency();
    _cards.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<Purchase>> fetchPurchases() async {
    await _simulateLatency();
    return List.unmodifiable(_purchases);
  }

  @override
  Future<Purchase> createPurchase(Purchase draft) async {
    await _simulateLatency();
    final purchase = draft.copyWith();
    final withId = Purchase(
      id: _generateId('p'),
      name: purchase.name,
      amount: purchase.amount,
      installments: purchase.installments,
      isOther: purchase.isOther,
      person: purchase.person,
      cardId: purchase.cardId,
      startAbs: purchase.startAbs,
    );
    _purchases.add(withId);
    return withId;
  }

  @override
  Future<Purchase> updatePurchase(Purchase purchase) async {
    await _simulateLatency();
    final index = _purchases.indexWhere((p) => p.id == purchase.id);
    _purchases[index] = purchase;
    return purchase;
  }

  @override
  Future<void> deletePurchase(String id) async {
    await _simulateLatency();
    _purchases.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<Salary>> fetchSalaries() async {
    await _simulateLatency();
    return List.unmodifiable(_salaries);
  }

  @override
  Future<Salary> addSalary(String name, double value) async {
    await _simulateLatency();
    final salary = Salary(id: _generateId('s'), name: name, value: value);
    _salaries.add(salary);
    return salary;
  }

  @override
  Future<void> removeSalary(String id) async {
    await _simulateLatency();
    _salaries.removeWhere((s) => s.id == id);
  }

  @override
  Future<List<Expense>> fetchExpenses() async {
    await _simulateLatency();
    return List.unmodifiable(_expenses);
  }

  @override
  Future<Expense> addExpense(String name, double value) async {
    await _simulateLatency();
    final expense = Expense(id: _generateId('e'), name: name, value: value);
    _expenses.add(expense);
    return expense;
  }

  @override
  Future<void> removeExpense(String id) async {
    await _simulateLatency();
    _expenses.removeWhere((e) => e.id == id);
  }

  @override
  Future<double?> fetchSpendingLimit() async {
    await _simulateLatency();
    return _spendingLimit;
  }

  @override
  Future<void> setSpendingLimit(double? limit) async {
    await _simulateLatency();
    _spendingLimit = limit;
  }

  @override
  Future<AppUser> fetchCurrentUser() async {
    await _simulateLatency();
    return _currentUser;
  }
}
