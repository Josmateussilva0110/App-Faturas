import 'dart:async';

/// Called after a successful refresh, so listeners can persist the new pair.
typedef OnRefreshedCallback = void Function(
  String accessToken,
  String refreshToken,
  int expiresAt,
);

typedef OnExpiredCallback = void Function();

/// In-memory holder for the session tokens plus the coordination primitives
/// that keep concurrent requests from stampeding the refresh endpoint.
///
/// Direct port of the React Native project's `token.manager.ts`. Tokens live
/// only in memory on purpose — persistence is [AuthStorage]'s job.
class TokenManager {
  String? _accessToken;
  String? _refreshToken;

  bool _refreshing = false;
  Future<void>? _refreshFuture;

  final _refreshedListeners = <OnRefreshedCallback>{};
  final _expiredListeners = <OnExpiredCallback>{};

  // ── Tokens ───────────────────────────────────────────────────────────
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  void setTokens(String access, String refresh) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  // ── Refresh coordination ─────────────────────────────────────────────
  bool get isRefreshing => _refreshing;

  /// Called by [RefreshService] when a refresh starts.
  void startRefresh(Future<void> work) {
    _refreshing = true;
    _refreshFuture = work;
  }

  void finishRefresh() {
    _refreshing = false;
    _refreshFuture = null;
  }

  /// Any request can park here until an in-flight refresh settles — this is
  /// what stops calls from going out with a token that's already stale at
  /// app boot.
  Future<void> waitRefresh() async {
    final pending = _refreshFuture;
    if (pending == null) return;

    try {
      await pending;
    } catch (_) {
      // Whoever started the refresh handles its error.
    }
  }

  // ── Listeners ────────────────────────────────────────────────────────
  /// Registers [callback]; the returned function unregisters it.
  void Function() onRefreshed(OnRefreshedCallback callback) {
    _refreshedListeners.add(callback);
    return () => _refreshedListeners.remove(callback);
  }

  void Function() onExpired(OnExpiredCallback callback) {
    _expiredListeners.add(callback);
    return () => _expiredListeners.remove(callback);
  }

  void notifyRefreshed(String accessToken, String refreshToken, int expiresAt) {
    for (final listener in _refreshedListeners.toList()) {
      listener(accessToken, refreshToken, expiresAt);
    }
  }

  void notifyExpired() {
    for (final listener in _expiredListeners.toList()) {
      listener();
    }
  }
}

/// App-wide instance, matching the singleton the RN project exports.
final TokenManager tokenManager = TokenManager();
