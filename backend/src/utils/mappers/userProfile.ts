import { UserProfile } from "../../types/users/profile"

type UserProfileRow = {
  id: string
  username: string
  email: string
  spending_limit: number | string | null
  must_change_password: boolean | null
}

export function mapUserProfileRow(row: UserProfileRow): UserProfile {
  return {
    id: row.id,
    username: row.username ?? "",
    email: row.email,
    // NUMERIC volta como string no driver do Postgres; converter aqui evita
    // que o app receba "1500.00" onde espera número.
    spending_limit: row.spending_limit === null ? null : Number(row.spending_limit),
    // O SELECT já trazia a coluna, mas o mapper a descartava — então o app
    // nunca ficava sabendo que a senha era temporária, e a solicitação de
    // reset não tinha como terminar.
    must_change_password: row.must_change_password === true,
  }
}
