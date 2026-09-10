import { z } from "zod"

/**
 * Campos de dinheiro compartilhados entre os payloads que os compõem.
 * `entryNameField` serve salários e despesas fixas, que têm a mesma forma;
 * `amountField` vale para qualquer valor monetário do app, e centralizá-lo
 * impede que os limites divirjam de um recurso para outro.
 */

export const entryNameField = z
  .string()
  .trim()
  .min(1, "Informe o nome.")
  .max(60, "Nome deve ter no máximo 60 caracteres.")

/** Mesmo teto de `purchases/purchase`: acima disso é bug do cliente. */
export const amountField = z
  .number()
  .positive("Valor deve ser maior que zero.")
  .max(99_999_999, "Valor muito alto.")
