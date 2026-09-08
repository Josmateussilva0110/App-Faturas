export interface UserProfile {
    id: string
    username: string
    email: string
}

/** Retorno de update: o cliente já tem o resto do payload. */
export interface UpdatedUser {
    id: string
}
