export interface AuthTokens {
  accessToken: string
  refreshToken: string
  expiresAt: number
  user: {
    id: string
    email: string | undefined
  }
}
