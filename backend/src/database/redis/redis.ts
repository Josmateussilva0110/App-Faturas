import { createClient, type RedisClientType } from "redis"
import { env } from "../../config/env"

let client: RedisClientType | null = null
let connectPromise: Promise<RedisClientType | null> | null = null

export async function initRedis(): Promise<RedisClientType | null> {
  if (!env.REDIS_URL) return null

  if (client?.isOpen) return client

  if (connectPromise) return connectPromise

  connectPromise = (async () => {
    try {
      const redis = createClient({ url: env.REDIS_URL })
      redis.on("error", (error) => {
        console.error("[Redis] erro de conexão:", error)
      })
      await redis.connect()
      client = redis as RedisClientType
      console.log("✅ Redis conectado (rate limit + revogação de tokens)")
      return client
    } catch (error) {
      console.error("[Redis] falha ao conectar — usando store em memória:", error)
      return null
    } finally {
      connectPromise = null
    }
  })()

  return connectPromise
}

export async function getRedisClient(): Promise<RedisClientType | null> {
  if (!env.REDIS_URL) return null
  if (client?.isOpen) return client
  return initRedis()
}

export async function closeRedis(): Promise<void> {
  if (client?.isOpen) {
    await client.quit()
  }
  client = null
}
