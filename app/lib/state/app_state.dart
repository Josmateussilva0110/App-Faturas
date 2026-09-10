import 'package:flutter/material.dart';

import '../core/settings/settings_storage.dart';
import '../core/toast/app_toast.dart';
import '../core/utils/formatters.dart';
import '../data/api/api_exception.dart';
import '../data/api/auth_storage.dart';
import '../data/fatura_repository.dart';
import '../data/services/profile_service.dart';
import '../models/app_user.dart';
import '../models/card_model.dart';
import '../models/card_statement.dart';
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

/// How a card's registered installments compare to the bill the user typed.
enum StatementStatus {
  /// No bill informed for this card in this month yet.
  unset,

  /// Within [kStatementTolerance] of the bill.
  matched,

  /// The bill is higher: purchases are missing from the app.
  missing,

  /// The bill is lower: the bill hasn't closed yet, or something is
  /// registered twice.
  extra,
}

/// Diferenças de centavos são a regra, não a exceção: arredondamento do
/// banco, IOF e conversão de moeda produzem alguns centavos de sobra quase
/// todo mês. Sem uma faixa de tolerância a conferência apontaria erro sempre,
/// e o alerta perderia o sentido.
const double kStatementTolerance = 1.0;

/// One card's reconciliation for a given month: what the bill says, what the
/// app has registered, and how far apart they are.
class StatementCheck {
  const StatementCheck({
    required this.card,
    required this.statement,
    required this.registered,
  });

  final CardModel card;

  /// The bill the user informed, or null when they haven't yet.
  final CardStatement? statement;

  /// Sum of the installments falling on this month for this card —
  /// everyone's, since the bank charges the whole card together.
  final double registered;

  double? get billed => statement?.amount;

  /// Bill minus registered. Positive means the app is missing purchases.
  /// Null while no bill was informed.
  double? get difference {
    final bill = billed;
    return bill == null ? null : bill - registered;
  }

  StatementStatus get status {
    final diff = difference;
    if (diff == null) return StatementStatus.unset;
    if (diff.abs() <= kStatementTolerance) return StatementStatus.matched;
    return diff > 0 ? StatementStatus.missing : StatementStatus.extra;
  }

  /// Fraction of the bill already registered, for the progress bar. Null
  /// without a bill to measure against; can exceed 1 when [extra].
  double? get progress {
    final bill = billed;
    if (bill == null || bill <= 0) return null;
    return registered / bill;
  }
}

/// Single source of truth for the whole app: owns the data fetched from
/// [FaturaRepository] and every derived computation the screens need (active
/// purchases per month, totals per person, the deposit/expense running
/// balance, share text, ...). Screens read it via `context.watch<AppState>()`
/// and call its methods instead of touching the repository directly.
class AppState extends ChangeNotifier {
  AppState(this._repository, {ThemeMode? themeMode})
      : themeMode = themeMode ?? ThemeMode.system;

  final FaturaRepository _repository;
  final int currentAbs = currentAbsoluteMonth();

  bool isLoading = true;

  /// A mensagem da última carga que falhou, ou null quando os dados na tela
  /// vieram do servidor. É o que permite a UI dizer "não consegui buscar" em
  /// vez de "não há nada" — sem isto, falha de rede e mês vazio produzem
  /// exatamente a mesma tela.
  String? loadError;
  /// Segue o sistema até o usuário escolher outra coisa. A escolha é lida
  /// antes do `runApp` (ver `main.dart`), para o app não abrir num tema e
  /// piscar para outro.
  ThemeMode themeMode;
  int monthOffset = 0;

  List<CardModel> cards = [];
  List<Purchase> purchases = [];
  List<Salary> salaries = [];
  List<Expense> expenses = [];
  List<CardStatement> statements = [];

  /// The user's monthly spending goal, or `null` when none is set.
  double? spendingLimit;

  /// The signed-in account, from the backend. Populated by [load]; only read
  /// once [isLoading] is false, since every screen that shows it sits behind
  /// that gate.
  late AppUser currentUser;

