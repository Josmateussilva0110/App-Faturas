import { z } from "zod"
import { loginPasswordField } from "./passwordSchema"

export const LoginSchema = z.object({
  email: z.string().email("Email inválido."),
  password: loginPasswordField,
})
