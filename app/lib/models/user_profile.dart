/// The account payload from `GET /profile` and `PUT /profile`.
///
/// The backend selects more columns than it returns — `mapUserProfileRow`
/// narrows the row down to these fields, so `earnings_percent` and
/// `must_change_password` (present in the React Native project's profile
/// type) are **not** available here.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.spendingLimit,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      spendingLimit: (json['spending_limit'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String username;
  final String email;

  /// Meta mensal de gastos, ou null quando o usuário não definiu uma. Vem
  /// junto do perfil para o app não precisar de uma segunda requisição só
  /// para lê-la no boot.
  final double? spendingLimit;
}
