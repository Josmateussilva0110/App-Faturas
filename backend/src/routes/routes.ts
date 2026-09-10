import { Router } from "express"
const router = Router()

import userRoutes from "./userRoutes"
import cardRoutes from "./cardRoutes"
import purchaseRoutes from "./purchaseRoutes"
import salaryRoutes from "./salaryRoutes"
import expenseRoutes from "./expenseRoutes"
import statementRoutes from "./statementRoutes"

router.use(userRoutes)
router.use(cardRoutes)
router.use(purchaseRoutes)
router.use(salaryRoutes)
router.use(expenseRoutes)
router.use(statementRoutes)


export default router
