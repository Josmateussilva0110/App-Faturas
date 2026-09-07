/**
 * Script de suporte: reseta senha temporária e exige troca no próximo login.
 *
 * Uso:
 *   cd backend
 *   npx ts-node scripts/reset-user-password.ts <email> [nova-senha-temporaria]
 *
 * Requer SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY no ambiente.
 */
import { createClient } from "@supabase/supabase-js"
import { config } from "dotenv"
import path from "path"

const backendRoot = path.resolve(__dirname, "..")
const monorepoRoot = path.resolve(backendRoot, "..")

config({ path: path.join(monorepoRoot, ".env") })
config({ path: path.join(backendRoot, ".env") })

const supabaseUrl = process.env.SUPABASE_URL
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !serviceRoleKey) {
  console.error("Defina SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY no .env")
  process.exit(1)
}

const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
})

function generateTemporaryPassword() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#$%"
  let password = "Aa1!"

  for (let index = password.length; index < 12; index += 1) {
    password += chars[Math.floor(Math.random() * chars.length)]
  }

  return password
}

async function main() {
  const email = process.argv[2]?.trim().toLowerCase()
  const temporaryPassword = process.argv[3] ?? generateTemporaryPassword()

  if (!email) {
    console.error("Uso: npx ts-node scripts/reset-user-password.ts <email> [nova-senha-temporaria]")
    process.exit(1)
  }

  const { data: userRow, error: userError } = await supabaseAdmin
    .from("users")
    .select("id, email")
    .eq("email", email)
    .maybeSingle()

  if (userError || !userRow) {
    console.error("Usuário não encontrado para o e-mail informado.")
    process.exit(1)
  }

  const { error: authError } = await supabaseAdmin.auth.admin.updateUserById(userRow.id, {
    password: temporaryPassword,
  })

  if (authError) {
    console.error("Falha ao resetar senha:", authError.message)
    process.exit(1)
  }

  const { error: flagError } = await supabaseAdmin
    .from("users")
    .update({ must_change_password: true })
    .eq("id", userRow.id)

  if (flagError) {
    console.error("Senha resetada, mas falhou ao marcar must_change_password:", flagError.message)
    process.exit(1)
  }

  await supabaseAdmin
    .from("password_reset_requests")
    .update({
      status: "resolved",
      resolved_at: new Date().toISOString(),
      resolved_by: "support-script",
    })
    .eq("user_id", userRow.id)
    .eq("status", "pending")

  console.log(`Senha temporária definida para ${userRow.email}`)
  console.log(`Senha: ${temporaryPassword}`)
  console.log("O usuário será obrigado a trocar a senha no próximo login.")
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
