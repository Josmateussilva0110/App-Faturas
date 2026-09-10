import { z } from "zod"

const cardBody = z.object({
  name: z
    .string()
    .trim()
    .min(1, "Informe o nome do cartão.")
    .max(60, "Nome deve ter no máximo 60 caracteres."),
})

export const CreateCardSchema = cardBody

/** Editar usa o mesmo campo da criação; um alias impede que divirjam. */
export const UpdateCardSchema = cardBody

export const CardIdParamSchema = z.object({
  id: z.string().uuid("Cartão inválido."),
})

export type CreateCardDTO = z.infer<typeof CreateCardSchema>
export type UpdateCardDTO = z.infer<typeof UpdateCardSchema>
export type CardIdParam = z.infer<typeof CardIdParamSchema>
