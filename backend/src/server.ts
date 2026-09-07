import { env } from "./config/env"
import { bootstrapInfrastructure, shutdownInfrastructure } from "./bootstrap"

async function main(): Promise<void> {
  await bootstrapInfrastructure()

  const { app } = require("./app") as typeof import("./app")

  const server = app.listen(env.PORT, "0.0.0.0", () => {
    console.log(`🔥 Servidor rodando na porta ${env.PORT} [${env.NODE_ENV}]`)
    console.log(`💚 Health check: / · /health · /api/health`)
  })

  function shutdown(signal: string): void {
    console.log(`${signal} recebido — encerrando servidor...`)
    server.close(async () => {
      await shutdownInfrastructure()
      console.log("Servidor encerrado.")
      process.exit(0)
    })
  }

  process.on("SIGTERM", () => shutdown("SIGTERM"))
  process.on("SIGINT", () => shutdown("SIGINT"))
}

main().catch((error) => {
  console.error("Falha ao iniciar servidor:", error)
  process.exit(1)
})
