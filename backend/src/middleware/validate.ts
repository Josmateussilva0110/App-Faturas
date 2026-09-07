import { z } from "zod"
import { Request, Response, NextFunction } from "express"
import { HttpResponse } from "../types/http/HttpResponse"

type ValidateTarget = "body" | "params" | "query"

export const validate =
  (schema: z.ZodTypeAny, target: ValidateTarget = "body") =>
  (request: Request, response: Response<HttpResponse>, next: NextFunction) => {
    const result = schema.safeParse(request[target])

    if (!result.success) {
      return response.status(422).json({
        success: false,
        message: "Erro de validação",
        errors: result.error.issues.map((issue) => ({
          field: issue.path.length > 0 ? issue.path.join(".") : target,
          message: issue.message,
        })),
      })
    }

    if (target === "query") {
      request.validatedQuery = result.data
    } else if (target === "params") {
      request.validatedParams = result.data
    } else {
      request.body = result.data
    }

    return next()
  }
