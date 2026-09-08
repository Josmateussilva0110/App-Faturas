import { Router } from "express"
const router = Router()

import userRoutes from "./userRoutes"
import purchaseRoutes from "./purchaseRoutes"

router.use(userRoutes)
router.use(purchaseRoutes)


export default router
