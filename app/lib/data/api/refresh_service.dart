import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/config/env.dart';
import '../../models/auth_data.dart';
import 'api_routes.dart';
import 'auth_storage.dart';
import 'token_manager.dart';

/// Thrown when a refresh couldn't produce a usable session.
class RefreshFailure implements Exception {
  const RefreshFailure(this.message);
  final String message;

  @override
  String toString() => 'RefreshFailure: $message';
}

/// Owns token rotation. Port of `refresh.service.ts`.
///
/// Two rules carry over from the RN version and matter a lot:
/// * **single flight** — concurrent 401s share one refresh call instead of
///   each firing their own and racing to overwrite the token pair;
/// * **the session is only cleared on a real auth failure** — a timeout, a
///   429, or a 5xx (Render waking up) leaves the tokens alone so the user
///   isn't logged out by a flaky network.
class RefreshService {
  RefreshService({Dio? client})
      : client = client ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.refreshTimeout,
              receiveTimeout: ApiConfig.refreshTimeout,
              headers: const {'Content-Type': 'application/json'},
            ));

  /// Deliberately a bare Dio with no interceptors: refreshing through the
  /// main client would recurse back into the 401 handler.
  final Dio client;

  Future<AuthData?>? _inFlight;

  Future<void> _clearLocalSession() async {
    tokenManager.clearTokens();
    tokenManager.notifyExpired();
    await authStorage.remove();
  }

  /// Refreshes the session, joining an in-flight attempt when there is one.
  Future<AuthData> refresh(String refreshToken) async {
    final pending = _inFlight;
    if (pending != null) {
      final joined = await pending;
      if (joined == null) throw const RefreshFailure('Refresh falhou');
      return joined;
    }

    final work = _execute(refreshToken);
    _inFlight = work;

    try {
      final result = await work;
      if (result == null) throw const RefreshFailure('Refresh inválido');
      return result;
    } finally {
      _inFlight = null;
    }
  }

  Future<AuthData?> _execute(String refreshToken) async {
    final work = _performRefresh(refreshToken);
    // Publish the attempt so `waitRefresh` can park on it; swallow the
    // outcome there, since this method already handles it.
    tokenManager.startRefresh(work.then((_) {}, onError: (_) {}));

    try {
      return await work;
    } finally {
      tokenManager.finishRefresh();
    }
  }

  bool _isAuthFailure(int? status, String? code) {
    if (status == 401 || status == 403) return true;
    return code == 'SESSION_REVOKED' || code == 'INVALID_CREDENTIALS';
  }

  Future<AuthData?> _performRefresh(String refreshToken) async {
    try {
      final response = await client.post<Map<String, dynamic>>(
        AuthRoutes.refresh,
        data: {'refreshToken': refreshToken},
      );

      final body = response.data ?? const <String, dynamic>{};
      final payload = (body['data'] as Map?)?.cast<String, dynamic>();
      final auth = payload == null ? null : AuthData.fromJson(payload);

      if (body['success'] != true || auth == null || auth.accessToken.isEmpty || auth.refreshToken.isEmpty) {
        if (_isAuthFailure(null, body['code'] as String?)) {
          await _clearLocalSession();
        }
        return null;
      }

      // Rotation: always replace both tokens with the returned pair.
      tokenManager.setTokens(auth.accessToken, auth.refreshToken);
      await authStorage.save(auth);
      tokenManager.notifyRefreshed(auth.accessToken, auth.refreshToken, auth.expiresAt);

      return auth;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final body = error.response?.data;
      final code = body is Map ? body['code'] as String? : null;

      // Server never answered, rate limited, or broke: keep the session and
      // let the caller retry later.
      if (error.response == null || status == 429 || (status != null && status >= 500)) {
        return null;
      }

      if (_isAuthFailure(status, code)) {
        await _clearLocalSession();
      }

      return null;
    }
  }

  /// Restores a stored session at app boot, refreshing it when expired.
  /// Returns null when the session is gone and the user must log in again.
  Future<AuthData?> initialize(AuthData auth) async {
    if (!auth.isExpired) {
      tokenManager.setTokens(auth.accessToken, auth.refreshToken);
      return auth;
    }

    try {
      return await refresh(auth.refreshToken);
    } on RefreshFailure {
      return null;
    }
  }

  /// Central logout: used both by the user action and by the interceptor
  /// when the refresh token is rejected.
  Future<void> logout() async {
    _inFlight = null;
    await _clearLocalSession();
  }
}

final RefreshService refreshService = RefreshService();
