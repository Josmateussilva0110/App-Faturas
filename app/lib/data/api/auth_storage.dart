import '../../models/auth_data.dart';

/// Where the session survives between app launches — the counterpart of the
/// RN project's `@/storage/auth.storage`.
///
/// That file wasn't part of the ported set, so the default below keeps the
/// session in memory: everything works within a run, but a restart lands on
/// the login screen. Swapping in a real implementation (shared_preferences,
/// or flutter_secure_storage for the refresh token) means writing one class
/// and assigning it to [authStorage] before `runApp`.
abstract class AuthStorage {
  Future<AuthData?> read();
  Future<void> save(AuthData auth);
  Future<void> remove();
}

class InMemoryAuthStorage implements AuthStorage {
  AuthData? _auth;

  @override
  Future<AuthData?> read() async => _auth;

  @override
  Future<void> save(AuthData auth) async => _auth = auth;

  @override
  Future<void> remove() async => _auth = null;
}

/// Swap this at boot to change how the session is persisted.
AuthStorage authStorage = InMemoryAuthStorage();
