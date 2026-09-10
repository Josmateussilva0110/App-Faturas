# Específico deste projeto (app "fatura")

Camada substituível da skill: ao levar `flutter-app` para outro projeto,
troque este arquivo e mantenha o `SKILL.md`.

## Mapa

O app é `app/`, servido pelo backend Express em `backend/` (veja a skill
`rest-api-ts`).

```
lib/
├── core/config/env.dart        ApiConfig.baseUrl
├── core/theme/                 app_colors, app_spacing, app_theme
├── core/toast/app_toast.dart   toast global, sem BuildContext
├── data/api/                   api_client, request, api_response, api_routes,
│                               token_manager, refresh_service, auth_storage,
│                               secure_auth_storage, api_exception
├── data/services/              auth, profile, card, purchase
├── data/*_repository.dart      FaturaRepository + Mock + Api
├── models/                     purchase, card_model, salary, expense,
│                               app_user, auth_data, user_profile
├── state/app_state.dart        AppState (ChangeNotifier), estado único
├── features/                   uma pasta por tela
└── widgets/                    13 widgets compartilhados
```

## Estado

`AppState` é o único store. Telas usam `context.watch<AppState>()` para ler e
`context.read<AppState>()` em callbacks. O `_guard` interno é quem trata
falha de escrita: avisa por toast e **não** altera a lista local.

`AppState.load()` só pode ser chamado com sessão ativa — ele bate em
endpoints autenticados. Quem o chama é o `SessionGate` (boot) e a tela de
login (após entrar).

## Origem dos dados hoje

`ApiFaturaRepository` é **híbrido de propósito**:

| Dado | Origem |
|---|---|
| Cartões, compras | API real |
| Perfil (nome, email) | API real (`GET /profile`) |
| Salários, despesas, limite de gastos | ainda em memória (delegado ao mock) |

Quando as rotas faltantes existirem, troque método por método na seção
"Ainda sem endpoint no backend" e apague a delegação.

## Sessão

Boot passa pelo `SessionGate`: lê a sessão do `flutter_secure_storage`,
renova se o access token expirou, e entra direto no app. A tela de
apresentação só aparece sem sessão ou quando o backend rejeita o refresh.

O `api_client.dart` renova o token sozinho no 401 e repete a requisição. Não
chame `refreshAccessToken` à mão.

**Contrato invisível:** o `code` devolvido pelo `refresh` decide se o app
apaga a sessão. `SESSION_REVOKED` e `INVALID_CREDENTIALS` derrubam; qualquer
outra falha preserva, para queda de rede não deslogar ninguém.

## Formato de rede

A API responde `snake_case` (espelha as colunas). A tradução está no
`fromJson`/`toJson` de `Purchase` e `CardModel`.

- `card_id` nulo = cartão apagado (FK `ON DELETE SET NULL`) → vira string
  vazia, e o app mostra "Cartão removido".
- `POST` e `PUT` respondem **só com o id**; use `draft.withId(id)`.

## Rodar

```bash
cd app && flutter run --dart-define-from-file=env.json
```

**Sem a flag o app não acha o backend**: `ApiConfig.baseUrl` cai no padrão de
Android (`10.0.2.2`), que só existe no emulador, e o login falha com "Tempo
esgotado ao conectar". Hot reload não relê o `env.json` — só um run novo.

O console imprime `[api] baseUrl: ...` no boot em debug; é o jeito rápido de
conferir qual URL foi compilada.

`app/env.json` é gitignored (guarda o IP da máquina na rede local);
`env.example.json` é o modelo versionado.

## APK

```bash
cd app && flutter build apk --release --split-per-abi --dart-define=API_URL=http://192.168.1.15:3001/api
```

Assinado com a chave de **debug** (o `TODO` segue em
`android/app/build.gradle.kts`): instala e roda, mas não serve para a Play
Store. Para o release alcançar backend em HTTP puro existe
`android/app/src/release/` com um `network_security_config` liberando
cleartext **apenas** para o IP da rede local.

## Testes

`test/support/fake_api.dart` traz `FakeAdapter`, `jsonBody`, `defaultHandler`
e os payloads (`fakeSession`, `fakeProfile`, `fakeCards`, `fakePurchases`).

Ao sobrescrever o adapter num teste, **delegue o resto para
`defaultHandler`** — senão as rotas que a tela também chama (cartões,
compras) recebem resposta errada e o teste falha por motivo alheio.

O `_pumpApp` avança 300ms antes do `pumpAndSettle` porque a implementação em
memória simula latência; sem isso sobram timers pendentes.
