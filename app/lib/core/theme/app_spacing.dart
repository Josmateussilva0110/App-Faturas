/// Escala de espaçamento do app.
///
/// Prefira os passos principais (xs, sm, md, lg, xl) em código novo. Os
/// meios-passos existem porque a interface já foi construída com eles em
/// respiros dentro de uma linha (ícone + texto, chip + rótulo); normalizar
/// tudo agora mexeria no layout de dezenas de telas sem ganho visível.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double xsPlus = 6;
  static const double sm = 8;
  static const double smPlus = 10;
  static const double md = 12;
  static const double mdPlus = 14;
  static const double lg = 16;
  static const double xl = 24;
}

/// Escala de raio. O app usava oito valores distintos para uma escala de
/// três, então metade dos `BorderRadius` eram literais — vários repetindo um
/// token que já existia.
class AppRadius {
  const AppRadius._();

  /// Detalhes finos: trilho de progresso, faixa de acento.
  static const double xs = 4;

  /// Pílulas pequenas: tags, chips de status.
  static const double sm = 8;

  /// Padrão: cards de lista, campos, botões, toast.
  static const double md = 14;

  /// Superfícies grandes: diálogos, card primário, seletor segmentado.
  static const double lg = 20;

  /// Cápsula — o valor é só grande o bastante para arredondar por completo.
  static const double pill = 999;
}
