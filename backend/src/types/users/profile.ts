export interface UserProfile {
    id: string
    username: string
    email: string
    /** Meta mensal de gastos no cartão. `null` quando o usuário não definiu uma. */
    spending_limit: number | null
}

/** Retorno de update: o cliente já tem o resto do payload. */
export interface UpdatedUser {
    id: string
}
