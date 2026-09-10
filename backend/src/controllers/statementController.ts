import { Request, Response } from "express"
import StatementService from "../services/StatementService"
import { statementErrorHttpStatusMap } from "../errors/statementErrorHttpMapper"
import { StatementIdParam } from "../schemas/statements/statement"
import { getAccessToken } from "../utils/auth/getAccessToken"
import { getValidatedParams } from "../utils/http/getValidatedParams"
import { sendFailure } from "../utils/http/sendFailure"

class StatementController {

  async list(request: Request, response: Response): Promise<Response> {
    const result = await StatementService.list(getAccessToken(request))

    if (!result.status) return sendFailure(response, result.error, statementErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      data: result.data,
    })
  }

  /**
   * 200, não 201: informar a fatura do mesmo (cartão, mês) de novo atualiza
   * a linha existente, então nem sempre houve criação.
   */
  async upsert(request: Request, response: Response): Promise<Response> {
    const result = await StatementService.upsert(getAccessToken(request), request.body)

    if (!result.status) return sendFailure(response, result.error, statementErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Fatura salva com sucesso.",
      data: result.data,
    })
  }

  async remove(request: Request, response: Response): Promise<Response> {
    const result = await StatementService.remove(
      getAccessToken(request),
      getValidatedParams<StatementIdParam>(request).id
    )

    if (!result.status) return sendFailure(response, result.error, statementErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Fatura removida com sucesso.",
    })
  }
}

export default new StatementController()
