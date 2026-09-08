# Específico deste projeto (contas)

Este arquivo é a camada substituível da skill: ao levar `rest-api-ts` para
outro projeto, troque o conteúdo daqui e mantenha o `SKILL.md` como está.

## Onde as coisas estão

O backend é `backend/` (Express + TypeScript), servindo o app Flutter em
`app/`. As camadas descritas no SKILL.md ficam em `backend/src/`.

## Clientes Supabase

`database/supabase/supabase.ts` exporta quatro, e a escolha é decisão de
segurança:

| Cliente | Quando usar |
|---|---|
| `createSupabaseClientForUser(accessToken)` | **Padrão para dados do usuário.** Emite JWT próprio e respeita RLS. |
| `supabaseAuth` | Fluxos de auth com a anon key (login, refresh). |
| `createEphemeralAuthClient()` | Reauth e troca de senha — isolado por requisição, para sessão não vazar entre chamadas. |
| `supabaseAdmin` | Service role, **ignora RLS**. Só APIs admin (`auth.admin.signOut`) e scripts. |

## Autenticação

`authMiddleware` valida o JWT localmente com `SUPABASE_JWT_SECRET` (rápido,
sem ida à rede) e só cai para `supabaseAdmin.auth.getUser` se falhar. Antes
de aceitar, consulta as listas de revogação (`isAccessTokenRevoked`,
`isUserSessionRevoked`), que usam Redis quando disponível e `Map` em memória
caso contrário.

Popula `request.user` e `request.accessToken`. Nos services, obtenha o id com
`getUserIdFromAccessToken(accessToken)` — nunca confie em id vindo do corpo.

## Contratos com o app Flutter

O app tem um parser único em `app/lib/data/api/request.dart`. Dois
acoplamentos que não são óbvios lendo só o backend:

- O `field` do erro 422 decide **em qual input** a mensagem aparece na tela
  de login (`_applyFieldErrors` em `login_screen.dart`).
- O `code` devolvido pelo `refresh` decide se o app **apaga a sessão local**.
  `SESSION_REVOKED` e `INVALID_CREDENTIALS` derrubam a sessão; qualquer outra
  falha a preserva. Ver `refresh_service.dart`.

## Armadilhas já vividas

- **`USER_PROFILE_SELECT` pedia `earnings_percent`, coluna inexistente em
  todas as migrations.** O Postgres rejeitou a query inteira (erro `42703`),
  derrubando todo o `GET /profile` — não só aquele campo.
- **Não existe rota de registro, e é intencional.** Contas nascem direto no
  Supabase Auth. Senha temporária via `scripts/reset-user-password.ts`.
- **`must_change_password` existe no banco e é usado no `changePassword`,
  mas `mapUserProfileRow` não devolve o campo** — o app não tem como forçar a
  troca. Expor exige mudança nos dois lados.

## Comandos

```bash
cd backend && npm run dev        # ts-node-dev, recarrega ao salvar
cd backend && npx tsc --noEmit   # checagem de tipos
```
