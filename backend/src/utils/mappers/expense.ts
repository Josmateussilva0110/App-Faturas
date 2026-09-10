import { Expense } from "../../types/expenses/expense"

type ExpenseRow = {
  id: string
  name: string
  amount: number | string
}

/**
 * NUMERIC volta como string no driver do Postgres, para não perder precisão.
 * Converter aqui evita que o cliente receba "93.00" onde espera número.
 */
export function mapExpenseRow(row: ExpenseRow): Expense {
  return {
    id: row.id,
    name: row.name,
    amount: Number(row.amount),
  }
}
