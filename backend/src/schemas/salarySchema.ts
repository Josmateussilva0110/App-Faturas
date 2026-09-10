import { z } from "zod"
import { amountField, entryNameField } from "./moneyEntrySchema"

const salaryBody = z.object({
  name: entryNameField,
  amount: amountField,
})

export const CreateSalarySchema = salaryBody

/** Editar usa os mesmos campos da criação; um alias impede que divirjam. */
export const UpdateSalarySchema = salaryBody

export const SalaryIdParamSchema = z.object({
  id: z.string().uuid("Salário inválido."),
})

export type CreateSalaryDTO = z.infer<typeof CreateSalarySchema>
export type UpdateSalaryDTO = z.infer<typeof UpdateSalarySchema>
export type SalaryIdParam = z.infer<typeof SalaryIdParamSchema>
