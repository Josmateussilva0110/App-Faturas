/// One recurring income line on the Deposit screen.
///
/// The backend calls the money field `amount` (matching the NUMERIC column);
/// the app calls it [value]. The translation lives only in [fromJson] /
/// [toJson], so no screen has to know about the wire format.
class Salary {
  const Salary({required this.id, required this.name, required this.value});

  factory Salary.fromJson(Map<String, dynamic> json) {
    return Salary(
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

  Salary withId(String id) => Salary(id: id, name: name, value: value);
}
