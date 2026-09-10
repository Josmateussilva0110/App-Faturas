import { createSupabaseClientForUser } from "../database/supabase/supabase"
import { PURCHASE_SELECT } from "../constants/purchase.constants"
import { ServiceResult } from "../types/serviceResults/ServiceResult"
import { PurchaseErrorCode } from "../types/code/purchaseCode"
import { CreatedPurchase, Purchase } from "../types/purchases/purchase"
import { CreatePurchaseDTO, UpdatePurchaseDTO } from "../schemas/purchases/purchase"
import { getUserIdFromAccessToken } from "../utils/auth/accessToken"
import { mapPurchaseRow } from "../utils/mappers/purchase"
import { failure } from "../utils/service/serviceResult"
import { isForeignKeyViolation } from "../utils/service/supabaseErrors"

/**
 * O dono sai sempre do token, nunca do corpo da requisição — é o que impede
 * que trocar um id no payload alcance a compra de outra pessoa. O RLS já
 * barraria, mas filtrar também aqui mantém a intenção explícita no código.
 */
class PurchaseService {

  async list(accessToken: string): Promise<ServiceResult<Purchase[], PurchaseErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(PurchaseErrorCode.PURCHASE_FETCH_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("purchases")
        .select(PURCHASE_SELECT)
        .eq("user_id", userId)
        .order("start_abs", { ascending: false })

      if (error || !data) {
        console.error("[PurchaseService.list]", error)
        return failure(PurchaseErrorCode.PURCHASE_FETCH_FAILED, "Erro ao buscar compras.")
      }

      return { status: true, data: data.map(mapPurchaseRow) }
    } catch (error) {
      console.error("[PurchaseService.list] error:", error)
      return failure(PurchaseErrorCode.PURCHASE_FETCH_FAILED, "Erro ao buscar compras.")
    }
  }

  async getById(
    accessToken: string,
    purchaseId: string
  ): Promise<ServiceResult<Purchase, PurchaseErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(PurchaseErrorCode.PURCHASE_FETCH_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("purchases")
        .select(PURCHASE_SELECT)
        .eq("id", purchaseId)
        .eq("user_id", userId)
        .maybeSingle()

      if (error) {
        console.error("[PurchaseService.getById]", error)
        return failure(PurchaseErrorCode.PURCHASE_FETCH_FAILED, "Erro ao buscar compra.")
      }

      if (!data) return failure(PurchaseErrorCode.PURCHASE_NOT_FOUND, "Compra não encontrada.")

      return { status: true, data: mapPurchaseRow(data) }
    } catch (error) {
      console.error("[PurchaseService.getById] error:", error)
      return failure(PurchaseErrorCode.PURCHASE_FETCH_FAILED, "Erro ao buscar compra.")
    }
  }

  async create(
    accessToken: string,
    payload: CreatePurchaseDTO
  ): Promise<ServiceResult<CreatedPurchase, PurchaseErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(PurchaseErrorCode.PURCHASE_CREATE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      // Só o id volta: o cliente já tem os campos que enviou, e trazer a
      // linha inteira de novo é tráfego sem uso.
      const { data, error } = await supabase
        .from("purchases")
        .insert({ ...payload, user_id: userId })
        .select("id")
        .single()

      if (error || !data) {
        console.error("[PurchaseService.create]", error)

        // O RLS do cartão faz um card_id de outro usuário parecer inexistente,
        // e a FK falha. Do ponto de vista do cliente é dado inválido, não 500.
        if (isForeignKeyViolation(error)) {
          return failure(PurchaseErrorCode.CARD_NOT_FOUND, "Cartão não encontrado.")
        }

        return failure(PurchaseErrorCode.PURCHASE_CREATE_FAILED, "Não foi possível criar a compra.")
      }

      return { status: true, data: { id: data.id } }
    } catch (error) {
      console.error("[PurchaseService.create] error:", error)
      return failure(PurchaseErrorCode.PURCHASE_CREATE_FAILED, "Erro ao criar compra.")
    }
  }

  async update(
    accessToken: string,
    purchaseId: string,
    payload: UpdatePurchaseDTO
  ): Promise<ServiceResult<CreatedPurchase, PurchaseErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(PurchaseErrorCode.PURCHASE_UPDATE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      const { data, error } = await supabase
        .from("purchases")
        .update(payload)
        .eq("id", purchaseId)
        .eq("user_id", userId)
        .select("id")
        .maybeSingle()

      if (error) {
        console.error("[PurchaseService.update]", error)

        if (isForeignKeyViolation(error)) {
          return failure(PurchaseErrorCode.CARD_NOT_FOUND, "Cartão não encontrado.")
        }

        return failure(PurchaseErrorCode.PURCHASE_UPDATE_FAILED, "Não foi possível atualizar a compra.")
      }

      if (!data) return failure(PurchaseErrorCode.PURCHASE_NOT_FOUND, "Compra não encontrada.")

      return { status: true, data: { id: data.id } }
    } catch (error) {
      console.error("[PurchaseService.update] error:", error)
      return failure(PurchaseErrorCode.PURCHASE_UPDATE_FAILED, "Erro ao atualizar compra.")
    }
  }

  async remove(
    accessToken: string,
    purchaseId: string
  ): Promise<ServiceResult<null, PurchaseErrorCode>> {
    try {
      const userId = getUserIdFromAccessToken(accessToken)
      if (!userId) return failure(PurchaseErrorCode.PURCHASE_DELETE_FAILED, "Sessão inválida.")

      const supabase = createSupabaseClientForUser(accessToken)

      // `select` no delete é o que diferencia "apagou" de "não era sua".
      const { data, error } = await supabase
        .from("purchases")
        .delete()
        .eq("id", purchaseId)
        .eq("user_id", userId)
        .select("id")
        .maybeSingle()

      if (error) {
        console.error("[PurchaseService.remove]", error)
        return failure(PurchaseErrorCode.PURCHASE_DELETE_FAILED, "Não foi possível remover a compra.")
      }

      if (!data) return failure(PurchaseErrorCode.PURCHASE_NOT_FOUND, "Compra não encontrada.")

      return { status: true, data: null }
    } catch (error) {
      console.error("[PurchaseService.remove] error:", error)
      return failure(PurchaseErrorCode.PURCHASE_DELETE_FAILED, "Erro ao remover compra.")
    }
  }
}

export default new PurchaseService()
