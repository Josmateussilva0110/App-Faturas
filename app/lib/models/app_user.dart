/// The logged-in user, from `GET /profile`.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.mustChangePassword = false,
  });

  final String id;
  final String name;
  final String email;

  /// A senha em uso é temporária (ver [UserProfile.mustChangePassword]).
  final bool mustChangePassword;

  AppUser copyWith({String? name, String? email, bool? mustChangePassword}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}
