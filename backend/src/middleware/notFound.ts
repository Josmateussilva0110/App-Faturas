import { Request, Response } from "express"

export const notFound = (_req: Request, res: Response) => {
    res.status(404).json({
        status: false,
        error: { message: "Rota não encontrada." },
    })
}
