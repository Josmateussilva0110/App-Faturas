import { Request, Response, NextFunction } from "express"
import jwt from "jsonwebtoken"
import type { User } from "@supabase/supabase-js"
import { env } from "../config/env"
import { supabaseAdmin } from "../database/supabase/supabase"
import { isAccessTokenRevoked, isUserSessionRevoked } from "../utils/tokenRevocation"

type SupabaseJwtPayload = jwt.JwtPayload & {
  sub: string
  email?: string
}

function toAuthUser(payload: SupabaseJwtPayload): User {
  const aud = payload.aud
  return {
    id: payload.sub,
    email: payload.email ?? "",
    aud: Array.isArray(aud) ? aud[0] ?? "authenticated" : aud ?? "authenticated",
    role: payload.role ?? "authenticated",
    app_metadata: {},
    user_metadata: {},
    created_at: "",
  }
}

async function verifyJwtLocally(token: string): Promise<User | null> {
  if (await isAccessTokenRevoked(token)) return null

  try {
    const payload = jwt.verify(token, env.SUPABASE_JWT_SECRET, {
      algorithms: ["HS256"],
    }) as SupabaseJwtPayload

    if (!payload.sub) return null
    if (await isUserSessionRevoked(payload.sub)) return null

    return toAuthUser(payload)
  } catch {
    return null
  }
}

export async function authMiddleware(
  request: Request,
  response: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = request.headers.authorization

  if (!authHeader?.startsWith("Bearer ")) {
    response.status(401).json({ success: false, message: "Token não fornecido" })
    return
  }

  const token = authHeader.split(" ")[1]

  const localUser = await verifyJwtLocally(token)
  if (localUser) {
    request.user = localUser
    request.accessToken = token
    next()
    return
  }

  const { data, error } = await supabaseAdmin.auth.getUser(token)

  if (error || !data.user) {
    response.status(401).json({ success: false, message: "Token inválido ou expirado" })
    return
  }

  if (await isUserSessionRevoked(data.user.id)) {
    response.status(401).json({ success: false, message: "Sessão encerrada. Faça login novamente." })
    return
  }

  request.user = data.user
  request.accessToken = token
  next()
}