  /// Loads everything the screens need. Call it once a session is active —
  /// [currentUser] comes from an authenticated endpoint.
  ///
  /// The profile request goes in the same batch as the repository reads, and
  /// carries [spendingLimit] with it: the goal lives on the profile row, so
  /// fetching it apart would mean a second identical round trip on every
  /// app launch.
  Future<void> load() async {
    try {
      final results = await Future.wait([
        _repository.fetchCards(),
        _repository.fetchPurchases(),
        _repository.fetchSalaries(),
        _repository.fetchExpenses(),
        _repository.fetchStatements(),
        _fetchCurrentUser(),
      ]);
      cards = results[0] as List<CardModel>;
      purchases = results[1] as List<Purchase>;
      salaries = results[2] as List<Salary>;
      expenses = results[3] as List<Expense>;
      statements = results[4] as List<CardStatement>;
      final profile = results[5] as ({AppUser user, double? spendingLimit});
      currentUser = profile.user;
      spendingLimit = profile.spendingLimit;
      loadError = null;
    } on ApiException catch (error) {
      // O app abre vazio em vez de travar na splash: o usuário vê o motivo
      // e pode tentar de novo sem ser jogado para a tela de login.
      AppToast.error(error.message);
      loadError = error.message;
      currentUser = (await _fetchCurrentUser()).user;
    }

    isLoading = false;
    notifyListeners();
  }

  /// Executa uma escrita na API. Devolve null quando ela falhou, já tendo
  /// avisado o usuário — o estado local não muda, para não divergir do
  /// servidor e mostrar na tela algo que não foi salvo.
  Future<T?> _guard<T>(Future<T> Function() write) async {
    try {
      return await write();
    } on ApiException catch (error) {
      AppToast.error(error.message);
      return null;
    }
  }

  /// The account behind `GET /profile`, plus the spending goal stored on the
  /// same row. When that call fails (offline, server down) we fall back to
  /// what the stored session already knows, so the app still opens instead
  /// of dying on an unset `late` field — with no goal, since the session
  /// doesn't carry one.
  Future<({AppUser user, double? spendingLimit})> _fetchCurrentUser() async {
    final response = await getProfile();
    final profile = response.data;

    if (response.success && profile != null) {
      return (
        user: AppUser(
          id: profile.id,
          // The backend allows a blank username; fall back to the email so
          // the profile never shows an empty name.
          name: profile.username.isNotEmpty ? profile.username : profile.email,
          email: profile.email,
        ),
        spendingLimit: profile.spendingLimit,
      );
    }

    final stored = await authStorage.read();
    final email = stored?.user.email ?? '';
    return (
      user: AppUser(id: stored?.user.id ?? '', name: email, email: email),
      spendingLimit: null,
    );
  }

  /// Drops everything tied to the account that just signed out, so the next
  /// login doesn't briefly show the previous user's data.
  void reset() {
    isLoading = true;
    loadError = null;
    cards = [];
    purchases = [];
    salaries = [];
    expenses = [];
    statements = [];
    spendingLimit = null;
    monthOffset = 0;
    notifyListeners();
  }

  // ── Spending goal ────────────────────────────────────────────────────
  Future<void> setSpendingLimit(double? limit) async {
    final saved = await _guard(() async {
      await _repository.setSpendingLimit(limit);
      return true;
    });
    if (saved == null) return;

    spendingLimit = limit;
    notifyListeners();
  }

