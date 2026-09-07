/// The session payload the backend returns from `POST /login` and
/// `POST /auth/refresh` — see `backend/src/types/auth/auth.types.ts`.
class AuthData {
  const AuthData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresAt: (json['expiresAt'] as num?)?.toInt() ?? 0,
      user: AuthUser.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  final String accessToken;
  final String refreshToken;

  /// Expiry as milliseconds since epoch — the backend already multiplies
  /// Supabase's `expires_at` (seconds) by 1000 in `buildAuthTokens`.
  final int expiresAt;

  final AuthUser user;

  bool get isExpired => DateTime.now().millisecondsSinceEpoch >= expiresAt;

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt,
        'user': user.toJson(),
      };
}

class AuthUser {
  const AuthUser({required this.id, required this.email});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  final String id;
  final String email;

  Map<String, dynamic> toJson() => {'id': id, 'email': email};
}
