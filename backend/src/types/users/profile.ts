export interface UserProfile {
    id: string
    username: string
    email: string
    /** Meta mensal de gastos no cartão. `null` quando o usuário não definiu uma. */
    spending_limit: number | null
    /**
     * A senha atual é temporária e precisa ser trocada antes de usar o app.
     * Marcada à mão ao atender uma solicitação de `password_reset_requests`.
     */
    must_change_password: boolean
}

/** Retorno de update: o cliente já tem o resto do payload. */
export interface UpdatedUser {
    id: string
}
