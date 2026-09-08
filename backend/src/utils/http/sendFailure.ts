import { Response } from "express"

import { getHttpStatusFromError } from "./getHttpStatusFromError"

type SendFailureOptions = {
  /**
   * Inclui o `code` no corpo. Use só quando o cliente precisa distinguir o
   * motivo do erro, não apenas mostrá-lo: o app, por exemplo, só apaga a
   * sessão local quando o refresh falha com SESSION_REVOKED — uma falha de
   * rede tem que preservá-la. Fora esses casos o código fica no servidor.
   */
  exposeCode?: boolean
}

/**
 * Traduz o erro de um service em resposta HTTP, no formato do envelope.
 *
 * O mapa de status vem por parâmetro para a função servir a qualquer domínio:
 * cada recurso tem seu enum de códigos e seu `Record<Código, number>`, e o
 * genérico amarra os dois — passar o mapa de outro domínio não compila.
 *
 * ```ts
 * if (!result.status) return sendFailure(response, result.error, purchaseErrorHttpStatusMap)
 * ```
 */
export function sendFailure<Code extends string>(
  response: Response,
  error: { code: Code; message?: string },
  statusMap: Record<Code, number>,
  options: SendFailureOptions = {}
): Response {
  const httpStatus = getHttpStatusFromError(error.code, statusMap)

  return response.status(httpStatus).json({
    success: false,
    ...(options.exposeCode ? { code: error.code } : {}),
    message: error.message,
  })
}
