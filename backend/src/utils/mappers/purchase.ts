import { Purchase } from "../../types/purchases/purchase"

type PurchaseRow = {
  id: string
  card_id: string | null
  name: string
  amount: number | string
  installments: number
  is_other: boolean
  person: string | null
  start_abs: number
}

/**
 * NUMERIC volta como string no driver do Postgres, para não perder precisão.
 * Converter aqui evita que o cliente receba "150.00" onde espera número.
 */
export function mapPurchaseRow(row: PurchaseRow): Purchase {
  return {
    id: row.id,
    card_id: row.card_id,
    name: row.name,
    amount: Number(row.amount),
    installments: row.installments,
    is_other: row.is_other,
    person: row.person ?? "",
    start_abs: row.start_abs,
  }
}
