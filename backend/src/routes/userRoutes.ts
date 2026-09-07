import { Router } from "express"
import UserController from "../controllers/userController"
import { validate } from "../middleware/validate"
import { LoginSchema } from "../schemas/loginSchema"
import { UpdateProfileSchema } from "../schemas/updateProfileSchema"
import { RefreshSchema } from "../schemas/refreshSchema"
import { ChangePasswordSchema } from "../schemas/changePasswordSchema"
import { PasswordResetRequestSchema } from "../schemas/passwordResetRequestSchema"
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
  "/profile/password",
  authMiddleware,
  validate(ChangePasswordSchema),
  UserController.changePassword
)

router.post("/logout", authMiddleware, UserController.logout)
router.post("/auth/refresh", refreshRateLimiter, validate(RefreshSchema), UserController.refresh.bind(UserController))


export default router
