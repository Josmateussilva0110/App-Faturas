import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Faz as barras do sistema (status e navegação) seguirem o tema do app.
///
/// A partir do Android 15 o modo edge-to-edge é obrigatório: o sistema desenha
/// as barras por cima do app e ignora a cor pedida. O que ainda obedece é o
/// brilho dos ícones — sem declarar, ficava o padrão do aparelho, e no tema
/// claro a barra de navegação aparecia como uma faixa escura.
///
/// Mora no `builder` do MaterialApp, abaixo do `Theme`, para que
/// `Theme.of(context).brightness` já traga o tema resolvido (inclusive quando
/// o modo é `system`) e uma declaração cubra o app inteiro.
class SystemBarsStyle extends StatelessWidget {
  const SystemBarsStyle({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Ícone escuro sobre fundo claro, e o contrário no tema escuro.
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        // Só o iOS lê este: aqui o valor é o brilho do *fundo*, não do ícone.
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: iconBrightness,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: child,
    );
  }
}
