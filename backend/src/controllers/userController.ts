import { Request, Response } from "express"
import UserService from "../services/UserService"
import { userErrorHttpStatusMap } from "../errors/userErrorHttpMapper"
import { getAccessToken } from "../utils/auth/getAccessToken"
import { sendFailure } from "../utils/http/sendFailure"

class UserController {

  async login(request: Request, response: Response): Promise<Response> {
    const { email, password } = request.body
    const result = await UserService.login(email, password)
    if (!result.status) return sendFailure(response, result.error, userErrorHttpStatusMap)


    return response.status(200).json({
      success: true,
      message: "Login Realizado com sucesso",
      data: result.data,
    })
  }

  async logout(request: Request, response: Response): Promise<Response> {

    const result = await UserService.logout(request.accessToken!)

    if (!result.status) return sendFailure(response, result.error, userErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Logout realizado com sucesso",
    })
  }

  async refresh(request: Request, response: Response): Promise<Response> {
    const { refreshToken } = request.body

    const result = await UserService.refresh(refreshToken)

    if (!result.status) {
      // O app usa o `code` para decidir se apaga a sessão local.
      return sendFailure(response, result.error, userErrorHttpStatusMap, { exposeCode: true })
    }

    return response.status(200).json({
      success: true,
      message: "Sessão renovada com sucesso.",
      data: result.data,
    })
  }

  async getProfile(request: Request, response: Response): Promise<Response> {
    const result = await UserService.getProfile(getAccessToken(request))

    if (!result.status) return sendFailure(response, result.error, userErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      data: result.data,
    })
  }

  async updateProfile(request: Request, response: Response): Promise<Response> {
    const { username } = request.body

    const result = await UserService.updateProfile(getAccessToken(request), { username })

    if (!result.status) return sendFailure(response, result.error, userErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Perfil atualizado com sucesso.",
      data: result.data,
    })
  }

  async updateSpendingLimit(request: Request, response: Response): Promise<Response> {
    const result = await UserService.updateSpendingLimit(getAccessToken(request), request.body)

    if (!result.status) return sendFailure(response, result.error, userErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Limite de gastos atualizado com sucesso.",
      data: result.data,
    })
  }

  async changePassword(request: Request, response: Response): Promise<Response> {
    const result = await UserService.changePassword(
      getAccessToken(request),
      request.body
    )

    if (!result.status) return sendFailure(response, result.error, userErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message: "Senha atualizada com sucesso.",
      data: result.data,
    })
  }

  async requestPasswordReset(request: Request, response: Response): Promise<Response> {
    const result = await UserService.requestPasswordReset(request.body)

    if (!result.status) return sendFailure(response, result.error, userErrorHttpStatusMap)

    return response.status(200).json({
      success: true,
      message:
        "Solicitação enviada. Nossa equipe vai entrar em contato para confirmar sua identidade e liberar o acesso.",
    })
  }

}

export default new UserController()
