import { createSupabaseClientForUser } from "../database/supabase/supabase"
import { STATEMENT_SELECT } from "../constants/statement.constants"
import { ServiceResult } from "../types/serviceResults/ServiceResult"
import { StatementErrorCode } from "../types/code/statementCode"
import { Statement, CreatedStatement } from "../types/statements/statement"
import { UpsertStatementDTO } from "../schemas/statements/statement"
import { getUserIdFromAccessToken } from "../utils/auth/accessToken"
import { mapStatementRow } from "../utils/mappers/statement"
import { failure } from "../utils/service/serviceResult"
import { isForeignKeyViolation } from "../utils/service/supabaseErrors"

/**
 * O valor da fatura que o banco mostra, por cartão e por mês. O app compara
 * com o total das parcelas que caem naquele mês para dizer se bate.
 *
 * O dono sai sempre do token, nunca do corpo da requisição — é o que impede
 * que trocar um id no payload alcance a fatura de outra pessoa.
 */
class StatementService {

  async list(accessToken: string): Promise<ServiceResult<Statement[], StatementErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(StatementErrorCode.STATEMENT_FETCH_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      // Sem filtro de mês: é uma linha por cartão por mês, então a lista
      // inteira cabe num payload pequeno e o app navega entre meses sem
      // pedir nada de novo à rede.
      const { data, error } = await supabase
        .from("card_statements")
        .select(STATEMENT_SELECT)
        .eq("user_id", userId)
        .order("month_abs", { ascending: false })

      if (error || !data) {
        console.error("[StatementService.list]", error)
        return failure(StatementErrorCode.STATEMENT_FETCH_FAILED, "Erro ao buscar faturas.")
      }

      return { status: true, data: data.map(mapStatementRow) }
    } catch (error) {
      console.error("[StatementService.list] error:", error)
      return failure(StatementErrorCode.STATEMENT_FETCH_FAILED, "Erro ao buscar faturas.")
    }
  }

  /**
   * Grava o valor da fatura de um (cartão, mês). Informar de novo o mesmo
   * par sobrescreve, em vez de criar uma segunda linha — quem garante isso é
   * o índice único, e não uma leitura antes da escrita, que deixaria brecha
   * para duas requisições simultâneas.
   */
  async upsert(
    accessToken: string,
    payload: UpsertStatementDTO
  ): Promise<ServiceResult<CreatedStatement, StatementErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(StatementErrorCode.STATEMENT_SAVE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      // Confere a posse do cartão explicitamente: o RLS esconde o cartão de
      // outro usuário desta consulta, então não achar significa "não é seu".
      // A FK sozinha não bastaria — ela valida que o cartão existe, não que
      // ele é de quem está pedindo.
      const { data: card, error: cardError } = await supabase
        .from("cards")
        .select("id")
        .eq("id", payload.card_id)
        .eq("user_id", userId)
        .maybeSingle()

      if (cardError) {
        console.error("[StatementService.upsert] card lookup", cardError)
        return failure(StatementErrorCode.STATEMENT_SAVE_FAILED, "Não foi possível salvar a fatura.")
      }

      if (!card) return failure(StatementErrorCode.CARD_NOT_FOUND, "Cartão não encontrado.")

      const { data, error } = await supabase
        .from("card_statements")
        .upsert({ ...payload, user_id: userId }, { onConflict: "card_id,month_abs" })
        .select("id")
        .single()

      if (error || !data) {
        if (isForeignKeyViolation(error)) {
          return failure(StatementErrorCode.CARD_NOT_FOUND, "Cartão não encontrado.")
        }

        console.error("[StatementService.upsert]", error)
        return failure(StatementErrorCode.STATEMENT_SAVE_FAILED, "Não foi possível salvar a fatura.")
      }

      return { status: true, data: { id: data.id } }
    } catch (error) {
      console.error("[StatementService.upsert] error:", error)
      return failure(StatementErrorCode.STATEMENT_SAVE_FAILED, "Erro ao salvar fatura.")
    }
  }

  async remove(
    accessToken: string,
    statementId: string
  ): Promise<ServiceResult<null, StatementErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(StatementErrorCode.STATEMENT_DELETE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      // O select é o que distingue "apagou" de "não era sua".
      const { data, error } = await supabase
        .from("card_statements")
        .delete()
        .eq("id", statementId)
        .eq("user_id", userId)
        .select("id")
        .maybeSingle()

      if (error) {
        console.error("[StatementService.remove]", error)
        return failure(StatementErrorCode.STATEMENT_DELETE_FAILED, "Não foi possível remover a fatura.")
      }

      if (!data) return failure(StatementErrorCode.STATEMENT_NOT_FOUND, "Fatura não encontrada.")

      return { status: true, data: null }
    } catch (error) {
      console.error("[StatementService.remove] error:", error)
      return failure(StatementErrorCode.STATEMENT_DELETE_FAILED, "Erro ao remover fatura.")
    }
  }
}

export default new StatementService()
