import { createSupabaseClientForUser } from "../database/supabase/supabase"
import { CARD_SELECT } from "../constants/card.constants"
import { ServiceResult } from "../types/serviceResults/ServiceResult"
import { CardErrorCode } from "../types/code/cardCode"
import { Card, CreatedCard } from "../types/cards/card"
import { CreateCardDTO, UpdateCardDTO } from "../schemas/cardSchema"
import { getUserIdFromAccessToken } from "../utils/auth/accessToken"
import { mapCardRow } from "../utils/mappers/card"
import { failure } from "../utils/service/serviceResult"
import { isUniqueViolation } from "../utils/service/supabaseErrors"

/**
 * O dono sai sempre do token, nunca do corpo da requisição — é o que impede
 * que trocar um id no payload alcance o cartão de outra pessoa. O RLS já
 * barraria, mas filtrar também aqui mantém a intenção explícita no código.
 */
class CardService {

  async list(accessToken: string): Promise<ServiceResult<Card[], CardErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(CardErrorCode.CARD_FETCH_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("cards")
        .select(CARD_SELECT)
        .eq("user_id", userId)
        .order("name", { ascending: true })

      if (error || !data) {
        console.error("[CardService.list]", error)
        return failure(CardErrorCode.CARD_FETCH_FAILED, "Erro ao buscar cartões.")
      }

      return { status: true, data: data.map(mapCardRow) }
    } catch (error) {
      console.error("[CardService.list] error:", error)
      return failure(CardErrorCode.CARD_FETCH_FAILED, "Erro ao buscar cartões.")
    }
  }

  async getById(
    accessToken: string,
    cardId: string
  ): Promise<ServiceResult<Card, CardErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(CardErrorCode.CARD_FETCH_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("cards")
        .select(CARD_SELECT)
        .eq("id", cardId)
        .eq("user_id", userId)
        .maybeSingle()

      if (error) {
        console.error("[CardService.getById]", error)
        return failure(CardErrorCode.CARD_FETCH_FAILED, "Erro ao buscar cartão.")
      }

      if (!data) return failure(CardErrorCode.CARD_NOT_FOUND, "Cartão não encontrado.")

      return { status: true, data: mapCardRow(data) }
    } catch (error) {
      console.error("[CardService.getById] error:", error)
      return failure(CardErrorCode.CARD_FETCH_FAILED, "Erro ao buscar cartão.")
    }
  }

  async create(
    accessToken: string,
    payload: CreateCardDTO
  ): Promise<ServiceResult<CreatedCard, CardErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(CardErrorCode.CARD_CREATE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("cards")
        .insert({ ...payload, user_id: userId })
        .select("id")
        .single()

      if (error || !data) {
        // Nome repetido é desfecho esperado, não falha do servidor: responde
        // 409 sem registrar erro. Quem garante a regra é o índice único
        // (user_id, lower(btrim(name))) — verificar antes do insert deixaria
        // brecha para duas requisições simultâneas gravarem o mesmo nome.
        if (isUniqueViolation(error)) {
          return failure(CardErrorCode.CARD_NAME_TAKEN, "Já existe um cartão com esse nome.")
        }

        console.error("[CardService.create]", error)
        return failure(CardErrorCode.CARD_CREATE_FAILED, "Não foi possível criar o cartão.")
      }

      return { status: true, data: { id: data.id } }
    } catch (error) {
      console.error("[CardService.create] error:", error)
      return failure(CardErrorCode.CARD_CREATE_FAILED, "Erro ao criar cartão.")
    }
  }

  async update(
    accessToken: string,
    cardId: string,
    payload: UpdateCardDTO
  ): Promise<ServiceResult<CreatedCard, CardErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(CardErrorCode.CARD_UPDATE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("cards")
        .update(payload)
        .eq("id", cardId)
        .eq("user_id", userId)
        .select("id")
        .maybeSingle()

      if (error) {
        if (isUniqueViolation(error)) {
          return failure(CardErrorCode.CARD_NAME_TAKEN, "Já existe um cartão com esse nome.")
        }

        console.error("[CardService.update]", error)
        return failure(CardErrorCode.CARD_UPDATE_FAILED, "Não foi possível atualizar o cartão.")
      }

      if (!data) return failure(CardErrorCode.CARD_NOT_FOUND, "Cartão não encontrado.")

      return { status: true, data: { id: data.id } }
    } catch (error) {
      console.error("[CardService.update] error:", error)
      return failure(CardErrorCode.CARD_UPDATE_FAILED, "Erro ao atualizar cartão.")
    }
  }

  async remove(
    accessToken: string,
    cardId: string
  ): Promise<ServiceResult<null, CardErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(CardErrorCode.CARD_DELETE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      // As compras do cartão sobrevivem: a FK é ON DELETE SET NULL, e o app
      // mostra "Cartão removido" no lugar do nome.
      const { data, error } = await supabase
        .from("cards")
        .delete()
        .eq("id", cardId)
        .eq("user_id", userId)
        .select("id")
        .maybeSingle()

      if (error) {
        console.error("[CardService.remove]", error)
        return failure(CardErrorCode.CARD_DELETE_FAILED, "Não foi possível remover o cartão.")
      }

      if (!data) return failure(CardErrorCode.CARD_NOT_FOUND, "Cartão não encontrado.")

      return { status: true, data: null }
    } catch (error) {
      console.error("[CardService.remove] error:", error)
      return failure(CardErrorCode.CARD_DELETE_FAILED, "Erro ao remover cartão.")
    }
  }
}

export default new CardService()
