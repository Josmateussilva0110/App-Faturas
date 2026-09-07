import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/env.dart';
import 'api_routes.dart';
import 'refresh_service.dart';
import 'token_manager.dart';

/// Keys used on [RequestOptions.extra] — Dart's stand-in for the
/// `_skipAuth` / `_retry` flags the RN project declared on Axios' config.
class ApiRequestFlags {
  const ApiRequestFlags._();

  /// Skip the Authorization header (login, refresh, password reset).
  static const String skipAuth = 'skipAuth';

  /// Marks a request already replayed after a refresh, so a second 401
  /// can't loop.
  static const String retry = 'retry';
}

/// The configured HTTP client. Port of `api.ts`: same base URL, same
/// interceptor pair, same "refresh once, then replay the request" flow.
final Dio api = _buildApi();

Dio _buildApi() {
  // Which backend the app ended up talking to is invisible otherwise: a
  // missing --dart-define-from-file silently falls back to the emulator
  // address and every call just times out.
  assert(() {
    debugPrint('[api] baseUrl: ${ApiConfig.baseUrl}');
    return true;
  }());

  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: const {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(
    InterceptorsWrapper(
      // ── Request ──────────────────────────────────────────────────────
      onRequest: (options, handler) async {
        if (options.extra[ApiRequestFlags.skipAuth] == true) {
          return handler.next(options);
        }

        // Critical: park until any in-flight refresh settles, so we never
        // send a token we already know is being replaced.
        await tokenManager.waitRefresh();

        final token = tokenManager.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },

      // ── Response errors ──────────────────────────────────────────────
      onError: (error, handler) async {
        final original = error.requestOptions;
        final status = error.response?.statusCode;
        final isRefreshEndpoint = original.path.contains(AuthRoutes.refresh);

        // The refresh token itself was rejected — the session is over.
        if (isRefreshEndpoint && (status == 401 || status == 403)) {
          await refreshService.logout();
          return handler.next(error);
        }

        // Refresh timed out (server asleep): keep the session, fail the call.
        if (isRefreshEndpoint && error.response == null) {
          return handler.next(error);
        }

        final skipAuth = original.extra[ApiRequestFlags.skipAuth] == true;
        final alreadyRetried = original.extra[ApiRequestFlags.retry] == true;

        if (status != 401 || skipAuth || alreadyRetried) {
          return handler.next(error);
        }

        final refreshToken = tokenManager.refreshToken;
        if (refreshToken == null || refreshToken.isEmpty) {
          await refreshService.logout();
          return handler.next(error);
        }

        try {
          original.extra[ApiRequestFlags.retry] = true;

          final session = await refreshService.refresh(refreshToken);
          original.headers['Authorization'] = 'Bearer ${session.accessToken}';

          final response = await dio.fetch<dynamic>(original);
          return handler.resolve(response);
        } catch (_) {
          // Still holding a refresh token means the failure was transient
          // (network/5xx); don't drop the session over it.
          if (tokenManager.refreshToken != null) {
            return handler.next(error);
          }

          await refreshService.logout();
          return handler.next(error);
        }
      },
    ),
  );

  return dio;
}
