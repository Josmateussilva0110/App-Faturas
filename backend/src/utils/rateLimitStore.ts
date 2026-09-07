import type { Store } from "express-rate-limit"
import { RedisStore } from "rate-limit-redis"
import { getRedisClient } from "../database/redis/redis"

let sharedStore: Store | undefined

export function getRateLimitStore(): Store | undefined {
  return sharedStore
}

export async function initRateLimitStore(): Promise<void> {
  const redis = await getRedisClient()
  if (!redis) return

  sharedStore = new RedisStore({
    sendCommand: (...args: string[]) => redis.sendCommand(args),
    prefix: "rl:",
  })
}
