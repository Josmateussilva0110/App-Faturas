import { z } from "zod"
import { amountField } from "../fields/money"

/**
 * Mesma faixa de `purchases/purchase.start_abs`: mês absoluto fora dela é bug do
 * cliente, não escolha do usuário.
 */
const monthAbsField = z
  .number()
  .int("Mês inválido.")
  .min(24000, "Mês fora do intervalo permitido.")
  .max(30000, "Mês fora do intervalo permitido.")

/**
 * Não há create e update separados: a identidade da fatura é (cartão, mês),
 * então informar o valor de novo para o mesmo par é a mesma operação.
 */
export const UpsertStatementSchema = z.object({
  card_id: z.string().uuid("Cartão inválido."),
  month_abs: monthAbsField,
  amount: amountField,
})

export const StatementIdParamSchema = z.object({
  id: z.string().uuid("Fatura inválida."),
})

export type UpsertStatementDTO = z.infer<typeof UpsertStatementSchema>
export type StatementIdParam = z.infer<typeof StatementIdParamSchema>
