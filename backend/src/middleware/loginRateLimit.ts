import { createRateLimiter } from "../utils/createRateLimiter"

export const loginRateLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true,
  message: {
    success: false,
    message: "Muitas tentativas. Tente novamente em 15 minutos.",
  },
})
