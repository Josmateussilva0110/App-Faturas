import { Router } from "express"
import ExpenseController from "../controllers/expenseController"
import { authMiddleware } from "../middleware/auth"
import { validate } from "../middleware/validate"
import {
  CreateExpenseSchema,
  ExpenseIdParamSchema,
  UpdateExpenseSchema,
} from "../schemas/expenses/expense"

const router = Router()

// Ordem dos middlewares: auth antes de validate — não vale validar o corpo
// de uma requisição que será recusada por falta de token.
router.get("/expenses", authMiddleware, ExpenseController.list)

router.post("/expenses", authMiddleware, validate(CreateExpenseSchema), ExpenseController.create)

router.get(
  "/expenses/:id",
  authMiddleware,
  validate(ExpenseIdParamSchema, "params"),
  ExpenseController.getById
)

router.put(
  "/expenses/:id",
  authMiddleware,
  validate(ExpenseIdParamSchema, "params"),
  validate(UpdateExpenseSchema),
  ExpenseController.update
)

router.delete(
  "/expenses/:id",
  authMiddleware,
  validate(ExpenseIdParamSchema, "params"),
  ExpenseController.remove
)

export default router
