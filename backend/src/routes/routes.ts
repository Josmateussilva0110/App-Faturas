import { Router } from "express"
const router = Router()

import userRoutes from "./userRoutes"
import cardRoutes from "./cardRoutes"
import purchaseRoutes from "./purchaseRoutes"

router.use(userRoutes)
router.use(cardRoutes)
router.use(purchaseRoutes)


export default router
