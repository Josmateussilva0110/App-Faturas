import { CardErrorCode } from "../types/code/cardCode"

export const cardErrorHttpStatusMap: Record<CardErrorCode, number> = {
  [CardErrorCode.CARD_NOT_FOUND]: 404,   // Not Found
  [CardErrorCode.CARD_NAME_TAKEN]: 409,  // Conflict
  [CardErrorCode.CARD_FETCH_FAILED]: 500,
  [CardErrorCode.CARD_CREATE_FAILED]: 500,
  [CardErrorCode.CARD_UPDATE_FAILED]: 500,
  [CardErrorCode.CARD_DELETE_FAILED]: 500,
}
