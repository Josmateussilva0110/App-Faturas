import { z } from "zod"

export const PasswordResetRequestSchema = z.object({
  identifier: z
    .string()
    .trim()
    .min(1, "Informe seu e-mail.")
    .max(255, "Identificador muito longo.")
    .email("Digite um e-mail válido."),
})

export type PasswordResetRequestDTO = z.infer<typeof PasswordResetRequestSchema>
