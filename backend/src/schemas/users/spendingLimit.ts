import { z } from "zod"
import { amountField } from "../fields/money"

/** `null` limpa a meta — é assim que o app desfaz o limite de gastos. */
export const UpdateSpendingLimitSchema = z.object({
  spending_limit: amountField.nullable(),
})

export type UpdateSpendingLimitDTO = z.infer<typeof UpdateSpendingLimitSchema>
