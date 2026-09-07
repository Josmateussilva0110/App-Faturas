/// The logged-in user. Static placeholder data until a real auth session
/// exists — see [ProfileScreen]'s "Sair da conta" button.
class AppUser {
  const AppUser({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  AppUser copyWith({String? name, String? email}) {
    return AppUser(id: id, name: name ?? this.name, email: email ?? this.email);
  }
}
