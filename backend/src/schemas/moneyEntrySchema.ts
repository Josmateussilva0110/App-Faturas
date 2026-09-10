import { z } from "zod"

/**
 * Campos comuns a salários e despesas fixas: as duas entidades têm a mesma
 * forma, e um par de campos compartilhados impede que os limites divirjam
 * entre os dois recursos.
 */

export const entryNameField = z
  .string()
  .trim()
  .min(1, "Informe o nome.")
  .max(60, "Nome deve ter no máximo 60 caracteres.")

/** Mesmo teto de `purchaseSchema`: acima disso é bug do cliente. */
export const amountField = z
  .number()
  .positive("Valor deve ser maior que zero.")
  .max(99_999_999, "Valor muito alto.")
