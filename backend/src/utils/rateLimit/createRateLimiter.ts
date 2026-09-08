import rateLimit, { type Options } from "express-rate-limit"
import { getRateLimitStore } from "./rateLimitStore"

export function createRateLimiter(options: Partial<Options>) {
  const store = getRateLimitStore()

  return rateLimit({
    standardHeaders: true,
    legacyHeaders: false,
    ...(store ? { store } : {}),
    ...options,
  })
}
