import { PurchaseErrorCode } from "../types/code/purchaseCode"

export const purchaseErrorHttpStatusMap: Record<PurchaseErrorCode, number> = {
  [PurchaseErrorCode.PURCHASE_NOT_FOUND]: 404,   // Not Found
  [PurchaseErrorCode.CARD_NOT_FOUND]: 422,       // cartão informado não é do usuário
  [PurchaseErrorCode.PURCHASE_FETCH_FAILED]: 500,
  [PurchaseErrorCode.PURCHASE_CREATE_FAILED]: 500,
  [PurchaseErrorCode.PURCHASE_UPDATE_FAILED]: 500,
  [PurchaseErrorCode.PURCHASE_DELETE_FAILED]: 500,
}
