import { z } from "zod"

/** Requisitos de complexidade para novas senhas (register). */
export const passwordField = z
    .string()
    .min(8, "Senha deve ter no mínimo 8 caracteres.")
    .max(128, "Senha deve ter no máximo 128 caracteres.")
    .regex(/[A-Z]/, "Senha deve conter ao menos uma letra maiúscula.")
    .regex(/[0-9]/, "Senha deve conter ao menos um número.")
    .regex(/[^A-Za-z0-9]/, "Senha deve conter ao menos um caractere especial.")

/** Login: só exige senha preenchida — contas antigas podem ter senha curta. */
export const loginPasswordField = z
    .string()
    .min(1, "Senha é obrigatória.")
    .max(128, "Senha deve ter no máximo 128 caracteres.")
