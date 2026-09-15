import { env } from "./config/env"
import { bootstrapInfrastructure, shutdownInfrastructure } from "./bootstrap"

async function main(): Promise<void> {
  await bootstrapInfrastructure()

  const { app } = require("./app") as typeof import("./app")

  const server = app.listen(env.PORT, "0.0.0.0", () => {
    console.log(`🔥 Servidor rodando na porta ${env.PORT} [${env.NODE_ENV}]`)
    console.log(`💚 Health check: / · /health · /api/health`)
  })

  // Prazo para o desligamento inteiro. Orquestradores dão uma carência curta
  // entre o SIGTERM e o SIGKILL (Docker: 10s por padrão); terminando antes,
  // quem encerra somos nós, e não um processo abatido no meio do caminho.
  const SHUTDOWN_TIMEOUT_MS = 8000

  let shuttingDown = false

  function shutdown(signal: string): void {
    // Dois sinais seguidos não podem abrir dois desligamentos concorrentes.
    if (shuttingDown) return
    shuttingDown = true

    console.log(`${signal} recebido — encerrando servidor...`)

    // Cobre as duas esperas: o `close` aguardando conexões e o Redis, que é
    // rede e pode não responder. Sem prazo, o processo fica de pé até o
    // SIGKILL — e aí nada disto roda.
    const forceExit = setTimeout(() => {
      console.error("Desligamento não terminou a tempo — encerrando à força.")
      process.exit(1)
    }, SHUTDOWN_TIMEOUT_MS)

    server.close(async () => {
      try {
        await shutdownInfrastructure()
      } catch (error) {
        // Falhar ao fechar o Redis não justifica travar o encerramento.
        console.error("Falha ao encerrar infraestrutura:", error)
      }
      clearTimeout(forceExit)
      console.log("Servidor encerrado.")
      process.exit(0)
    })

    // Redundante no Node 22, onde `close` já derruba as ociosas — medido.
    // Fica como rede de segurança para versões onde não derrubava: o
    // `engines` do projeto admite a 20, e sem isto uma keep-alive parada
    // atrás do proxy seguraria o fechamento até o prazo acima.
    server.closeIdleConnections()
  }

  process.on("SIGTERM", () => shutdown("SIGTERM"))
  process.on("SIGINT", () => shutdown("SIGINT"))
}

main().catch((error) => {
  console.error("Falha ao iniciar servidor:", error)
  process.exit(1)
})
