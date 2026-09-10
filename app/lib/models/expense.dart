/// One recurring fixed expense on the Deposit screen.
///
/// Same shape as [Salary], including the `amount` (wire) / [value] (app)
/// naming, kept as a separate type because the two lists never mix.
class Expense {
  const Expense({required this.id, required this.name, required this.value});

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      value: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String name;
  final double value;

  /// Corpo enviado ao criar ou editar. Sem `id`: quem o define é o servidor.
  Map<String, dynamic> toJson() => {'name': name, 'amount': value};

  Expense withId(String id) => Expense(id: id, name: name, value: value);
}
