import express, { type Request, type Response } from "express"
import cors from "cors"
import helmet from "helmet"
import compression from "compression"
import { env } from "./config/env"
import { rateLimiter } from "./middleware/rateLimiter"
import { healthRateLimiter } from "./middleware/healthRateLimit"
import { errorHandler } from "./middleware/errorHandler"
import { notFound } from "./middleware/notFound"
import router from "./routes/routes"

function healthPayload() {
    if (env.NODE_ENV === "production") {
        return { status: "ok" }
    }
    return { status: "ok", env: env.NODE_ENV }
}

export const app = express()

// ── Segurança ────────────────────────────────────────────
// Render/Belmo: 1 hop de proxy. Ajuste TRUST_PROXY_HOPS se o deploy mudar.
app.set("trust proxy", env.TRUST_PROXY_HOPS)

app.use(helmet())
app.use(compression())

app.use(cors({
    origin(origin, callback) {
        if (!origin) return callback(null, true)
        if (env.ALLOWED_ORIGINS.includes(origin)) return callback(null, true)
        callback(new Error("CORS: origin não permitida"))
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"],
}))

// ── Rotas ────────────────────────────────────────────────
const sendHealth = (_req: Request, res: Response) => {
    res.json(healthPayload())
}

app.get("/", healthRateLimiter, sendHealth)
app.get("/health", healthRateLimiter, sendHealth)
app.get("/api/health", healthRateLimiter, sendHealth)

app.use(rateLimiter)

// API JSON-only — urlencoded desabilitado (superfície de Prototype Pollution via qs)
app.use(express.json({ limit: "10kb" }))

app.use("/api", router)


app.use(notFound)
app.use(errorHandler)
