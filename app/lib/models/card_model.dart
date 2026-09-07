class CardModel {
  const CardModel({required this.id, required this.name});

  final String id;
  final String name;

  CardModel copyWith({String? name}) {
    return CardModel(id: id, name: name ?? this.name);
  }
}
