import { z } from "zod"
import { usernameField } from "../fields/username"

export const UpdateProfileSchema = z.object({
  username: usernameField,
})

export type UpdateProfileDTO = z.infer<typeof UpdateProfileSchema>
