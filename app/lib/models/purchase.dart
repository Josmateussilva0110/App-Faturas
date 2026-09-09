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

  /// A API usa snake_case (`card_id`, `is_other`, `start_abs`) porque espelha
  /// as colunas do banco; aqui os campos seguem a convenção do Dart. A
  /// tradução entre os dois formatos mora neste par fromJson/toJson, e em
  /// nenhum outro lugar.
  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      installments: (json['installments'] as num?)?.toInt() ?? 1,
      isOther: json['is_other'] as bool? ?? false,
      person: json['person'] as String? ?? '',
      // Nulo quando o cartão foi removido; o app mostra "Cartão removido".
      cardId: json['card_id'] as String? ?? '',
      startAbs: (json['start_abs'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final double amount;
  final int installments;
  final bool isOther;
  final String person;
  final String cardId;
  final int startAbs;

  /// Corpo enviado ao criar ou editar. Sem `id`: quem o define é o servidor.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'installments': installments,
      'is_other': isOther,
      'person': person,
      'card_id': cardId,
      'start_abs': startAbs,
    };
  }

  /// Mesma compra com o id atribuído pelo servidor.
  ///
  /// `POST` e `PUT` respondem apenas com o id — o resto do objeto o cliente
  /// já tem, então remontar localmente evita um GET só para reler o que
  /// acabamos de enviar.
  Purchase withId(String id) {
    return Purchase(
      id: id,
      name: name,
      amount: amount,
      installments: installments,
      isOther: isOther,
      person: person,
      cardId: cardId,
      startAbs: startAbs,
    );
  }

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
