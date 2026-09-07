import { UserErrorCode } from "../types/code/userCode"

export const userErrorHttpStatusMap: Record<UserErrorCode, number> = {
  [UserErrorCode.EMAIL_ALREADY_EXISTS]: 409, // Conflict
  [UserErrorCode.CPF_ALREADY_EXISTS]: 409,
  [UserErrorCode.PHONE_ALREADY_EXISTS]: 409,
  [UserErrorCode.USER_NOT_FOUND]: 404,       // Not Found
  [UserErrorCode.INVALID_PASSWORD]: 422,     // Unprocessable Entity
  [UserErrorCode.USER_CREATE_FAILED]: 500,   // Internal Server Error
  [UserErrorCode.LOGIN_FAILED]: 500,
  [UserErrorCode.USER_FETCH_FAILED]: 500,
  [UserErrorCode.USER_DELETE_FAILED]: 500,
  [UserErrorCode.USER_UPDATE_FAILED]: 500,
  [UserErrorCode.INVALID_CREDENTIALS]: 401, // Unauthorized
  [UserErrorCode.SESSION_REVOKED]: 401,
  [UserErrorCode.LOGOUT_FAILED]: 500,
  [UserErrorCode.PASSWORD_RESET_REQUEST_FAILED]: 500,
}
