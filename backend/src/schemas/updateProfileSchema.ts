import { z } from "zod"
import { usernameField } from "./usernameSchema"

export const UpdateProfileSchema = z.object({
  username: usernameField,
})

export type UpdateProfileDTO = z.infer<typeof UpdateProfileSchema>
