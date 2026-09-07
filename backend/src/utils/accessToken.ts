import jwt from "jsonwebtoken"

import { env } from "../config/env"

/** Tempo de vida do JWT emitido pelo backend para queries PostgREST (RLS). */
const SUPABASE_DB_JWT_TTL_SECONDS = 300

export function getUserIdFromAccessToken(accessToken: string): string | undefined {
  try {
    const payload = jwt.verify(accessToken, env.SUPABASE_JWT_SECRET, {
      algorithms: ["HS256"],
    }) as { sub?: string }

    return payload.sub
  } catch {
    const payload = jwt.decode(accessToken) as { sub?: string } | null
    return payload?.sub
  }
}

/**
 * Emite JWT curto para o PostgREST respeitar RLS (auth.uid()).
 * Sem `iat`: PostgREST só valida iat quando presente; omitir evita PGRST303
 * quando o relógio do servidor (ex.: Belmo) está adiantado em relação ao PostgREST.
 */
export function mintSupabaseAccessToken(userId: string): string {
  const issuer = `${env.SUPABASE_URL.replace(/\/+$/, "")}/auth/v1`

  return jwt.sign(
    {
      sub: userId,
      aud: "authenticated",
      role: "authenticated",
      iss: issuer,
    },
    env.SUPABASE_JWT_SECRET,
    {
      algorithm: "HS256",
      expiresIn: SUPABASE_DB_JWT_TTL_SECONDS,
      noTimestamp: true,
    }
  )
}
