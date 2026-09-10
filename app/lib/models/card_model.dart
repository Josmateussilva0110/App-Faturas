import '../core/utils/formatters.dart';

class CardModel {
  const CardModel({required this.id, required this.name, this.hue});

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      hue: (json['color_hue'] as num?)?.toInt(),
    );
  }

  final String id;
  final String name;

  /// Matiz escolhido pelo usuário, ou null para "automática".
  final int? hue;

  /// A cor que o cartão realmente usa. O fallback mora aqui, e não em cada
  /// tela, para não haver como esquecer dele num lugar e o mesmo cartão sair
  /// de cores diferentes em telas diferentes.
  int get resolvedHue => hue ?? hueForLabel(name);

  /// Corpo enviado ao criar ou editar. Sem `id`: quem o define é o servidor.
  Map<String, dynamic> toJson() => {'name': name, 'color_hue': hue};

  /// Mesmo cartão com o id atribuído pelo servidor — `POST` e `PUT`
  /// respondem apenas com ele.
  CardModel withId(String id) => CardModel(id: id, name: name, hue: hue);

  CardModel copyWith({String? name, int? hue}) {
    return CardModel(id: id, name: name ?? this.name, hue: hue ?? this.hue);
  }
}
