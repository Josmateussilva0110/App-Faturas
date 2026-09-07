import crypto from "crypto"
import jwt from "jsonwebtoken"
import { getRedisClient } from "../database/redis/redis"

const revokedTokenHashes = new Map<string, number>()
const revokedUsers = new Map<string, number>()

const DEFAULT_USER_REVOKE_TTL_MS = 60 * 60 * 1000
const TOKEN_KEY_PREFIX = "revoked:token:"
const USER_KEY_PREFIX = "revoked:user:"

function pruneExpired(): void {
  const now = Date.now()

  for (const [hash, expMs] of revokedTokenHashes) {
    if (expMs <= now) revokedTokenHashes.delete(hash)
  }

  for (const [userId, untilMs] of revokedUsers) {
    if (untilMs <= now) revokedUsers.delete(userId)
  }
}

function hashToken(token: string): string {
  return crypto.createHash("sha256").update(token).digest("hex")
}

function tokenTtlSeconds(exp: number): number {
  return Math.max(1, exp - Math.floor(Date.now() / 1000))
}

export async function revokeAccessToken(token: string): Promise<void> {
  const payload = jwt.decode(token) as { exp?: number } | null
  if (!payload?.exp) return

  const hash = hashToken(token)
  const redis = await getRedisClient()

  if (redis) {
    await redis.setEx(`${TOKEN_KEY_PREFIX}${hash}`, tokenTtlSeconds(payload.exp), "1")
    return
  }

  revokedTokenHashes.set(hash, payload.exp * 1000)
  pruneExpired()
}

export async function revokeUserSessions(
  userId: string,
  ttlMs = DEFAULT_USER_REVOKE_TTL_MS
): Promise<void> {
  const redis = await getRedisClient()
  const ttlSeconds = Math.max(1, Math.ceil(ttlMs / 1000))

  if (redis) {
    await redis.setEx(`${USER_KEY_PREFIX}${userId}`, ttlSeconds, "1")
    return
  }

  revokedUsers.set(userId, Date.now() + ttlMs)
  pruneExpired()
}

export async function isAccessTokenRevoked(token: string): Promise<boolean> {
  const hash = hashToken(token)
  const redis = await getRedisClient()

  if (redis) {
    const exists = await redis.exists(`${TOKEN_KEY_PREFIX}${hash}`)
    return exists === 1
  }

  pruneExpired()
  const expMs = revokedTokenHashes.get(hash)
  if (!expMs) return false
  return Date.now() < expMs
}

export async function isUserSessionRevoked(userId: string): Promise<boolean> {
  const redis = await getRedisClient()

  if (redis) {
    const exists = await redis.exists(`${USER_KEY_PREFIX}${userId}`)
    return exists === 1
  }

  pruneExpired()
  const untilMs = revokedUsers.get(userId)
  if (!untilMs) return false
  return Date.now() < untilMs
}
