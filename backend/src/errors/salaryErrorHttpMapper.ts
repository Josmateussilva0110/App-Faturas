import { SalaryErrorCode } from "../types/code/salaryCode"

export const salaryErrorHttpStatusMap: Record<SalaryErrorCode, number> = {
  [SalaryErrorCode.SALARY_NOT_FOUND]: 404,  // Not Found
  [SalaryErrorCode.SALARY_FETCH_FAILED]: 500,
  [SalaryErrorCode.SALARY_CREATE_FAILED]: 500,
  [SalaryErrorCode.SALARY_UPDATE_FAILED]: 500,
  [SalaryErrorCode.SALARY_DELETE_FAILED]: 500,
}
