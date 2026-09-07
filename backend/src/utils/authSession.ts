import { AuthTokens } from "../types/auth/auth.types"

type AuthSession = {
  access_token: string
  refresh_token: string
  expires_at?: number
}

type AuthUser = {
  id: string
  email?: string | null
}

export function buildAuthTokens(session: AuthSession, user: AuthUser): AuthTokens {
  const expiresAtSec = session.expires_at ?? 0

  return {
    accessToken: session.access_token,
    refreshToken: session.refresh_token,
    expiresAt: expiresAtSec * 1000,
    user: {
      id: user.id,
      email: user.email ?? "",
    },
  }
}
