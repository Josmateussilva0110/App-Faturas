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

/// An account payload shaped like the backend's `UserProfile`.
Map<String, dynamic> fakeProfile({
  String username = 'Mateus',
  String email = 'mateus@email.com',
}) {
  return {'id': 'u1', 'username': username, 'email': email};
}

/// Answers the endpoints the app hits at boot and after login: the profile
/// for `/profile`, a session for everything else.
ResponseBody defaultHandler(RequestOptions options) {
  if (options.path.contains('/profile')) {
    return jsonBody({'success': true, 'data': fakeProfile()}, 200);
  }
  return jsonBody({'success': true, 'message': 'ok', 'data': fakeSession()}, 200);
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
