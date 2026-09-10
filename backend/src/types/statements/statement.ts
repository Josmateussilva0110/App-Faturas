export interface Statement {
  id: string
  card_id: string
  month_abs: number
  amount: number
}

/** Retorno do upsert: o cliente já tem o resto do payload. */
export interface CreatedStatement {
  id: string
}
