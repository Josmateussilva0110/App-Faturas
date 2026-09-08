/**
 * Monta o ramo de falha de um `ServiceResult`.
 *
 * Existe para os services não repetirem `{ status: false, error: { ... } }`
 * em cada saída de erro — que costumam ser várias por método. O genérico
 * mantém o código preso ao enum do recurso.
 *
 * ```ts
 * if (!userId) return failure(PurchaseErrorCode.PURCHASE_FETCH_FAILED, "Sessão inválida.")
 * ```
 */
export function failure<Code extends string>(
  code: Code,
  message: string
): { status: false; error: { code: Code; message: string } } {
  return { status: false, error: { code, message } }
}
