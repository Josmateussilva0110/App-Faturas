import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/data/api/api_client.dart';
import 'package:fatura/data/api/api_routes.dart';
import 'package:fatura/data/api/auth_storage.dart';
import 'package:fatura/data/api/refresh_service.dart';
import 'package:fatura/data/api/request.dart';
import 'package:fatura/data/api/token_manager.dart';
import 'package:fatura/data/services/auth_service.dart';
import 'package:fatura/data/services/profile_service.dart';
import 'package:fatura/models/user_profile.dart';

import '../support/fake_api.dart';

void main() {
  late FakeAdapter apiAdapter;

  setUp(() {
    tokenManager.clearTokens();
    authStorage = InMemoryAuthStorage();
  });

  tearDown(() {
    tokenManager.clearTokens();
  });

  void mountApi(ResponseBody Function(RequestOptions) handler) {
    apiAdapter = FakeAdapter(handler);
    api.httpClientAdapter = apiAdapter;
  }

  test('decodes a successful response through parse', () async {
    mountApi((_) => jsonBody({
          'success': true,
          'data': {'id': 'u1', 'username': 'Mateus', 'email': 'mateus@email.com'},
        }, 200));

    final response = await getProfile();

    expect(response.success, isTrue);
    expect(response.data, isA<UserProfile>());
    expect(response.data!.username, 'Mateus');
  });

  test('attaches the bearer token, and skips it when withAuth is false', () async {
    mountApi((_) => jsonBody({'success': true}, 200));
    tokenManager.setTokens('access-1', 'refresh-1');

    await getProfile();
    expect(apiAdapter.calls.last.headers['Authorization'], 'Bearer access-1');

    await loginUser(email: 'a@b.com', password: 'x');
    expect(apiAdapter.calls.last.headers.containsKey('Authorization'), isFalse);
  });

  test('surfaces the first field error from a 422', () async {
    mountApi((_) => jsonBody({
          'success': false,
          'message': 'Erro de validação',
          'errors': [
            {'field': 'email', 'message': 'Email inválido.'},
          ],
        }, 422));

    final response = await loginUser(email: 'nope', password: 'x');

    expect(response.success, isFalse);
    expect(response.message, 'Email inválido.');
    expect(response.errors.single.field, 'email');
    expect(response.error!.status, 422);
    expect(response.isServerError, isTrue);
  });

  test('reports a network failure without throwing', () async {
    apiAdapter = FakeAdapter((_) => throw StateError('offline'));
    api.httpClientAdapter = apiAdapter;

    final response = await getProfile();

    expect(response.success, isFalse);
    expect(response.isNetworkError, isTrue);
    expect(response.message, contains('Não foi possível conectar'));
  });

  test('refreshes once on a 401 and replays the request with the new token', () async {
    tokenManager.setTokens('stale', 'refresh-1');

    var profileCalls = 0;
    mountApi((options) {
      profileCalls += 1;
      // First attempt carries the stale token and is rejected; the replay
      // carries the refreshed one and succeeds.
      if (options.headers['Authorization'] == 'Bearer fresh-access') {
        return jsonBody({
          'success': true,
          'data': {'id': 'u1', 'username': 'Mateus', 'email': 'mateus@email.com'},
        }, 200);
      }
      return jsonBody({'success': false, 'message': 'Não autorizado'}, 401);
    });

    final refreshAdapter = FakeAdapter((_) => jsonBody({
          'success': true,
          'data': {
            'accessToken': 'fresh-access',
            'refreshToken': 'fresh-refresh',
            'expiresAt': 4102444800000,
            'user': {'id': 'u1', 'email': 'mateus@email.com'},
          },
        }, 200));
    refreshService.client.httpClientAdapter = refreshAdapter;

    final response = await getProfile();

    expect(response.success, isTrue);
    expect(response.data!.username, 'Mateus');
    expect(profileCalls, 2, reason: 'original request + one replay');
    expect(refreshAdapter.calls.single.path, AuthRoutes.refresh);
    // Rotation: both tokens replaced by the pair the server returned.
    expect(tokenManager.accessToken, 'fresh-access');
    expect(tokenManager.refreshToken, 'fresh-refresh');
    expect((await authStorage.read())!.accessToken, 'fresh-access');
  });

  test('a rejected refresh token ends the session', () async {
    tokenManager.setTokens('stale', 'refresh-1');
    var expired = false;
    final unsubscribe = tokenManager.onExpired(() => expired = true);
    addTearDown(unsubscribe);

    mountApi((_) => jsonBody({'success': false, 'message': 'Não autorizado'}, 401));
    refreshService.client.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'success': false, 'code': 'SESSION_REVOKED'}, 401),
    );

    final response = await getProfile();

    expect(response.success, isFalse);
    expect(tokenManager.accessToken, isNull);
    expect(tokenManager.refreshToken, isNull);
    expect(expired, isTrue, reason: 'listeners are told to send the user back to login');
  });

  test('a 5xx during refresh keeps the session so a retry can recover', () async {
    tokenManager.setTokens('stale', 'refresh-1');

    mountApi((_) => jsonBody({'success': false, 'message': 'Não autorizado'}, 401));
    refreshService.client.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'success': false, 'message': 'Servidor indisponível'}, 503),
    );

    final response = await getProfile();

    expect(response.success, isFalse);
    expect(tokenManager.refreshToken, 'refresh-1', reason: 'not logged out by a flaky server');
  });

  test('concurrent 401s share a single refresh call', () async {
    tokenManager.setTokens('stale', 'refresh-1');

    mountApi((options) {
      if (options.headers['Authorization'] == 'Bearer fresh-access') {
        return jsonBody({
          'success': true,
          'data': {'id': 'u1', 'username': 'Mateus', 'email': 'mateus@email.com'},
        }, 200);
      }
      return jsonBody({'success': false, 'message': 'Não autorizado'}, 401);
    });

    final refreshAdapter = FakeAdapter((_) => jsonBody({
          'success': true,
          'data': {
            'accessToken': 'fresh-access',
            'refreshToken': 'fresh-refresh',
            'expiresAt': 4102444800000,
            'user': {'id': 'u1', 'email': 'mateus@email.com'},
          },
        }, 200));
    refreshService.client.httpClientAdapter = refreshAdapter;

    final responses = await Future.wait([getProfile(), getProfile(), getProfile()]);

    expect(responses.every((response) => response.success), isTrue);
    expect(refreshAdapter.calls.length, 1, reason: 'single-flight refresh');
  });

  test('requestData reaches any endpoint by name, with query params', () async {
    mountApi((_) => jsonBody({'success': true, 'message': 'ok'}, 200));

    final response = await requestData<Object?>(
      endpoint: '/qualquer/rota',
      method: 'GET',
      params: {'mes': 3},
      withAuth: false,
    );

    expect(response.success, isTrue);
    expect(apiAdapter.calls.single.path, '/qualquer/rota');
    expect(apiAdapter.calls.single.uri.queryParameters['mes'], '3');
  });
}
