import { Statement } from "../../types/statements/statement"

type StatementRow = {
  id: string
  card_id: string
  month_abs: number
  amount: number | string
}

/**
 * NUMERIC volta como string no driver do Postgres, para não perder precisão.
 * Converter aqui evita que o cliente receba "1193.87" onde espera número —
 * e a conferência compara justamente esse valor com o total somado no app.
 */
export function mapStatementRow(row: StatementRow): Statement {
  return {
    id: row.id,
    card_id: row.card_id,
    month_abs: row.month_abs,
    amount: Number(row.amount),
  }
}
