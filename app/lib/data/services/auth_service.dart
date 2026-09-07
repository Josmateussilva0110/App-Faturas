import '../../models/auth_data.dart';
import '../api/api_response.dart';
import '../api/api_routes.dart';
import '../api/auth_storage.dart';
import '../api/refresh_service.dart';
import '../api/request.dart';
import '../api/token_manager.dart';

/// Auth endpoints, each one a thin call over [requestData] — port of
/// `auth.service.ts`.
///
/// There's no `registerUser` here: this backend has no register route
/// (`backend/src/routes/userRoutes.ts`), accounts are created directly in
/// Supabase Auth.

/// `POST /login`. On success, hand the result to [startSession] to make the
/// tokens active for every later call.
Future<ApiResponse<AuthData>> loginUser({
  required String email,
  required String password,
}) {
  return requestData<AuthData>(
    endpoint: AuthRoutes.login,
    method: 'POST',
    data: {'email': email, 'password': password},
    withAuth: false,
    parse: (json) => AuthData.fromJson((json! as Map).cast<String, dynamic>()),
  );
}

/// `POST /logout` — revokes the token server-side. Call [endSession]
/// afterwards to drop it locally too.
Future<ApiResponse<Object?>> logoutUser() {
  return requestData<Object?>(endpoint: AuthRoutes.logout, method: 'POST');
}

/// `POST /auth/refresh`. Regular calls don't need this — the interceptor in
/// `api_client.dart` refreshes on a 401 by itself; use it only to refresh
/// deliberately.
Future<ApiResponse<AuthData>> refreshAccessToken(String refreshToken) {
  return requestData<AuthData>(
    endpoint: AuthRoutes.refresh,
    method: 'POST',
    data: {'refreshToken': refreshToken},
    withAuth: false,
    parse: (json) => AuthData.fromJson((json! as Map).cast<String, dynamic>()),
  );
}

/// `POST /auth/password-reset-request`. The backend takes `identifier` (an
/// email) and answers that the team will make contact — there's no
/// self-service reset link.
Future<ApiResponse<Object?>> requestPasswordReset(String identifier) {
  return requestData<Object?>(
    endpoint: AuthRoutes.passwordResetRequest,
    method: 'POST',
    data: {'identifier': identifier.trim().toLowerCase()},
    withAuth: false,
  );
}

// ── Session plumbing ───────────────────────────────────────────────────
// The RN project did this inside its auth context; keeping it next to the
// auth calls means a caller never has to touch TokenManager directly.

/// Makes [auth] the active session and persists it.
Future<void> startSession(AuthData auth) async {
  tokenManager.setTokens(auth.accessToken, auth.refreshToken);
  await authStorage.save(auth);
}

/// Drops the local session (tokens, storage) and notifies listeners.
Future<void> endSession() => refreshService.logout();

/// Restores a stored session at boot, refreshing it when it has expired.
/// Returns null when there's nothing usable and the user must log in.
Future<AuthData?> restoreSession() async {
  final stored = await authStorage.read();
  if (stored == null) return null;

  return refreshService.initialize(stored);
}
