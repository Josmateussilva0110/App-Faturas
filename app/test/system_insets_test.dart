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

    // O resumo abre a tela: os três números empilhados, com o saldo fechando
    // o bloco. Os rótulos ficam presos aqui porque foram renomeados no
    // redesign e nada mais os cobria.
    expect(find.text('Total de salários'), findsOneWidget);
    expect(find.text('Crédito no cartão'), findsOneWidget);
    expect(find.text('Saldo após o cartão'), findsOneWidget);

    final guardar = find.text('GUARDAR');
    await tester.dragUntilVisible(guardar, find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(find.textContaining('Saldo restante:'), findsWidgets);

    expect(tester.getRect(guardar).bottom, lessThanOrEqualTo(_navBarTop(tester)));
  });

  testWidgets('a aba Meses cabe numa tela estreita sem estourar', (tester) async {
    _useSmallScreenWithNavBar(tester);
    await _pumpApp(tester);
    await _signIn(tester);

    await tester.tap(find.text('Meses'));
    await tester.pumpAndSettle();

    // O redesign deu mais respiro aos cards e aumentou a tipografia. Num
    // aparelho de 360px isso é o que estoura primeiro — e o teste falha
    // sozinho se qualquer RenderFlex passar da largura, porque o
    // WidgetTester trata o overflow como exceção não esperada.
    expect(find.text('Conferência da fatura'), findsOneWidget);
    expect(find.text('Confere'), findsOneWidget);

    // A lista só constrói o que está no viewport, então o resto da tela só
    // existe depois de rolar — que é também o que exercita as linhas de
    // parcela, fora da primeira dobra nessa altura.
    await tester.dragUntilVisible(
      find.text('Compra 1'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parcelas do mês'), findsOneWidget);
  });

  testWidgets('Pessoas e Cartões cabem numa tela estreita sem estourar', (tester) async {
    _useSmallScreenWithNavBar(tester);
    await _pumpApp(tester);
    await _signIn(tester);

    // As duas linhas ficaram mais largas no redesign — avatar, nome, valor e
    // botões disputando 360px. É onde um RenderFlex estoura primeiro, e o
    // WidgetTester trata overflow como exceção não esperada, então basta
    // renderizar para o teste valer.
    await tester.tap(find.text('Pessoas'));
    await tester.pumpAndSettle();
    expect(find.text('Gastos por pessoa'), findsOneWidget);

    await tester.tap(find.text('Cartões'));
    await tester.pumpAndSettle();
    expect(find.text('Meus cartões'), findsOneWidget);
    expect(find.text('Nubank'), findsOneWidget);
    expect(find.byTooltip('Editar cartão'), findsOneWidget);
    expect(find.byTooltip('Excluir cartão'), findsOneWidget);
  });

  testWidgets('no tema claro os ícones da barra do sistema ficam escuros', (tester) async {
    _useSmallScreenWithNavBar(tester);
    await _pumpApp(tester);

    // Ícone escuro sobre a superfície clara do app. Sem isto a barra herdava
    // o padrão do aparelho e aparecia como uma faixa escura no tema claro.
    expect(SystemChrome.latestStyle?.systemNavigationBarIconBrightness, Brightness.dark);
  });
}
