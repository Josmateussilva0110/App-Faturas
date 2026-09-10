import { Router } from "express"
import PurchaseController from "../controllers/purchaseController"
import { authMiddleware } from "../middleware/auth"
import { validate } from "../middleware/validate"
import {
  CreatePurchaseSchema,
  PurchaseIdParamSchema,
  UpdatePurchaseSchema,
} from "../schemas/purchases/purchase"

const router = Router()

// Ordem dos middlewares: auth antes de validate — não vale validar o corpo
// de uma requisição que será recusada por falta de token.
router.get("/purchases", authMiddleware, PurchaseController.list)

router.post(
  "/purchases",
  authMiddleware,
  validate(CreatePurchaseSchema),
  PurchaseController.create
)

router.get(
  "/purchases/:id",
  authMiddleware,
  validate(PurchaseIdParamSchema, "params"),
  PurchaseController.getById
)

router.put(
  "/purchases/:id",
  authMiddleware,
  validate(PurchaseIdParamSchema, "params"),
  validate(UpdatePurchaseSchema),
  PurchaseController.update
)

router.delete(
  "/purchases/:id",
  authMiddleware,
  validate(PurchaseIdParamSchema, "params"),
  PurchaseController.remove
)

export default router
