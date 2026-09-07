import { z } from "zod"

/** Letras (incl. acentuadas), números, espaço, ponto, hífen e underscore — sem HTML/tags. */
const USERNAME_PATTERN = /^[a-zA-ZÀ-ÿ0-9._ -]+$/

export const usernameField = z
    .string()
    .trim()
    .min(3, "Nome deve ter no mínimo 3 caracteres.")
    .max(50, "Nome deve ter no máximo 50 caracteres.")
    .regex(USERNAME_PATTERN, "Nome contém caracteres inválidos.")
