import { UserProfile } from "../../types/users/profile"

type UserProfileRow = {
  id: string
  username: string
  email: string
  spending_limit: number | string | null
}

export function mapUserProfileRow(row: UserProfileRow): UserProfile {
  return {
    id: row.id,
    username: row.username ?? "",
    email: row.email,
    // NUMERIC volta como string no driver do Postgres; converter aqui evita
    // que o app receba "1500.00" onde espera número.
    spending_limit: row.spending_limit === null ? null : Number(row.spending_limit),
  }
}
