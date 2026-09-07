import path from "path"
import { config } from "dotenv"
import { z } from "zod"

// Local: carrega .env da raiz do monorepo ou de backend/
const backendRoot = path.resolve(__dirname, "../..")
const monorepoRoot = path.resolve(backendRoot, "..")
const quietDotenv = process.env.NODE_ENV === "production"
config({ path: path.join(monorepoRoot, ".env"), quiet: quietDotenv })
config({ path: path.join(backendRoot, ".env"), quiet: quietDotenv })

const envSchema = z.object({
    NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
    PORT: z.coerce.number().default(3001),
    SUPABASE_URL: z.url("SUPABASE_URL inválida"),
    SUPABASE_ANON_KEY: z.string().min(1, "SUPABASE_ANON_KEY ausente").optional(),
    EXPO_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1).optional(),
    SUPABASE_SERVICE_ROLE_KEY: z.string().min(1, "SUPABASE_SERVICE_ROLE_KEY ausente").transform((s) => s.trim()),
    SUPABASE_JWT_SECRET: z
        .string()
        .min(1, "SUPABASE_JWT_SECRET ausente — use o JWT Secret em Supabase → Settings → API")
        .transform((s) => s.trim()),
    ALLOWED_ORIGINS: z
        .string()
        .default("http://localhost:8081")
        .transform((val) => val.split(",").map((s) => s.trim()).filter(Boolean)),
    TRUST_PROXY_HOPS: z.coerce.number().int().min(0).max(5).default(1),
    RENDER_EXTERNAL_URL: z.string().url().optional(),
    REDIS_URL: z.string().url().optional(),
}).transform((data) => {
    const anonKey = data.SUPABASE_ANON_KEY ?? data.EXPO_PUBLIC_SUPABASE_ANON_KEY
    if (!anonKey) {
        throw new z.ZodError([{
            code: "custom",
            path: ["SUPABASE_ANON_KEY"],
            message: "Defina SUPABASE_ANON_KEY ou EXPO_PUBLIC_SUPABASE_ANON_KEY",
        }])
    }

    const origins = new Set(data.ALLOWED_ORIGINS)
    if (data.RENDER_EXTERNAL_URL) {
        origins.add(data.RENDER_EXTERNAL_URL)
    }

    const { EXPO_PUBLIC_SUPABASE_ANON_KEY: _, RENDER_EXTERNAL_URL: __, ...rest } = data
    return { ...rest, SUPABASE_ANON_KEY: anonKey, ALLOWED_ORIGINS: [...origins] }
})

const parsed = envSchema.safeParse(process.env)

if (!parsed.success) {
    console.error("❌ Variáveis de ambiente inválidas:")
    console.error(parsed.error.flatten().fieldErrors)
    process.exit(1)
}

export const env = parsed.data
