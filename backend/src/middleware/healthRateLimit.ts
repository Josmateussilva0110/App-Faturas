import { createRateLimiter } from "../utils/createRateLimiter"

/** Protege health checks contra abuso; limite generoso para probes de cloud (Render, etc.). */
export const healthRateLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 60,
  message: {
    success: false,
    message: "Muitas requisições ao health check.",
  },
})
