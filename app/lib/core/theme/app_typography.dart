import 'package:flutter/material.dart';

/// A escala tipográfica do app, por papel.
///
/// Papel, não slot do Material: `titleMedium` não diz se serve para um valor
/// em dinheiro ou para o nome de uma compra, e essa ambiguidade foi o que
/// produziu 68 `TextStyle` inline com 14 tamanhos diferentes — e o mesmo
/// papel saindo com pesos diferentes em telas vizinhas.
///
/// Use por `context.text`.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.hero,
    required this.money,
    required this.title,
    required this.body,
    required this.label,
    required this.field,
    required this.caption,
  });

  factory AppTypography.of(ColorScheme scheme) {
    return AppTypography(
      hero: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
      money: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      title: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      body: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      label: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      field: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      caption: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
    );
  }

  /// O número herói de uma tela — o total do mês no card primário.
  final TextStyle hero;

  /// Valor em dinheiro dentro de uma linha ou de um rodapé de total.
  final TextStyle money;

  /// Título de uma linha de lista: nome da compra, do cartão, da pessoa.
  final TextStyle title;

  /// Texto corrente com algum peso: rótulo do seletor de mês, item de lista
  /// de dinheiro.
  final TextStyle body;

  /// Cabeçalho de seção e mensagens de estado.
  final TextStyle label;

  /// Rótulo de campo de formulário e legendas. Já vem apagado.
  final TextStyle field;

  /// O menor nível: tags, metadados sob uma linha. Já vem apagado.
  final TextStyle caption;

  @override
  AppTypography copyWith({
    TextStyle? hero,
    TextStyle? money,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
    TextStyle? field,
    TextStyle? caption,
  }) {
    return AppTypography(
      hero: hero ?? this.hero,
      money: money ?? this.money,
      title: title ?? this.title,
      body: body ?? this.body,
      label: label ?? this.label,
      field: field ?? this.field,
      caption: caption ?? this.caption,
    );
  }

  @override
  AppTypography lerp(AppTypography? other, double t) {
    if (other == null) return this;
    return AppTypography(
      hero: TextStyle.lerp(hero, other.hero, t)!,
      money: TextStyle.lerp(money, other.money, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      field: TextStyle.lerp(field, other.field, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }
}

extension AppTypographyContext on BuildContext {
  AppTypography get text => Theme.of(this).extension<AppTypography>()!;
}
