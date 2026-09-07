/// Why a request failed when the app never got a usable answer.
enum ApiErrorReason {
  /// Timeout, DNS, offline — the server was never reached.
  networkError,

  /// The server answered, but with 4xx/5xx.
  serverError,
}

/// One field-level validation message, as produced by the backend's
/// `validate` middleware (HTTP 422).
class ApiFieldError {
  const ApiFieldError({required this.field, required this.message});

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  final String field;
  final String message;
}

class ApiFailure {
  const ApiFailure({required this.reason, this.status});

  final ApiErrorReason reason;
  final int? status;
}

/// Normalized envelope for every backend call — the Dart counterpart of the
/// React Native project's `ApiResponse<T>`.
///
/// [requestData] never throws: a failure comes back as `success == false`
/// with a ready-to-show [message], so callers branch on data instead of
/// wrapping every call in a try/catch.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.code,
    this.errors = const [],
    this.error,
  });

  /// Builds the envelope from a decoded JSON body. [parse] turns the `data`
  /// field into `T`; without it, [data] is left null (useful for endpoints
  /// that only answer with a message).
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Object? json)? parse,
  }) {
    final rawErrors = json['errors'];
    final payload = json['data'];

    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: parse != null && payload != null ? parse(payload) : null,
      code: json['code'] as String?,
      errors: rawErrors is List
          ? rawErrors
              .whereType<Map<String, dynamic>>()
              .map(ApiFieldError.fromJson)
              .toList(growable: false)
          : const [],
    );
  }

  /// Failure that never reached a parsed body (network error, or a response
  /// the server sent without the usual envelope).
  const ApiResponse.failure({
    required this.message,
    required ApiFailure this.error,
    this.code,
    this.errors = const [],
  })  : success = false,
        data = null;

  final bool success;
  final String message;
  final T? data;

  /// Backend error code (`SESSION_REVOKED`, `INVALID_CREDENTIALS`, ...) —
  /// see `backend/src/types/code/userCode.ts`.
  final String? code;

  /// Field-level validation messages from a 422.
  final List<ApiFieldError> errors;

  /// Present only when the call failed without a valid business answer.
  final ApiFailure? error;

  bool get isNetworkError => error?.reason == ApiErrorReason.networkError;
  bool get isServerError => error?.reason == ApiErrorReason.serverError;
}
