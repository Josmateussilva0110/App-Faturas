import { z } from "zod"
import { loginPasswordField } from "../fields/password"

export const LoginSchema = z.object({
  email: z.string().email("Email inválido."),
  password: loginPasswordField,
})
