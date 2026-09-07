import { createClient } from "@supabase/supabase-js"
import { env } from "../../config/env"
import {
  getUserIdFromAccessToken,
  mintSupabaseAccessToken,
} from "../../utils/accessToken"

const clientOptions = {
    auth: {
        autoRefreshToken: false,
        persistSession: false,
    },
} as const

/** Bypasses RLS — use only for server-side DB and admin auth APIs. */
export const supabaseAdmin = createClient(
    env.SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    clientOptions
)

/** Auth flows (login/register/refresh) — must not share session with supabaseAdmin. */
export const supabaseAuth = createClient(
    env.SUPABASE_URL,
    env.SUPABASE_ANON_KEY,
    clientOptions
)

/** Cliente isolado por requisição — login, reauth e updateUser de senha. */
export function createEphemeralAuthClient() {
    return createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, clientOptions)
}

/** Respeita RLS — valida o token do usuário e emite JWT próprio para o PostgREST. */
export function createSupabaseClientForUser(accessToken: string) {
    const userId = getUserIdFromAccessToken(accessToken)
    if (!userId) {
        throw new Error("Token de acesso inválido para consulta ao banco.")
    }

    const dbAccessToken = mintSupabaseAccessToken(userId)

    return createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
        ...clientOptions,
        global: {
            headers: {
                Authorization: `Bearer ${dbAccessToken}`,
            },
        },
    })
}
