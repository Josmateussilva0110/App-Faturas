import { ExpenseErrorCode } from "../types/code/expenseCode"

export const expenseErrorHttpStatusMap: Record<ExpenseErrorCode, number> = {
  [ExpenseErrorCode.EXPENSE_NOT_FOUND]: 404,  // Not Found
  [ExpenseErrorCode.EXPENSE_FETCH_FAILED]: 500,
  [ExpenseErrorCode.EXPENSE_CREATE_FAILED]: 500,
  [ExpenseErrorCode.EXPENSE_UPDATE_FAILED]: 500,
  [ExpenseErrorCode.EXPENSE_DELETE_FAILED]: 500,
}
