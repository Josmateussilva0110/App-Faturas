import '../../models/user_profile.dart';
import '../api/api_response.dart';
import '../api/api_routes.dart';
import '../api/request.dart';

/// Profile endpoints — port of `profile.service.ts`.
///
/// `updateEarningsPercent` from the RN project has no counterpart: this
/// backend exposes no `PATCH /profile/earnings-percent` route.

UserProfile _parseProfile(Object? json) =>
    UserProfile.fromJson((json! as Map).cast<String, dynamic>());

/// `GET /profile`
Future<ApiResponse<UserProfile>> getProfile() {
  return requestData<UserProfile>(
    endpoint: ProfileRoutes.profile,
    parse: _parseProfile,
  );
}

/// `PUT /profile`
Future<ApiResponse<UserProfile>> updateProfile({required String username}) {
  return requestData<UserProfile>(
    endpoint: ProfileRoutes.profile,
    method: 'PUT',
    data: {'username': username},
    parse: _parseProfile,
  );
}

/// `PUT /profile/password`.
///
/// [currentPassword] is optional because the backend also serves the
/// "temporary password" flow, where the user has to set a new one without
/// knowing the old. The new password must satisfy the backend's rules: 8+
/// chars with an uppercase letter, a digit and a symbol.
Future<ApiResponse<Object?>> changePassword({
  required String newPassword,
  required String confirmPassword,
  String? currentPassword,
}) {
  return requestData<Object?>(
    endpoint: ProfileRoutes.password,
    method: 'PUT',
    data: {
      'current_password': ?currentPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    },
  );
}
