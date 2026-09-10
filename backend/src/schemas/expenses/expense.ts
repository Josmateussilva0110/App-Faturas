import { z } from "zod"
import { amountField, entryNameField } from "../fields/money"

const expenseBody = z.object({
  name: entryNameField,
  amount: amountField,
})

export const CreateExpenseSchema = expenseBody

/** Editar usa os mesmos campos da criação; um alias impede que divirjam. */
export const UpdateExpenseSchema = expenseBody

export const ExpenseIdParamSchema = z.object({
  id: z.string().uuid("Despesa inválida."),
})

export type CreateExpenseDTO = z.infer<typeof CreateExpenseSchema>
export type UpdateExpenseDTO = z.infer<typeof UpdateExpenseSchema>
export type ExpenseIdParam = z.infer<typeof ExpenseIdParamSchema>
