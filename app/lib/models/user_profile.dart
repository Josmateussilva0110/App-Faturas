/// The account payload from `GET /profile` and `PUT /profile`.
///
/// O backend seleciona mais colunas do que devolve: `mapUserProfileRow`
/// estreita a linha para estes campos, então `earnings_percent` (presente no
/// projeto React Native) **não** chega aqui.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.spendingLimit,
    this.mustChangePassword = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      spendingLimit: (json['spending_limit'] as num?)?.toDouble(),
      mustChangePassword: json['must_change_password'] as bool? ?? false,
    );
  }

  final String id;
  final String username;
  final String email;

  /// Meta mensal de gastos, ou null quando o usuário não definiu uma. Vem
  /// junto do perfil para o app não precisar de uma segunda requisição só
  /// para lê-la no boot.
  final double? spendingLimit;

  /// A senha em uso é temporária: alguém atendeu a solicitação de reset à
  /// mão e marcou a conta. O app prende o usuário na troca de senha até ele
  /// definir uma própria.
  ///
  /// Falso por omissão de propósito — se o campo não vier, o certo é deixar
  /// entrar, e não trancar todo mundo para fora.
  final bool mustChangePassword;
}
