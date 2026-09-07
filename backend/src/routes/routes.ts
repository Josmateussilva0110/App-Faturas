import { Router } from "express"
const router = Router()

import userRoutes from "./userRoutes"

router.use(userRoutes)


export default router
