/// Every backend endpoint in one place, mirroring `@/config/api-routes` from
/// the React Native project. Paths are relative to [ApiConfig.baseUrl]
/// (which already includes the `/api` prefix mounted in `backend/src/app.ts`).
///
/// Note there is **no register route**: this backend creates accounts
/// straight in Supabase Auth, so the RN project's `AUTH_ROUTES.register` has
/// no counterpart here.
class AuthRoutes {
  const AuthRoutes._();

  static const String login = '/login';
  static const String logout = '/logout';
  static const String refresh = '/auth/refresh';
  static const String passwordResetRequest = '/auth/password-reset-request';
}

class ProfileRoutes {
  const ProfileRoutes._();

  static const String profile = '/profile';
  static const String password = '/profile/password';
}

class CardRoutes {
  const CardRoutes._();

  static const String cards = '/cards';

  static String card(String id) => '/cards/$id';
}

class PurchaseRoutes {
  const PurchaseRoutes._();

  static const String purchases = '/purchases';

  static String purchase(String id) => '/purchases/$id';
}
