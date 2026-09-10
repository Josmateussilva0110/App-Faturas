import { z } from "zod"

export const RefreshSchema = z.object({
  refreshToken: z
    .string()
    .min(1, "refreshToken é obrigatório.")
    .max(2048, "refreshToken inválido."),
})
