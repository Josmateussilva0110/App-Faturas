import { createSupabaseClientForUser } from "../database/supabase/supabase"
import { EXPENSE_SELECT } from "../constants/expense.constants"
import { ServiceResult } from "../types/serviceResults/ServiceResult"
import { ExpenseErrorCode } from "../types/code/expenseCode"
import { Expense, CreatedExpense } from "../types/expenses/expense"
import { CreateExpenseDTO, UpdateExpenseDTO } from "../schemas/expenseSchema"
import { getUserIdFromAccessToken } from "../utils/auth/accessToken"
import { mapExpenseRow } from "../utils/mappers/expense"
import { failure } from "../utils/service/serviceResult"

/**
 * O dono sai sempre do token, nunca do corpo da requisição — é o que impede
 * que trocar um id no payload alcance a despesa de outra pessoa. O RLS já
 * barraria, mas filtrar também aqui mantém a intenção explícita no código.
 */
class ExpenseService {

  async list(accessToken: string): Promise<ServiceResult<Expense[], ExpenseErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(ExpenseErrorCode.EXPENSE_FETCH_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      // Ordem de inserção, não alfabética: o app desconta as despesas uma a
      // uma nessa sequência e mostra o saldo corrente sob cada linha, então
      // reordenar aqui mudaria os números que o usuário vê.
      const { data, error } = await supabase
        .from("expenses")
        .select(EXPENSE_SELECT)
        .eq("user_id", userId)
        .order("created_at", { ascending: true })

      if (error || !data) {
        console.error("[ExpenseService.list]", error)
        return failure(ExpenseErrorCode.EXPENSE_FETCH_FAILED, "Erro ao buscar despesas.")
      }

      return { status: true, data: data.map(mapExpenseRow) }
    } catch (error) {
      console.error("[ExpenseService.list] error:", error)
      return failure(ExpenseErrorCode.EXPENSE_FETCH_FAILED, "Erro ao buscar despesas.")
    }
  }

  async getById(
    accessToken: string,
    expenseId: string
  ): Promise<ServiceResult<Expense, ExpenseErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(ExpenseErrorCode.EXPENSE_FETCH_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("expenses")
        .select(EXPENSE_SELECT)
        .eq("id", expenseId)
        .eq("user_id", userId)
        .maybeSingle()

      if (error) {
        console.error("[ExpenseService.getById]", error)
        return failure(ExpenseErrorCode.EXPENSE_FETCH_FAILED, "Erro ao buscar despesa.")
      }

      if (!data) return failure(ExpenseErrorCode.EXPENSE_NOT_FOUND, "Despesa não encontrada.")

      return { status: true, data: mapExpenseRow(data) }
    } catch (error) {
      console.error("[ExpenseService.getById] error:", error)
      return failure(ExpenseErrorCode.EXPENSE_FETCH_FAILED, "Erro ao buscar despesa.")
    }
  }

  async create(
    accessToken: string,
    payload: CreateExpenseDTO
  ): Promise<ServiceResult<CreatedExpense, ExpenseErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(ExpenseErrorCode.EXPENSE_CREATE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("expenses")
        .insert({ ...payload, user_id: userId })
        .select("id")
        .single()

      if (error || !data) {
        console.error("[ExpenseService.create]", error)
        return failure(ExpenseErrorCode.EXPENSE_CREATE_FAILED, "Não foi possível criar a despesa.")
      }

      return { status: true, data: { id: data.id } }
    } catch (error) {
      console.error("[ExpenseService.create] error:", error)
      return failure(ExpenseErrorCode.EXPENSE_CREATE_FAILED, "Erro ao criar despesa.")
    }
  }

  async update(
    accessToken: string,
    expenseId: string,
    payload: UpdateExpenseDTO
  ): Promise<ServiceResult<CreatedExpense, ExpenseErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(ExpenseErrorCode.EXPENSE_UPDATE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("expenses")
        .update(payload)
        .eq("id", expenseId)
        .eq("user_id", userId)
        .select("id")
        .maybeSingle()

      if (error) {
        console.error("[ExpenseService.update]", error)
        return failure(ExpenseErrorCode.EXPENSE_UPDATE_FAILED, "Não foi possível atualizar a despesa.")
      }

      if (!data) return failure(ExpenseErrorCode.EXPENSE_NOT_FOUND, "Despesa não encontrada.")

      return { status: true, data: { id: data.id } }
    } catch (error) {
      console.error("[ExpenseService.update] error:", error)
      return failure(ExpenseErrorCode.EXPENSE_UPDATE_FAILED, "Erro ao atualizar despesa.")
    }
  }

  async remove(
    accessToken: string,
    expenseId: string
  ): Promise<ServiceResult<null, ExpenseErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(ExpenseErrorCode.EXPENSE_DELETE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      // O select é o que distingue "apagou" de "não era sua": sem ele um
      // delete que não casou com nada volta igual a um bem-sucedido.
      const { data, error } = await supabase
        .from("expenses")
        .delete()
        .eq("id", expenseId)
        .eq("user_id", userId)
        .select("id")
        .maybeSingle()

      if (error) {
        console.error("[ExpenseService.remove]", error)
        return failure(ExpenseErrorCode.EXPENSE_DELETE_FAILED, "Não foi possível remover a despesa.")
      }

      if (!data) return failure(ExpenseErrorCode.EXPENSE_NOT_FOUND, "Despesa não encontrada.")

      return { status: true, data: null }
    } catch (error) {
      console.error("[ExpenseService.remove] error:", error)
      return failure(ExpenseErrorCode.EXPENSE_DELETE_FAILED, "Erro ao remover despesa.")
    }
  }
}

export default new ExpenseService()
