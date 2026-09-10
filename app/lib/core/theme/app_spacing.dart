/// Escala de espaçamento do app.
///
/// Prefira os passos principais (xs, sm, md, lg, xl, xxl) em código novo. Os
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
  static const double xxl = 32;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
}
