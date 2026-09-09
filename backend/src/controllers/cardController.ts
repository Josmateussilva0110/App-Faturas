import { Request, Response } from "express"
import CardService from "../services/CardService"
import { cardErrorHttpStatusMap } from "../errors/cardErrorHttpMapper"
import { CardIdParam } from "../schemas/cardSchema"
import { getAccessToken } from "../utils/auth/getAccessToken"
import { getValidatedParams } from "../utils/http/getValidatedParams"
import { sendFailure } from "../utils/http/sendFailure"

class CardController {

  async list(request: Request, response: Response): Promise<Response> {
    const result = await CardService.list(getAccessToken(request))

    if (!result.status) return sendFailure(response, result.error, cardErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      data: result.data,
    })
  }

  async getById(request: Request, response: Response): Promise<Response> {
    const result = await CardService.getById(
      getAccessToken(request),
      getValidatedParams<CardIdParam>(request).id
    )

    if (!result.status) return sendFailure(response, result.error, cardErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      data: result.data,
    })
  }

  async create(request: Request, response: Response): Promise<Response> {
    const result = await CardService.create(getAccessToken(request), request.body)

    if (!result.status) return sendFailure(response, result.error, cardErrorHttpStatusMap)

    return response.status(201).json({
      success: true,
      message: "Cartão criado com sucesso.",
      data: result.data,
    })
  }

  async update(request: Request, response: Response): Promise<Response> {
    const result = await CardService.update(
      getAccessToken(request),
      getValidatedParams<CardIdParam>(request).id,
      request.body
    )

    if (!result.status) return sendFailure(response, result.error, cardErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Cartão atualizado com sucesso.",
      data: result.data,
    })
  }

  async remove(request: Request, response: Response): Promise<Response> {
    const result = await CardService.remove(
      getAccessToken(request),
      getValidatedParams<CardIdParam>(request).id
    )

    if (!result.status) return sendFailure(response, result.error, cardErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Cartão removido com sucesso.",
    })
  }
}

export default new CardController()
