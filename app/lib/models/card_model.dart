class CardModel {
  const CardModel({required this.id, required this.name});

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  final String id;
  final String name;

  /// Corpo enviado ao criar ou editar. Sem `id`: quem o define é o servidor.
  Map<String, dynamic> toJson() => {'name': name};

  /// Mesmo cartão com o id atribuído pelo servidor — `POST` e `PUT`
  /// respondem apenas com ele.
  CardModel withId(String id) => CardModel(id: id, name: name);

  CardModel copyWith({String? name}) {
    return CardModel(id: id, name: name ?? this.name);
  }
}
