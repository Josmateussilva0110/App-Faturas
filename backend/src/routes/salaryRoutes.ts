import { Router } from "express"
import SalaryController from "../controllers/salaryController"
import { authMiddleware } from "../middleware/auth"
import { validate } from "../middleware/validate"
import {
  CreateSalarySchema,
  SalaryIdParamSchema,
  UpdateSalarySchema,
} from "../schemas/salaries/salary"

const router = Router()

// Ordem dos middlewares: auth antes de validate — não vale validar o corpo
// de uma requisição que será recusada por falta de token.
router.get("/salaries", authMiddleware, SalaryController.list)

router.post("/salaries", authMiddleware, validate(CreateSalarySchema), SalaryController.create)

router.get(
  "/salaries/:id",
  authMiddleware,
  validate(SalaryIdParamSchema, "params"),
  SalaryController.getById
)

router.put(
  "/salaries/:id",
  authMiddleware,
  validate(SalaryIdParamSchema, "params"),
  validate(UpdateSalarySchema),
  SalaryController.update
)

router.delete(
  "/salaries/:id",
  authMiddleware,
  validate(SalaryIdParamSchema, "params"),
  SalaryController.remove
)

export default router
