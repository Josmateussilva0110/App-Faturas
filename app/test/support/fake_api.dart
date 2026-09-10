import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers requests from a canned handler instead of hitting the network,
/// recording what went out so tests can assert on headers and bodies.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Map<String, dynamic> body, int status) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// An account payload shaped like the backend's `UserProfile`. The spending
/// goal rides along on the profile, which is where the app reads it from.
Map<String, dynamic> fakeProfile({
  String username = 'Mateus',
  String email = 'mateus@email.com',
  double? spendingLimit,
}) {
  return {
    'id': 'u1',
    'username': username,
    'email': email,
    'spending_limit': spendingLimit,
  };
}

/// Answers the endpoints the app hits at boot and after login: the profile,
/// the card, purchase, salary and expense lists, and a session for
/// everything else.
ResponseBody defaultHandler(RequestOptions options) {
  if (options.path.contains('/profile')) {
    return jsonBody({'success': true, 'data': fakeProfile()}, 200);
  }
  if (options.path.contains('/cards')) {
    return jsonBody({'success': true, 'data': fakeCards()}, 200);
  }
  if (options.path.contains('/purchases')) {
    return jsonBody({'success': true, 'data': fakePurchases()}, 200);
  }
  if (options.path.contains('/salaries')) {
    return jsonBody({'success': true, 'data': fakeSalaries()}, 200);
  }
  if (options.path.contains('/expenses')) {
    return jsonBody({'success': true, 'data': fakeExpenses()}, 200);
  }
  return jsonBody({'success': true, 'message': 'ok', 'data': fakeSession()}, 200);
}

/// Um cartão, com o nome que os testes de navegação procuram.
List<Map<String, dynamic>> fakeCards() {
  return [
    {'id': 'c1', 'name': 'Nubank'},
  ];
}

List<Map<String, dynamic>> fakePurchases() {
  return [
    {
      'id': 'p1',
      'card_id': 'c1',
      'name': 'Compra 1',
      'amount': 165.0,
      'installments': 10,
      'is_other': false,
      'person': '',
      'start_abs': DateTime.now().year * 12 + DateTime.now().month - 1,
    },
  ];
}

/// Um salário e uma despesa, o bastante para a tela de Depositar abrir com
/// conteúdo. `deposit_mapping_test` cobre as variações de formato.
List<Map<String, dynamic>> fakeSalaries() {
  return [
    {'id': 's1', 'name': 'Mateus', 'amount': 650.0},
  ];
}

List<Map<String, dynamic>> fakeExpenses() {
  return [
    {'id': 'e1', 'name': 'Internet', 'amount': 100.0},
  ];
}

/// A session payload shaped like the backend's `AuthTokens`, expiring far
/// enough in the future that nothing tries to refresh it mid-test.
Map<String, dynamic> fakeSession({
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
}) {
  return {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': 4102444800000,
    'user': {'id': 'u1', 'email': 'voce@email.com'},
  };
}
