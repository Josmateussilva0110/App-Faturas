import { Request, Response, NextFunction } from "express"
import { env } from "../config/env"

export interface AppError extends Error {
    statusCode?: number
    code?: string
}

export const errorHandler = (
    err: AppError,
    _req: Request,
    res: Response,
    _next: NextFunction
) => {
    const statusCode = err.statusCode ?? 500
    const isProd = env.NODE_ENV === "production"

    console.error(`[${statusCode}] ${err.message}`, isProd ? "" : err.stack)

    res.status(statusCode).json({
        status: false,
        error: {
            message: isProd && statusCode === 500
                ? "Erro interno do servidor."
                : err.message,
            ...(isProd ? {} : { stack: err.stack }),
        },
    })
}
