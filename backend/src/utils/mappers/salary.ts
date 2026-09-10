import { Salary } from "../../types/salaries/salary"

type SalaryRow = {
  id: string
  name: string
  amount: number | string
}

/**
 * NUMERIC volta como string no driver do Postgres, para não perder precisão.
 * Converter aqui evita que o cliente receba "1600.00" onde espera número.
 */
export function mapSalaryRow(row: SalaryRow): Salary {
  return {
    id: row.id,
    name: row.name,
    amount: Number(row.amount),
  }
}
