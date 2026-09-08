export interface Purchase {
  id: string
  card_id: string | null
  name: string
  amount: number
  installments: number
  is_other: boolean
  person: string
  start_abs: number
}

/** Retorno de create e update: o cliente já tem o resto do payload. */
export interface CreatedPurchase {
  id: string
}
