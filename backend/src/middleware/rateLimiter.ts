import { createRateLimiter } from "../utils/createRateLimiter"

/**
 * Com REDIS_URL: contadores compartilhados entre instâncias.
 * Sem Redis: MemoryStore (reset a cada deploy/restart).
 */
export const rateLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: {
    success: false,
    message: "Muitas requisições. Tente novamente em 15 minutos.",
  },
})
