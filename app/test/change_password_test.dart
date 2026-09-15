import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/auth_storage.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/main.dart';

import 'support/fake_api.dart';

/// `PUT /profile/password` compartilha prefixo com `GET /profile`, e o
/// `defaultHandler` casa o prefixo primeiro — sem separar por método, uma
/// troca de senha "daria certo" devolvendo o perfil.
bool _isPasswordChange(RequestOptions options) =>
    options.path.contains('/profile/password') && options.method == 'PUT';

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
  await tester.tap(entrar);
  await tester.pumpAndSettle();

  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Future<void> _openChangePassword(WidgetTester tester) async {
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Alterar senha'));
  await tester.pumpAndSettle();
}

/// Preenche os três campos da troca voluntária.
Future<void> _fill(
  WidgetTester tester, {
  required String current,
  required String next,
  required String confirm,
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), current);
  await tester.enterText(fields.at(1), next);
  await tester.enterText(fields.at(2), confirm);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    tokenManager.clearTokens();
    authStorage = InMemoryAuthStorage();
    api.httpClientAdapter = FakeAdapter(defaultHandler);
  });

  tearDown(tokenManager.clearTokens);

  testWidgets('o Perfil abre a troca de senha e o sucesso volta para lá', (tester) async {
    late FakeAdapter adapter;
    adapter = FakeAdapter((options) {
      if (_isPasswordChange(options)) {
        return jsonBody({'success': true, 'data': {'id': 'u1'}}, 200);
      }
      return defaultHandler(options);
    });
    api.httpClientAdapter = adapter;

    await _pumpApp(tester);
    await _signIn(tester);
    await _openChangePassword(tester);

    expect(find.text('Alterar senha'), findsWidgets);
    await _fill(tester, current: 'antiga123', next: 'NovaSenha1!', confirm: 'NovaSenha1!');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar senha'));
    await tester.pumpAndSettle();

    final sent = adapter.calls.where(_isPasswordChange).toList();
    expect(sent, hasLength(1));
    expect(sent.single.data, {
      'current_password': 'antiga123',
      'new_password': 'NovaSenha1!',
      'confirm_password': 'NovaSenha1!',
    });

    // Voltou para o Perfil.
    expect(find.text('Sair da conta'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('senha fraca nem chega ao servidor', (tester) async {
    late FakeAdapter adapter;
    adapter = FakeAdapter(defaultHandler);
    api.httpClientAdapter = adapter;

    await _pumpApp(tester);
    await _signIn(tester);
    await _openChangePassword(tester);

    await _fill(tester, current: 'antiga123', next: 'abcdefgh', confirm: 'abcdefgh');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar senha'));
    await tester.pumpAndSettle();

    expect(find.text('Inclua ao menos uma letra maiúscula.'), findsOneWidget);
    expect(adapter.calls.where(_isPasswordChange), isEmpty);
  });

  testWidgets('confirmação diferente é barrada antes do envio', (tester) async {
    late FakeAdapter adapter;
    adapter = FakeAdapter(defaultHandler);
    api.httpClientAdapter = adapter;

    await _pumpApp(tester);
    await _signIn(tester);
    await _openChangePassword(tester);

    await _fill(tester, current: 'antiga123', next: 'NovaSenha1!', confirm: 'NovaSenha2!');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar senha'));
    await tester.pumpAndSettle();

    expect(find.text('As senhas não coincidem.'), findsOneWidget);
    expect(adapter.calls.where(_isPasswordChange), isEmpty);
  });

  testWidgets('senha temporária prende na troca e libera o app depois dela', (tester) async {
    var mustChange = true;
    late FakeAdapter adapter;
    adapter = FakeAdapter((options) {
      if (_isPasswordChange(options)) {
        mustChange = false;
        return jsonBody({'success': true, 'data': {'id': 'u1'}}, 200);
      }
      if (options.path.contains('/profile')) {
        return jsonBody({
          'success': true,
          'data': fakeProfile(mustChangePassword: mustChange),
        }, 200);
      }
      return defaultHandler(options);
    });
    api.httpClientAdapter = adapter;

    await _pumpApp(tester);
    await _signIn(tester);

    // Entra na tela obrigatória, e não no app.
    expect(find.text('Defina uma nova senha'), findsOneWidget);
    expect(find.text('Início'), findsNothing);

    // Sem campo de senha atual: o usuário não a conhece, ela é temporária.
    expect(find.byType(TextField), findsNWidgets(2));

    // O gesto de voltar não pode devolver ao app com a senha temporária.
    final popped = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(popped, isTrue);
    expect(find.text('Defina uma nova senha'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'NovaSenha1!');
    await tester.enterText(fields.at(1), 'NovaSenha1!');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar senha'));
    await tester.pumpAndSettle();

    final sent = adapter.calls.where(_isPasswordChange).toList();
    expect(sent, hasLength(1));
    // Sem `current_password`: o backend aceita a troca sem ela nesse caso.
    expect((sent.single.data as Map).containsKey('current_password'), isFalse);

    // E o app abre. `findsWidgets` porque "Início" aparece duas vezes ali:
    // o título da AppBar e o rótulo da aba.
    expect(find.text('Início'), findsWidgets);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
