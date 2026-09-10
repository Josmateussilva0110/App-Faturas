import { createSupabaseClientForUser } from "../database/supabase/supabase"
import { SALARY_SELECT } from "../constants/salary.constants"
import { ServiceResult } from "../types/serviceResults/ServiceResult"
import { SalaryErrorCode } from "../types/code/salaryCode"
import { Salary, CreatedSalary } from "../types/salaries/salary"
import { CreateSalaryDTO, UpdateSalaryDTO } from "../schemas/salaries/salary"
import { getUserIdFromAccessToken } from "../utils/auth/accessToken"
import { mapSalaryRow } from "../utils/mappers/salary"
import { failure } from "../utils/service/serviceResult"

/**
 * O dono sai sempre do token, nunca do corpo da requisição — é o que impede
 * que trocar um id no payload alcance o salário de outra pessoa. O RLS já
 * barraria, mas filtrar também aqui mantém a intenção explícita no código.
 */
class SalaryService {

  async list(accessToken: string): Promise<ServiceResult<Salary[], SalaryErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(SalaryErrorCode.SALARY_FETCH_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      // Ordem de inserção, não alfabética: a tela lista salários e despesas
      // na sequência em que o usuário os cadastrou, e o saldo corrente das
      // despesas é calculado nessa mesma ordem.
      const { data, error } = await supabase
        .from("salaries")
        .select(SALARY_SELECT)
        .eq("user_id", userId)
        .order("created_at", { ascending: true })

      if (error || !data) {
        console.error("[SalaryService.list]", error)
        return failure(SalaryErrorCode.SALARY_FETCH_FAILED, "Erro ao buscar salários.")
      }

      return { status: true, data: data.map(mapSalaryRow) }
    } catch (error) {
      console.error("[SalaryService.list] error:", error)
      return failure(SalaryErrorCode.SALARY_FETCH_FAILED, "Erro ao buscar salários.")
    }
  }

  async getById(
    accessToken: string,
    salaryId: string
  ): Promise<ServiceResult<Salary, SalaryErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(SalaryErrorCode.SALARY_FETCH_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("salaries")
        .select(SALARY_SELECT)
        .eq("id", salaryId)
        .eq("user_id", userId)
        .maybeSingle()

      if (error) {
        console.error("[SalaryService.getById]", error)
        return failure(SalaryErrorCode.SALARY_FETCH_FAILED, "Erro ao buscar salário.")
      }

      if (!data) return failure(SalaryErrorCode.SALARY_NOT_FOUND, "Salário não encontrado.")

      return { status: true, data: mapSalaryRow(data) }
    } catch (error) {
      console.error("[SalaryService.getById] error:", error)
      return failure(SalaryErrorCode.SALARY_FETCH_FAILED, "Erro ao buscar salário.")
    }
  }

  async create(
    accessToken: string,
    payload: CreateSalaryDTO
  ): Promise<ServiceResult<CreatedSalary, SalaryErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(SalaryErrorCode.SALARY_CREATE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("salaries")
        .insert({ ...payload, user_id: userId })
        .select("id")
        .single()

      if (error || !data) {
        console.error("[SalaryService.create]", error)
        return failure(SalaryErrorCode.SALARY_CREATE_FAILED, "Não foi possível criar o salário.")
      }

      return { status: true, data: { id: data.id } }
    } catch (error) {
      console.error("[SalaryService.create] error:", error)
      return failure(SalaryErrorCode.SALARY_CREATE_FAILED, "Erro ao criar salário.")
    }
  }

  async update(
    accessToken: string,
    salaryId: string,
    payload: UpdateSalaryDTO
  ): Promise<ServiceResult<CreatedSalary, SalaryErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(SalaryErrorCode.SALARY_UPDATE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("salaries")
        .update(payload)
        .eq("id", salaryId)
        .eq("user_id", userId)
        .select("id")
        .maybeSingle()

      if (error) {
        console.error("[SalaryService.update]", error)
        return failure(SalaryErrorCode.SALARY_UPDATE_FAILED, "Não foi possível atualizar o salário.")
      }

      if (!data) return failure(SalaryErrorCode.SALARY_NOT_FOUND, "Salário não encontrado.")

      return { status: true, data: { id: data.id } }
    } catch (error) {
      console.error("[SalaryService.update] error:", error)
      return failure(SalaryErrorCode.SALARY_UPDATE_FAILED, "Erro ao atualizar salário.")
    }
  }

  async remove(
    accessToken: string,
    salaryId: string
  ): Promise<ServiceResult<null, SalaryErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(SalaryErrorCode.SALARY_DELETE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      // O select é o que distingue "apagou" de "não era sua": sem ele um
      // delete que não casou com nada volta igual a um bem-sucedido.
      const { data, error } = await supabase
        .from("salaries")
        .delete()
        .eq("id", salaryId)
        .eq("user_id", userId)
        .select("id")
        .maybeSingle()

      if (error) {
        console.error("[SalaryService.remove]", error)
        return failure(SalaryErrorCode.SALARY_DELETE_FAILED, "Não foi possível remover o salário.")
      }

      if (!data) return failure(SalaryErrorCode.SALARY_NOT_FOUND, "Salário não encontrado.")

      return { status: true, data: null }
    } catch (error) {
      console.error("[SalaryService.remove] error:", error)
      return failure(SalaryErrorCode.SALARY_DELETE_FAILED, "Erro ao remover salário.")
    }
  }
}

export default new SalaryService()
