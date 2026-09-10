import { Request, Response } from "express"
import ExpenseService from "../services/ExpenseService"
import { expenseErrorHttpStatusMap } from "../errors/expenseErrorHttpMapper"
import { ExpenseIdParam } from "../schemas/expenseSchema"
import { getAccessToken } from "../utils/auth/getAccessToken"
import { getValidatedParams } from "../utils/http/getValidatedParams"
import { sendFailure } from "../utils/http/sendFailure"

class ExpenseController {

  async list(request: Request, response: Response): Promise<Response> {
    const result = await ExpenseService.list(getAccessToken(request))

    if (!result.status) return sendFailure(response, result.error, expenseErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      data: result.data,
    })
  }

  async getById(request: Request, response: Response): Promise<Response> {
    const result = await ExpenseService.getById(
      getAccessToken(request),
      getValidatedParams<ExpenseIdParam>(request).id
    )

    if (!result.status) return sendFailure(response, result.error, expenseErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      data: result.data,
    })
  }

  async create(request: Request, response: Response): Promise<Response> {
    const result = await ExpenseService.create(getAccessToken(request), request.body)

    if (!result.status) return sendFailure(response, result.error, expenseErrorHttpStatusMap)

    return response.status(201).json({
      success: true,
      message: "Despesa adicionada com sucesso.",
      data: result.data,
    })
  }

  async update(request: Request, response: Response): Promise<Response> {
    const result = await ExpenseService.update(
      getAccessToken(request),
      getValidatedParams<ExpenseIdParam>(request).id,
      request.body
    )

    if (!result.status) return sendFailure(response, result.error, expenseErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Despesa atualizada com sucesso.",
      data: result.data,
    })
  }

  async remove(request: Request, response: Response): Promise<Response> {
    const result = await ExpenseService.remove(
      getAccessToken(request),
      getValidatedParams<ExpenseIdParam>(request).id
    )

    if (!result.status) return sendFailure(response, result.error, expenseErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Despesa removida com sucesso.",
    })
  }
}

export default new ExpenseController()
