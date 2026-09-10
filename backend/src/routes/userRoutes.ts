import { Router } from "express"
import UserController from "../controllers/userController"
import { validate } from "../middleware/validate"
import { LoginSchema } from "../schemas/auth/login"
import { UpdateProfileSchema } from "../schemas/users/updateProfile"
import { RefreshSchema } from "../schemas/auth/refresh"
import { ChangePasswordSchema } from "../schemas/auth/changePassword"
import { UpdateSpendingLimitSchema } from "../schemas/users/spendingLimit"
import { PasswordResetRequestSchema } from "../schemas/auth/passwordResetRequest"
import { loginRateLimiter } from "../middleware/loginRateLimit"
import { refreshRateLimiter } from "../middleware/refreshRateLimit"
import { authMiddleware } from "../middleware/auth"


const router = Router()

router.post("/login", loginRateLimiter, validate(LoginSchema), UserController.login)
router.post(
  "/auth/password-reset-request",
  loginRateLimiter,
  validate(PasswordResetRequestSchema),
  UserController.requestPasswordReset
)
router.get("/profile", authMiddleware, UserController.getProfile)
router.put("/profile", authMiddleware, validate(UpdateProfileSchema), UserController.updateProfile)
router.put(
  "/profile/spending-limit",
  authMiddleware,
  validate(UpdateSpendingLimitSchema),
  UserController.updateSpendingLimit
)
router.put(
  "/profile/password",
  authMiddleware,
  validate(ChangePasswordSchema),
  UserController.changePassword
)

router.post("/logout", authMiddleware, UserController.logout)
router.post("/auth/refresh", refreshRateLimiter, validate(RefreshSchema), UserController.refresh.bind(UserController))


export default router
