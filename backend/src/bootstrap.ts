import { initRedis, closeRedis } from "./database/redis/redis"
import { initRateLimitStore } from "./utils/rateLimitStore"

export async function bootstrapInfrastructure(): Promise<void> {
  await initRedis()
  await initRateLimitStore()
}

export async function shutdownInfrastructure(): Promise<void> {
  await closeRedis()
}

export { closeRedis }