  // ── Theme ────────────────────────────────────────────────────────────
  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
    // Sem await: a UI não deve esperar o disco para trocar de tema, e falha
    // de gravação já é engolida pela implementação de storage.
    settingsStorage.saveThemeMode(mode);
  }

  // ── Month navigation (Monthly screen) ───────────────────────────────
  void setMonthOffset(int offset) {
    if (offset == monthOffset) return;
    monthOffset = offset;
    notifyListeners();
  }

  // ── Cards ────────────────────────────────────────────────────────────
  String cardName(String cardId) => _card(cardId)?.name ?? 'Cartão removido';

  /// A cor do cartão nas listas. Um cartão apagado cai no hash do rótulo
  /// "Cartão removido", que é sempre o mesmo cinza-neutro para todos eles.
  int cardHue(String cardId) => _card(cardId)?.resolvedHue ?? hueForLabel('Cartão removido');

  CardModel? _card(String cardId) {
    for (final card in cards) {
      if (card.id == cardId) return card;
    }
    return null;
  }

  // As escritas de cartão e de fatura devolvem se deram certo porque a tela
  // mostra um toast de sucesso depois delas. Sem isso, uma falha exibia os
  // dois toasts — o erro vindo do _guard e o sucesso vindo da tela.
  Future<bool> addCard(String name, int? hue) async {
    final created = await _guard(() => _repository.createCard(name, hue));
    if (created == null) return false;

    cards = [...cards, created];
    notifyListeners();
    return true;
  }

  Future<bool> updateCard(String id, String name, int? hue) async {
    final updated = await _guard(() => _repository.updateCard(id, name, hue));
    if (updated == null) return false;

    cards = [for (final c in cards) if (c.id == id) updated else c];
    notifyListeners();
    return true;
  }

  Future<bool> deleteCard(String id) async {
    final removed = await _guard(() async {
      await _repository.deleteCard(id);
      return true;
    });
    if (removed == null) return false;

    cards = cards.where((c) => c.id != id).toList();
    notifyListeners();
    return true;
  }

  // ── Purchases ────────────────────────────────────────────────────────
  /// As parcelas que caem em [offset], da maior para a menor.
  ///
  /// Ordenar por valor põe na frente o que mais pesa na fatura, que é a
  /// pergunta que a lista responde. O desempate por mês e depois por nome
  /// não é detalhe: sem ele, duas compras de mesmo valor trocariam de lugar
  /// a cada rebuild, já que o sort do Dart não é estável.
  List<PurchaseEntry> activePurchases(int offset) {
    final target = currentAbs + offset;
    final entries = <PurchaseEntry>[
      for (final p in purchases) (purchase: p, status: PurchaseStatus.at(p, target)),
    ].where((e) => e.status.active).toList()
      ..sort((a, b) {
        final byAmount = b.purchase.amount.compareTo(a.purchase.amount);
        if (byAmount != 0) return byAmount;

        final byMonth = b.purchase.startAbs.compareTo(a.purchase.startAbs);
        if (byMonth != 0) return byMonth;

        return a.purchase.name.compareTo(b.purchase.name);
      });
    return entries;
  }

  double totalFor(int offset) =>
      activePurchases(offset).fold(0.0, (sum, e) => sum + e.purchase.amount);

  /// This month's active purchases and total — what the Home screen shows.
  List<PurchaseEntry> get homeEntries => activePurchases(0);
  double get homeTotal => totalFor(0);

  /// Total falling on [offset] for one card only. The bank bills each card
  /// separately, so this — not [totalFor] — is what a bill can be checked
  /// against. Other people's purchases count: the bank charges the whole
  /// card together, whoever made the purchase.
  double totalForCard(int offset, String cardId) => activePurchases(offset)
      .where((e) => e.purchase.cardId == cardId)
      .fold(0.0, (sum, e) => sum + e.purchase.amount);

  /// Total considering only the user's own purchases for [offset] months
  /// from now — other people's purchases on the card don't count toward the
  /// spending goal or the deposit calculator.
  double ownTotalFor(int offset) =>
      activePurchases(offset).where((e) => !e.purchase.isOther).fold(0.0, (sum, e) => sum + e.purchase.amount);

  /// This month's total considering only the user's own purchases.
  double get homeOwnTotal => ownTotalFor(0);

  /// Fraction of [spendingLimit] used by [homeOwnTotal] (can exceed 1 when
  /// over the goal), or `null` when no goal is set.
  double? get spendingGoalRatio {
    final limit = spendingLimit;
    if (limit == null || limit <= 0) return null;
    return homeOwnTotal / limit;
  }

  /// The Monthly screen's active purchases and total, for [monthOffset].
  List<PurchaseEntry> get monthlyEntries => activePurchases(monthOffset);
  double get monthlyTotal => totalFor(monthOffset);

  Future<void> addPurchase(Purchase draft) async {
    final created = await _guard(() => _repository.createPurchase(draft));
    if (created == null) return;

    purchases = [...purchases, created];
    notifyListeners();
  }

  Future<void> updatePurchase(Purchase purchase) async {
    final updated = await _guard(() => _repository.updatePurchase(purchase));
    if (updated == null) return;

    purchases = [for (final p in purchases) if (p.id == updated.id) updated else p];
    notifyListeners();
  }

  Future<void> deletePurchase(String id) async {
    final removed = await _guard(() async {
      await _repository.deletePurchase(id);
      return true;
    });
    if (removed == null) return;

    purchases = purchases.where((p) => p.id != id).toList();
    notifyListeners();
  }

  // ── Conferência da fatura ────────────────────────────────────────────
  /// The reconciliation rows for [offset], one per card worth showing.
  ///
  /// A card only shows up when it has installments this month or a bill was
  /// informed for it — otherwise every card ever created would linger on
  /// every month forever.
  List<StatementCheck> statementChecksFor(int offset) {
    final target = currentAbs + offset;
    final checks = <StatementCheck>[];

    for (final card in cards) {
      final registered = totalForCard(offset, card.id);
      final statement = statementFor(card.id, target);
      if (registered == 0 && statement == null) continue;

      checks.add(StatementCheck(card: card, statement: statement, registered: registered));
    }

    return checks;
  }

  /// The bill informed for [cardId] on the absolute month [monthAbs], if any.
  CardStatement? statementFor(String cardId, int monthAbs) {
    for (final statement in statements) {
      if (statement.cardId == cardId && statement.monthAbs == monthAbs) return statement;
    }
    return null;
  }

  /// The Monthly screen's reconciliation, for [monthOffset].
  List<StatementCheck> get monthlyStatementChecks => statementChecksFor(monthOffset);

  Future<bool> saveStatement(String cardId, int monthAbs, double amount) async {
    final saved = await _guard(() => _repository.saveStatement(cardId, monthAbs, amount));
    if (saved == null) return false;

    // Substitui a linha do mesmo (cartão, mês) em vez de acrescentar: no
    // servidor o upsert já fez isso, e duas linhas do mesmo par aqui fariam
    // a conferência ler a errada.
    statements = [
      for (final s in statements)
        if (s.cardId != cardId || s.monthAbs != monthAbs) s,
      saved,
    ];
    notifyListeners();
    return true;
  }

  Future<bool> removeStatement(String id) async {
    final removed = await _guard(() async {
      await _repository.removeStatement(id);
      return true;
    });
    if (removed == null) return false;

    statements = statements.where((s) => s.id != id).toList();
    notifyListeners();
    return true;
  }

  // ── People ───────────────────────────────────────────────────────────
  /// Per-person totals for [offset] months from now — lets the People
  /// screen browse upcoming (or past) months the same way Deposit does.
  List<PersonSummary> personSummariesFor(int offset) {
    final totals = <String, double>{};
    for (final e in activePurchases(offset)) {
      totals[e.purchase.personLabel] = (totals[e.purchase.personLabel] ?? 0) + e.purchase.amount;
    }
    final list = totals.entries.map((e) => PersonSummary(label: e.key, total: e.value)).toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  List<PersonSummary> get personSummaries => personSummariesFor(0);

  List<PurchaseEntry> transactionsForPersonFor(int offset, String label) =>
      activePurchases(offset).where((e) => e.purchase.personLabel == label).toList();

  List<PurchaseEntry> transactionsForPerson(String label) => transactionsForPersonFor(0, label);

  double get grandTotal => homeTotal;

  // ── Deposit (salaries / expenses) ───────────────────────────────────
  // Salaries and fixed expenses are a flat recurring budget (no month of
  // their own); only the credit card total changes per month, so that's the
  // only piece these take an [offset] for. Only the user's own card
  // purchases count against savings — other people's purchases are their
  // own to pay back, not the user's.
  double get totalSalaries => salaries.fold(0.0, (sum, s) => sum + s.value);
  double afterCreditFor(int offset) => totalSalaries - ownTotalFor(offset);
  double get afterCredit => afterCreditFor(0);

  List<ExpenseRow> expenseRowsFor(int offset) {
    final rows = <ExpenseRow>[];
    var running = afterCreditFor(offset);
    for (final expense in expenses) {
      running -= expense.value;
      rows.add(ExpenseRow(expense: expense, runningBalance: running));
    }
    return rows;
  }

  List<ExpenseRow> get expenseRows => expenseRowsFor(0);

  double guardarFor(int offset) {
    final rows = expenseRowsFor(offset);
    return rows.isEmpty ? afterCreditFor(offset) : rows.last.runningBalance;
  }

  double get guardar => guardarFor(0);

  Future<void> addSalary(String name, double value) async {
    final created = await _guard(() => _repository.addSalary(name, value));
    if (created == null) return;

    salaries = [...salaries, created];
    notifyListeners();
  }

  /// Substitui o item no lugar em que ele já estava. A posição importa: a
  /// ordem da lista é a mesma em que as despesas são descontadas do saldo.
  Future<void> updateSalary(String id, String name, double value) async {
    final updated = await _guard(() => _repository.updateSalary(id, name, value));
    if (updated == null) return;

    salaries = [
      for (final salary in salaries) salary.id == id ? updated : salary,
    ];
    notifyListeners();
  }

  Future<void> removeSalary(String id) async {
    final removed = await _guard(() async {
      await _repository.removeSalary(id);
      return true;
    });
    if (removed == null) return;

    salaries = salaries.where((s) => s.id != id).toList();
    notifyListeners();
  }

  Future<void> addExpense(String name, double value) async {
    final created = await _guard(() => _repository.addExpense(name, value));
    if (created == null) return;

    expenses = [...expenses, created];
    notifyListeners();
  }

  Future<void> updateExpense(String id, String name, double value) async {
    final updated = await _guard(() => _repository.updateExpense(id, name, value));
    if (updated == null) return;

    expenses = [
      for (final expense in expenses) expense.id == id ? updated : expense,
    ];
    notifyListeners();
  }

  Future<void> removeExpense(String id) async {
    final removed = await _guard(() async {
      await _repository.removeExpense(id);
      return true;
    });
    if (removed == null) return;

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
      '─────────────────────',
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
