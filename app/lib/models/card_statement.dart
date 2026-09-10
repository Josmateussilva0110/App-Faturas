/// The bill amount the bank shows for one card in one month, as typed by the
/// user. The app compares it against the installments it has registered for
/// that same card and month.
///
/// Its identity is the (card, month) pair, not [id] — informing the value
/// again for the same pair overwrites it rather than adding a second row.
class CardStatement {
  const CardStatement({
    required this.id,
    required this.cardId,
    required this.monthAbs,
    required this.amount,
  });

  factory CardStatement.fromJson(Map<String, dynamic> json) {
    return CardStatement(
      id: json['id'] as String? ?? '',
      cardId: json['card_id'] as String? ?? '',
      monthAbs: (json['month_abs'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String cardId;

  /// Absolute month (`year * 12 + month0`), same convention as
  /// `Purchase.startAbs`.
  final int monthAbs;

  final double amount;

  /// Corpo enviado ao gravar. Sem `id`: o servidor resolve pela chave
  /// natural (`card_id`, `month_abs`).
  Map<String, dynamic> toJson() => {
        'card_id': cardId,
        'month_abs': monthAbs,
        'amount': amount,
      };

  CardStatement withId(String id) =>
      CardStatement(id: id, cardId: cardId, monthAbs: monthAbs, amount: amount);
}
