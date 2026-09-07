import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../data/fatura_repository.dart';
import '../models/card_model.dart';
import '../models/expense.dart';
import '../models/purchase.dart';
import '../models/salary.dart';

/// A purchase paired with its installment status as of some target month.
typedef PurchaseEntry = ({Purchase purchase, PurchaseStatus status});

class PersonSummary {
  const PersonSummary({required this.label, required this.total});
  final String label;
  final double total;
}

class ExpenseRow {
  const ExpenseRow({required this.expense, required this.runningBalance});
  final Expense expense;
  final double runningBalance;
}

/// Single source of truth for the whole app: owns the data fetched from
/// [FaturaRepository] and every derived computation the screens need (active
/// purchases per month, totals per person, the deposit/expense running
/// balance, share text, ...). Screens read it via `context.watch<AppState>()`
/// and call its methods instead of touching the repository directly.
class AppState extends ChangeNotifier {
  AppState(this._repository);

  final FaturaRepository _repository;
  final int currentAbs = currentAbsoluteMonth();

  bool isLoading = true;
  ThemeMode themeMode = ThemeMode.light;
  int monthOffset = 0;

  List<CardModel> cards = [];
  List<Purchase> purchases = [];
  List<Salary> salaries = [];
  List<Expense> expenses = [];

  Future<void> load() async {
    final results = await Future.wait([
      _repository.fetchCards(),
      _repository.fetchPurchases(),
      _repository.fetchSalaries(),
      _repository.fetchExpenses(),
    ]);
    cards = results[0] as List<CardModel>;
    purchases = results[1] as List<Purchase>;
    salaries = results[2] as List<Salary>;
    expenses = results[3] as List<Expense>;
    isLoading = false;
    notifyListeners();
  }

  // ── Theme ────────────────────────────────────────────────────────────
  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  // ── Month navigation (Monthly screen) ───────────────────────────────
  void changeMonth(int delta) {
    monthOffset += delta;
    notifyListeners();
  }

  // ── Cards ────────────────────────────────────────────────────────────
  String cardName(String cardId) {
    for (final card in cards) {
      if (card.id == cardId) return card.name;
    }
    return 'Cartão removido';
  }

  Future<void> addCard(String name) async {
    final created = await _repository.createCard(name);
    cards = [...cards, created];
    notifyListeners();
  }

  Future<void> renameCard(String id, String name) async {
    final updated = await _repository.renameCard(id, name);
    cards = [for (final c in cards) if (c.id == id) updated else c];
    notifyListeners();
  }

  Future<void> deleteCard(String id) async {
    await _repository.deleteCard(id);
    cards = cards.where((c) => c.id != id).toList();
    notifyListeners();
  }

  // ── Purchases ────────────────────────────────────────────────────────
  List<PurchaseEntry> activePurchases(int offset) {
    final target = currentAbs + offset;
    final entries = <PurchaseEntry>[
      for (final p in purchases) (purchase: p, status: PurchaseStatus.at(p, target)),
    ].where((e) => e.status.active).toList()
      ..sort((a, b) => b.purchase.startAbs.compareTo(a.purchase.startAbs));
    return entries;
  }

  double totalFor(int offset) =>
      activePurchases(offset).fold(0.0, (sum, e) => sum + e.purchase.amount);

  /// This month's active purchases and total — what the Home screen shows.
  List<PurchaseEntry> get homeEntries => activePurchases(0);
  double get homeTotal => totalFor(0);

  /// The Monthly screen's active purchases and total, for [monthOffset].
  List<PurchaseEntry> get monthlyEntries => activePurchases(monthOffset);
  double get monthlyTotal => totalFor(monthOffset);

  Future<void> addPurchase(Purchase draft) async {
    final created = await _repository.createPurchase(draft);
    purchases = [...purchases, created];
    notifyListeners();
  }

  Future<void> updatePurchase(Purchase purchase) async {
    final updated = await _repository.updatePurchase(purchase);
    purchases = [for (final p in purchases) if (p.id == updated.id) updated else p];
    notifyListeners();
  }

  Future<void> deletePurchase(String id) async {
    await _repository.deletePurchase(id);
    purchases = purchases.where((p) => p.id != id).toList();
    notifyListeners();
  }

  // ── People ───────────────────────────────────────────────────────────
  List<PersonSummary> get personSummaries {
    final totals = <String, double>{};
    for (final e in homeEntries) {
      totals[e.purchase.personLabel] = (totals[e.purchase.personLabel] ?? 0) + e.purchase.amount;
    }
    final list = totals.entries.map((e) => PersonSummary(label: e.key, total: e.value)).toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  List<PurchaseEntry> transactionsForPerson(String label) =>
      homeEntries.where((e) => e.purchase.personLabel == label).toList();

  double get grandTotal => homeTotal;

  // ── Deposit (salaries / expenses) ───────────────────────────────────
  double get totalSalaries => salaries.fold(0.0, (sum, s) => sum + s.value);
  double get afterCredit => totalSalaries - grandTotal;

  List<ExpenseRow> get expenseRows {
    final rows = <ExpenseRow>[];
    var running = afterCredit;
    for (final expense in expenses) {
      running -= expense.value;
      rows.add(ExpenseRow(expense: expense, runningBalance: running));
    }
    return rows;
  }

  double get guardar => expenseRows.isEmpty ? afterCredit : expenseRows.last.runningBalance;

  Future<void> addSalary(String name, double value) async {
    final created = await _repository.addSalary(name, value);
    salaries = [...salaries, created];
    notifyListeners();
  }

  Future<void> removeSalary(String id) async {
    await _repository.removeSalary(id);
    salaries = salaries.where((s) => s.id != id).toList();
    notifyListeners();
  }

  Future<void> addExpense(String name, double value) async {
    final created = await _repository.addExpense(name, value);
    expenses = [...expenses, created];
    notifyListeners();
  }

  Future<void> removeExpense(String id) async {
    await _repository.removeExpense(id);
    expenses = expenses.where((e) => e.id != id).toList();
    notifyListeners();
  }

  // ── Share text ───────────────────────────────────────────────────────
  String buildShareText({
    required String label,
    required List<PurchaseEntry> rows,
    required double subtotal,
    required double discount,
  }) {
    String pad2(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    final dateStr = '${pad2(now.day)}/${pad2(now.month)}/${now.year}';
    final timeStr = '${pad2(now.hour)}:${pad2(now.minute)}';
    final mod = currentAbs % 12;
    final year = (currentAbs - mod) ~/ 12;
    final due = '10/${pad2(mod + 1)}/$year';

    final lines = [
      for (final e in rows)
        '  ▸ ${formatMoney(e.purchase.amount)}  (${e.status.installmentNumber}/${e.purchase.installments})',
    ];
    const sep = '─────────────────────';
    final totalLines = discount > 0
        ? [
            sep,
            '🧾 Subtotal:   ${formatMoney(subtotal)}',
            '🏷 Desconto:  - ${formatMoney(discount)}',
            sep,
            '💰 Total:     ${formatMoney(subtotal - discount)}',
          ]
        : [sep, '💰 Total:     ${formatMoney(subtotal)}'];

    return [
      '💳 FATURA MENSAL',
      '─────────────────────────────────',
      '👤 $label',
      '🗓 Gerada em $dateStr às $timeStr',
      '📅 Vencimento: $due',
      '',
      '📋 Contas do mês:',
      '',
      ...lines,
      '',
      ...totalLines,
    ].join('\n');
  }
}
