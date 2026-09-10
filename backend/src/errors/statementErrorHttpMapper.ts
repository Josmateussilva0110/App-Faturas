import { StatementErrorCode } from "../types/code/statementCode"

export const statementErrorHttpStatusMap: Record<StatementErrorCode, number> = {
  [StatementErrorCode.STATEMENT_NOT_FOUND]: 404,  // Not Found
  [StatementErrorCode.CARD_NOT_FOUND]: 422,       // cartão informado não é do usuário
  [StatementErrorCode.STATEMENT_FETCH_FAILED]: 500,
  [StatementErrorCode.STATEMENT_SAVE_FAILED]: 500,
  [StatementErrorCode.STATEMENT_DELETE_FAILED]: 500,
}
