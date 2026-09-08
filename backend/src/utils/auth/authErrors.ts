export type AuthProviderError = {
  message?: string
  code?: string
} | null

export function isRefreshTokenReuseOrRevoked(error: AuthProviderError) {
  if (!error) return false

  const message = (error.message ?? "").toLowerCase()
  const code = (error.code ?? "").toLowerCase()

  return (
    code.includes("refresh_token") ||
    message.includes("already used") ||
    message.includes("not found") ||
    message.includes("invalid refresh")
  )
}
