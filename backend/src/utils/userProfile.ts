import { UserProfile } from "../types/users/profile"

type UserProfileRow = {
  id: string
  username: string
  email: string
}

export function mapUserProfileRow(row: UserProfileRow): UserProfile {
  return {
    id: row.id,
    username: row.username ?? "",
    email: row.email,
  }
}
