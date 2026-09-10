import { z } from "zod"

/**
 * Mês absoluto (year * 12 + mês0). A faixa cobre os anos 2000–2500 e serve
 * de sanidade: valor fora disso é bug do cliente, não escolha do usuário.
 */
const startAbsField = z
  .number()
  .int("Mês inválido.")
  .min(24000, "Data fora do intervalo permitido.")
  .max(30000, "Data fora do intervalo permitido.")

const purchaseFields = {
  name: z
    .string()
    .trim()
    .min(1, "Informe o nome da compra.")
    .max(120, "Nome deve ter no máximo 120 caracteres."),
  amount: z
    .number()
    .positive("Valor deve ser maior que zero.")
    .max(99_999_999, "Valor muito alto."),
  installments: z
    .number()
    .int("Número de parcelas inválido.")
    .min(1, "A compra deve ter ao menos 1 parcela.")
    .max(120, "Máximo de 120 parcelas."),
  is_other: z.boolean(),
  person: z.string().trim().max(80, "Nome deve ter no máximo 80 caracteres.").default(""),
  card_id: z.string().uuid("Cartão inválido."),
  start_abs: startAbsField,
}

/**
 * Espelha a regra do formulário e a CHECK constraint da tabela: compra de
 * outra pessoa precisa de nome, compra própria não guarda nome nenhum.
 * Validar aqui devolve 422 apontando o campo, em vez de deixar o banco
 * responder com erro genérico de constraint.
 */
const purchaseBody = z.object(purchaseFields).superRefine((data, ctx) => {
  if (data.is_other && data.person.length === 0) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      path: ["person"],
      message: "Informe quem fez a compra.",
    })
  }
})

export const CreatePurchaseSchema = purchaseBody

/** Editar usa os mesmos campos do formulário; um alias impede que divirjam. */
export const UpdatePurchaseSchema = purchaseBody

export const PurchaseIdParamSchema = z.object({
  id: z.string().uuid("Compra inválida."),
})

export type CreatePurchaseDTO = z.infer<typeof CreatePurchaseSchema>
export type UpdatePurchaseDTO = z.infer<typeof UpdatePurchaseSchema>
export type PurchaseIdParam = z.infer<typeof PurchaseIdParamSchema>
