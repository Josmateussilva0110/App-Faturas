import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/auth_storage.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/main.dart';

import 'support/fake_api.dart';

/// Altura em pixels lógicos da faixa de botões/gestos do Android nos testes
/// abaixo. O recorte é o do bug: tela pequena, faixa alta.
const _navBarHeight = 48.0;

/// Simula um aparelho de tela pequena com a barra de navegação do sistema
/// embaixo — foi nesse formato que o conteúdo ficou embaixo dos botões.
void _useSmallScreenWithNavBar(WidgetTester tester) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(720, 1280); // 360 x 640 lógicos
  const inset = FakeViewPadding(bottom: _navBarHeight * 2);
  tester.view.viewPadding = inset;
  tester.view.padding = inset;
  addTearDown(tester.view.reset);
}

double _navBarTop(WidgetTester tester) =>
    tester.view.physicalSize.height / tester.view.devicePixelRatio - _navBarHeight;

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const FaturaApp());
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester) async {
  final entrar = find.widgetWithText(FilledButton, 'Entrar');
  await tester.tap(entrar);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'voce@email.com');
  await tester.enterText(find.byType(TextField).last, 'senha123');
  // Nesta tela o formulário é mais alto que 640px: sem rolar, o botão fica
  // fora da árvore visível e o toque do teste erra o alvo.
  await tester.ensureVisible(entrar);
  await tester.pumpAndSettle();
  await tester.tap(entrar);
  await tester.pumpAndSettle();

  // Deixa o toast de boas-vindas expirar: o timer dele sobreviveria ao teste.
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    tokenManager.clearTokens();
    authStorage = InMemoryAuthStorage();
    api.httpClientAdapter = FakeAdapter(defaultHandler);
  });

  tearDown(tokenManager.clearTokens);

  testWidgets('a barra do sistema não cobre o botão de salvar compra', (tester) async {
    _useSmallScreenWithNavBar(tester);
    await _pumpApp(tester);
    await _signIn(tester);

    await tester.tap(find.byTooltip('Nova compra'));
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(FilledButton, 'Salvar compra');
    await tester.dragUntilVisible(submit, find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();

    // Rolar até o fim não pode deixar o botão embaixo da barra: ali o toque
    // vai para o sistema e o usuário não consegue salvar.
    expect(tester.getRect(submit).bottom, lessThanOrEqualTo(_navBarTop(tester)));
  });

  testWidgets('a barra do sistema não cobre o card "Guardar" do Depositar', (tester) async {
    _useSmallScreenWithNavBar(tester);
    await _pumpApp(tester);
    await _signIn(tester);

    await tester.tap(find.text('Depositar'));
    await tester.pumpAndSettle();

    final guardar = find.text('GUARDAR');
    await tester.dragUntilVisible(guardar, find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(tester.getRect(guardar).bottom, lessThanOrEqualTo(_navBarTop(tester)));
  });

  testWidgets('no tema claro os ícones da barra do sistema ficam escuros', (tester) async {
    _useSmallScreenWithNavBar(tester);
    await _pumpApp(tester);

    // Ícone escuro sobre a superfície clara do app. Sem isto a barra herdava
    // o padrão do aparelho e aparecia como uma faixa escura no tema claro.
    expect(SystemChrome.latestStyle?.systemNavigationBarIconBrightness, Brightness.dark);
  });
}
