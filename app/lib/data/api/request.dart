import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_response.dart';

/// **The one function that talks to the backend.** Give it an endpoint and
/// it handles method, auth header, token refresh, JSON decoding and error
/// normalization — the Dart port of `requestData` from the React Native
/// project.
///
/// It never throws: failures come back as [ApiResponse] with
/// `success == false` and a message that's safe to show the user.
///
/// ```dart
/// final response = await requestData<UserProfile>(
///   endpoint: ProfileRoutes.profile,
///   parse: (json) => UserProfile.fromJson(json! as Map<String, dynamic>),
/// );
/// if (response.success) print(response.data!.username);
/// ```
///
/// [parse] is the piece Axios didn't need: TypeScript erases generics, Dart
/// doesn't, so the caller says how to build `T` from the decoded `data`
/// field. Omit it for endpoints that only answer with a message.
Future<ApiResponse<T>> requestData<T>({
  required String endpoint,
  String method = 'GET',
  Object? data,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool withAuth = true,
  T Function(Object? json)? parse,
}) async {
  try {
    final isGet = method.toUpperCase() == 'GET';

    // GET carries everything in the query string, like the RN version.
    final queryParameters = <String, dynamic>{
      ...?params,
      if (isGet && data is Map) ...data.cast<String, dynamic>(),
    };

    final response = await api.request<dynamic>(
      endpoint,
      data: isGet ? null : data,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      options: Options(
        method: method.toUpperCase(),
        headers: headers,
        extra: {ApiRequestFlags.skipAuth: !withAuth},
      ),
    );

    final body = _asMap(response.data);
    if (body == null) {
      return ApiResponse<T>.failure(
        message: 'Resposta inesperada do servidor.',
        error: ApiFailure(reason: ApiErrorReason.serverError, status: response.statusCode),
      );
    }

    return ApiResponse<T>.fromJson(body, parse: parse);
  } on DioException catch (error) {
    final response = error.response;

    // The server answered (4xx / 5xx).
    if (response != null) {
      final body = _asMap(response.data);
      final errors = _fieldErrors(body);

      return ApiResponse<T>.failure(
        message: errors.isNotEmpty
            ? errors.first.message
            : _messageOf(body) ?? 'Erro ao processar solicitação.',
        code: body?['code'] as String?,
        errors: errors,
        error: ApiFailure(reason: ApiErrorReason.serverError, status: response.statusCode),
      );
    }

    // Timeout / DNS / server unreachable.
    return ApiResponse<T>.failure(
      message: _networkMessage(error),
      error: const ApiFailure(reason: ApiErrorReason.networkError),
    );
  }
}

Map<String, dynamic>? _asMap(Object? body) {
  return body is Map ? body.cast<String, dynamic>() : null;
}

List<ApiFieldError> _fieldErrors(Map<String, dynamic>? body) {
  final raw = body?['errors'];
  if (raw is! List) return const [];

  return raw
      .whereType<Map>()
      .map((entry) => ApiFieldError.fromJson(entry.cast<String, dynamic>()))
      .toList(growable: false);
}

/// Reads the message from either envelope the backend uses: the normal
/// `{ message }` one, or `{ error: { message } }` from `errorHandler`.
String? _messageOf(Map<String, dynamic>? body) {
  final message = body?['message'];
  if (message is String && message.isNotEmpty) return message;

  final error = body?['error'];
  if (error is Map) {
    final nested = error['message'];
    if (nested is String && nested.isNotEmpty) return nested;
  }

  return null;
}

String _networkMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Tempo esgotado ao conectar.';
    case DioExceptionType.cancel:
      return 'Requisição cancelada.';
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      return 'Não foi possível conectar ao servidor. '
          'Tente novamente em alguns instantes.';
  }
}
