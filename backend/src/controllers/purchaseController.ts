import { Request, Response } from "express"
import PurchaseService from "../services/PurchaseService"
import { purchaseErrorHttpStatusMap } from "../errors/purchaseErrorHttpMapper"
import { PurchaseIdParam } from "../schemas/purchases/purchase"
import { getAccessToken } from "../utils/auth/getAccessToken"
import { getValidatedParams } from "../utils/http/getValidatedParams"
import { sendFailure } from "../utils/http/sendFailure"

class PurchaseController {

  async list(request: Request, response: Response): Promise<Response> {
    const result = await PurchaseService.list(getAccessToken(request))

    if (!result.status) return sendFailure(response, result.error, purchaseErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      data: result.data,
    })
  }

  async getById(request: Request, response: Response): Promise<Response> {
    const result = await PurchaseService.getById(getAccessToken(request), getValidatedParams<PurchaseIdParam>(request).id)

    if (!result.status) return sendFailure(response, result.error, purchaseErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      data: result.data,
    })
  }

  async create(request: Request, response: Response): Promise<Response> {
    const result = await PurchaseService.create(getAccessToken(request), request.body)

    if (!result.status) return sendFailure(response, result.error, purchaseErrorHttpStatusMap)

    return response.status(201).json({
      success: true,
      message: "Compra criada com sucesso.",
      data: result.data,
    })
  }

  async update(request: Request, response: Response): Promise<Response> {
    const result = await PurchaseService.update(
      getAccessToken(request),
      getValidatedParams<PurchaseIdParam>(request).id,
      request.body
    )

    if (!result.status) return sendFailure(response, result.error, purchaseErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Compra atualizada com sucesso.",
      data: result.data,
    })
  }

  async remove(request: Request, response: Response): Promise<Response> {
    const result = await PurchaseService.remove(getAccessToken(request), getValidatedParams<PurchaseIdParam>(request).id)

    if (!result.status) return sendFailure(response, result.error, purchaseErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Compra removida com sucesso.",
    })
  }
}

export default new PurchaseController()
