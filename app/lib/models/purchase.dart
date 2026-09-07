/// A credit-card purchase, possibly split into installments.
///
/// [startAbs] is an absolute month index (`year * 12 + monthIndex0based`),
/// used so installment math never has to special-case year boundaries.
class Purchase {
  const Purchase({
    required this.id,
    required this.name,
    required this.amount,
    required this.installments,
    required this.isOther,
    required this.person,
    required this.cardId,
    required this.startAbs,
  });

  final String id;
  final String name;
  final double amount;
  final int installments;
  final bool isOther;
  final String person;
  final String cardId;
  final int startAbs;

  /// Label of who this purchase belongs to ("Nós" when it's the user's own).
  String get personLabel => isOther ? person : 'Nós';

  Purchase copyWith({
    String? name,
    double? amount,
    int? installments,
    bool? isOther,
    String? person,
    String? cardId,
    int? startAbs,
  }) {
    return Purchase(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      installments: installments ?? this.installments,
      isOther: isOther ?? this.isOther,
      person: person ?? this.person,
      cardId: cardId ?? this.cardId,
      startAbs: startAbs ?? this.startAbs,
    );
  }
}

/// Installment status of a [Purchase] as seen from a given absolute month.
class PurchaseStatus {
  const PurchaseStatus({required this.active, required this.installmentNumber});

  final bool active;
  final int installmentNumber;

  static PurchaseStatus at(Purchase purchase, int targetAbs) {
    final elapsed = targetAbs - purchase.startAbs;
    return PurchaseStatus(
      active: elapsed >= 0 && elapsed < purchase.installments,
      installmentNumber: elapsed + 1,
    );
  }
}
