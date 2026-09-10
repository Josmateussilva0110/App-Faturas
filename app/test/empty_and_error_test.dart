import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/auth_storage.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/main.dart';
import 'package:fatura/widgets/empty_state.dart';

import 'support/fake_api.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const FaturaApp());
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'voce@email.com');
  await tester.enterText(find.byType(TextField).last, 'senha123');
  await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
  await tester.pumpAndSettle();
}

/// Responde à sessão e ao perfil, mas derruba as listas — é a forma da falha
/// de rede parcial que o `AppState.load()` trata.
ResponseBody _listsDown(RequestOptions options) {
  if (options.path.contains('/cards') ||
      options.path.contains('/purchases') ||
      options.path.contains('/salaries') ||
      options.path.contains('/expenses') ||
      options.path.contains('/statements')) {
    return jsonBody({'success': false, 'message': 'Servidor indisponível.'}, 503);
  }
  return defaultHandler(options);
}

void main() {
  setUp(() {
    tokenManager.clearTokens();
    authStorage = InMemoryAuthStorage();
    api.httpClientAdapter = FakeAdapter(defaultHandler);
  });

  tearDown(tokenManager.clearTokens);

  testWidgets('falha de rede mostra erro com retry, não "nenhuma compra"', (tester) async {
    final adapter = FakeAdapter(_listsDown);
    api.httpClientAdapter = adapter;

    await _pumpApp(tester);
    await _signIn(tester);

    // A mensagem do servidor, não a frase de lista vazia.
    expect(find.text('Servidor indisponível.'), findsOneWidget);
    expect(find.text('Nenhuma compra ativa este mês.'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Tentar de novo'), findsOneWidget);

    // O retry busca de novo — e, com o servidor de volta, a tela se recupera
    // sozinha, sem precisar reabrir o app.
    api.httpClientAdapter = FakeAdapter(defaultHandler);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Servidor indisponível.'), findsNothing);
    expect(find.text('Compra 1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('mês sem compras continua dizendo que está vazio', (tester) async {
    api.httpClientAdapter = FakeAdapter((options) {
      if (options.path.contains('/purchases')) {
        return jsonBody({'success': true, 'data': <Map<String, dynamic>>[]}, 200);
      }
      return defaultHandler(options);
    });

    await _pumpApp(tester);
    await _signIn(tester);

    // Vazio de verdade: sem botão de retry, que aqui não teria o que corrigir.
    expect(find.text('Nenhuma compra ativa este mês.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Tentar de novo'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('sem cartões, o formulário de compra oferece cadastrar um', (tester) async {
    api.httpClientAdapter = FakeAdapter((options) {
      if (options.path.contains('/cards')) {
        return jsonBody({'success': true, 'data': <Map<String, dynamic>>[]}, 200);
      }
      return defaultHandler(options);
    });

    await _pumpApp(tester);
    await _signIn(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Antes a seção "Pagamento" ficava em branco e o botão nunca habilitava,
    // sem nada explicando o que faltava.
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Cadastrar cartão'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
