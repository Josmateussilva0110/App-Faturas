export interface Expense {
  id: string
  name: string
  amount: number
}

/** Retorno de create e update: o cliente já tem o resto do payload. */
export interface CreatedExpense {
  id: string
}
