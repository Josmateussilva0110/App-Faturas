import { Router } from "express"
import CardController from "../controllers/cardController"
import { authMiddleware } from "../middleware/auth"
import { validate } from "../middleware/validate"
import { CardIdParamSchema, CreateCardSchema, UpdateCardSchema } from "../schemas/cardSchema"

const router = Router()

// Ordem dos middlewares: auth antes de validate — não vale validar o corpo
// de uma requisição que será recusada por falta de token.
router.get("/cards", authMiddleware, CardController.list)

router.post("/cards", authMiddleware, validate(CreateCardSchema), CardController.create)

router.get(
  "/cards/:id",
  authMiddleware,
  validate(CardIdParamSchema, "params"),
  CardController.getById
)

router.put(
  "/cards/:id",
  authMiddleware,
  validate(CardIdParamSchema, "params"),
  validate(UpdateCardSchema),
  CardController.update
)

router.delete(
  "/cards/:id",
  authMiddleware,
  validate(CardIdParamSchema, "params"),
  CardController.remove
)

export default router
