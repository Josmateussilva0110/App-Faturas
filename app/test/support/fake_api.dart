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
