import { Router } from "express"
import StatementController from "../controllers/statementController"
import { authMiddleware } from "../middleware/auth"
import { validate } from "../middleware/validate"
import { StatementIdParamSchema, UpsertStatementSchema } from "../schemas/statements/statement"

const router = Router()

// Ordem dos middlewares: auth antes de validate — não vale validar o corpo
// de uma requisição que será recusada por falta de token.
router.get("/statements", authMiddleware, StatementController.list)

// PUT sem id no caminho: a identidade da fatura é o par (cartão, mês) que vai
// no corpo, e a operação é idempotente.
router.put("/statements", authMiddleware, validate(UpsertStatementSchema), StatementController.upsert)

router.delete(
  "/statements/:id",
  authMiddleware,
  validate(StatementIdParamSchema, "params"),
  StatementController.remove
)

export default router
