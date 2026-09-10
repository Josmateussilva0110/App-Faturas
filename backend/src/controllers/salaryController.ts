import { Request, Response } from "express"
import SalaryService from "../services/SalaryService"
import { salaryErrorHttpStatusMap } from "../errors/salaryErrorHttpMapper"
import { SalaryIdParam } from "../schemas/salaries/salary"
import { getAccessToken } from "../utils/auth/getAccessToken"
import { getValidatedParams } from "../utils/http/getValidatedParams"
import { sendFailure } from "../utils/http/sendFailure"

class SalaryController {

  async list(request: Request, response: Response): Promise<Response> {
    const result = await SalaryService.list(getAccessToken(request))

    if (!result.status) return sendFailure(response, result.error, salaryErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      data: result.data,
    })
  }

  async getById(request: Request, response: Response): Promise<Response> {
    const result = await SalaryService.getById(
      getAccessToken(request),
      getValidatedParams<SalaryIdParam>(request).id
    )

    if (!result.status) return sendFailure(response, result.error, salaryErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      data: result.data,
    })
  }

  async create(request: Request, response: Response): Promise<Response> {
    const result = await SalaryService.create(getAccessToken(request), request.body)

    if (!result.status) return sendFailure(response, result.error, salaryErrorHttpStatusMap)

    return response.status(201).json({
      success: true,
      message: "Salário adicionado com sucesso.",
      data: result.data,
    })
  }

  async update(request: Request, response: Response): Promise<Response> {
    const result = await SalaryService.update(
      getAccessToken(request),
      getValidatedParams<SalaryIdParam>(request).id,
      request.body
    )

    if (!result.status) return sendFailure(response, result.error, salaryErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Salário atualizado com sucesso.",
      data: result.data,
    })
  }

  async remove(request: Request, response: Response): Promise<Response> {
    const result = await SalaryService.remove(
      getAccessToken(request),
      getValidatedParams<SalaryIdParam>(request).id
    )

    if (!result.status) return sendFailure(response, result.error, salaryErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Salário removido com sucesso.",
    })
  }
}

export default new SalaryController()
