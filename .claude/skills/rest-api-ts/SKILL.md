---
name: rest-api-ts
description: Padrões de API REST em TypeScript com camadas route/controller/service, envelope de resposta único, ServiceResult em vez de exceções, validação por schema no middleware e mapa de código de erro para status HTTP. Use sempre que a tarefa envolver criar ou alterar endpoint, rota, controller, service, schema de validação, middleware, código de erro ou tratamento de erro numa API TypeScript/Express, mesmo que o pedido não use essas palavras — inclui frases como "cria um endpoint de X", "adiciona validação em Y", "esse endpoint está retornando erro", "preciso salvar isso no servidor", ou pedidos que chegam pelo lado do cliente e exigem mudança na API.
---

# API REST em TypeScript — padrões de camadas e contrato

Este é o conjunto de convenções para APIs REST em TypeScript onde o cliente
(app mobile, SPA) tem **um único parser de resposta**. Nesse arranjo, uma rota
que foge do formato não dá erro de compilação nem de teste: a chamada
"funciona" e o cliente mostra erro genérico. As regras abaixo existem para
tornar esse tipo de quebra impossível, não por estilo.

Se o projeto tiver um arquivo `references/project.md` ao lado deste, leia-o
também: é onde ficam as escolhas específicas do projeto (banco, provedor de
autenticação, caminhos, armadilhas já vividas).

## Camadas

```
src/
├── routes/        # caminho + middlewares. Zero lógica.
├── controllers/   # resultado do service -> HTTP. Zero regra de negócio.
├── services/      # regra de negócio, fala com o banco. Nunca lança.
├── schemas/       # validação de entrada, um arquivo por payload
├── middleware/    # auth, validate, rate limit, errorHandler, notFound
├── types/         # ServiceResult, envelope de resposta, códigos de erro
├── errors/        # mapa código -> status HTTP
├── constants/     # listas de colunas, valores fixos
└── utils/         # helpers puros
```

O teste que mantém as camadas honestas: **se você precisa do objeto
`response` dentro de um service, ou do cliente de banco dentro de um
controller, a lógica está na camada errada.**

## Envelope de resposta

Todo endpoint responde a mesma forma:

```ts
interface HttpResponse<T = unknown> {
  success: boolean
  message: string
  data?: T
  errors?: Array<{ field: string; message: string }>
}
```

```ts
{ success: true,  message: "Perfil atualizado com sucesso.", data: {...} }
{ success: false, message: "Usuário não encontrado." }
{ success: false, message: "Erro de validação", errors: [{ field, message }] }
```

O `field` em `errors` não é decorativo: clientes usam ele para marcar o input
correspondente na tela. Renomear um campo no schema muda onde a mensagem
aparece para o usuário — é mudança de contrato, não refactor interno.

## ServiceResult em vez de exceção

```ts
export type ServiceResult<T = void, E extends string = string> =
  | { status: true;  data: T }
  | { status: false; error: { code: E; message?: string } }
```

O motivo de não lançar: a tradução de erro para status HTTP acontece num
lugar só. Se cada service lançasse, todo `catch` teria que decidir de novo se
aquilo é 404, 409 ou 500 — e eles divergiriam. Com o resultado tipado, o
controller vira um tradutor de seis linhas e o compilador cobra os casos.

## Controller — sempre esta forma

```ts
async metodo(request: Request, response: Response): Promise<Response> {
  const result = await Service.metodo(...)

  if (!result.status) {
    const httpStatus = getHttpStatusFromError(result.error.code, errorHttpStatusMap)
    return response.status(httpStatus).json({
      success: false,
      message: result.error.message,
    })
  }

  return response.status(200).json({
    success: true,
    message: "...",
    data: result.data,
  })
}
```

Quando o cliente precisar reagir a um erro específico — por exemplo, apagar a
sessão local só quando a sessão foi revogada, e não quando a rede falhou —
inclua também o `code` no corpo do erro. Trate isso como contrato: mudar
aquele código muda o comportamento do cliente.

Métodos que usam `this` precisam de `.bind(Controller)` ao serem passados
para a rota.

## Service — sempre esta forma

```ts
async metodo(...): Promise<ServiceResult<Tipo, ErrorCode>> {
  try {
    const { data, error } = await db...

    if (error || !data) {
      console.error("[Service.metodo]", error)
      return { status: false, error: { code: ErrorCode.X, message: "Mensagem para o usuário." } }
    }

    return { status: true, data: mapear(data) }
  } catch (error) {
    console.error("[Service.metodo] error:", error)
    return { status: false, error: { code: ErrorCode.X_FAILED, message: "Erro ao ..." } }
  }
}
```

Dois pontos que importam:

- **O log recebe o erro cru; a resposta leva mensagem genérica.** Detalhe de
  banco no log do servidor, nunca na tela — mensagem de erro de driver
  costuma revelar nome de tabela, coluna e às vezes o próprio dado.
- **Nunca logar token, senha ou credencial.** É o vazamento mais fácil de
  cometer sem perceber, e o mais difícil de auditar depois.
- **Sempre mapear a linha do banco para um tipo próprio** antes de devolver.
  Retornar a linha crua vaza colunas internas para o cliente na primeira vez
  que alguém adicionar um campo na tabela.

## Rota

```ts
router.post("/login", loginRateLimiter, validate(LoginSchema), Controller.login)
router.put("/profile", authMiddleware, validate(UpdateProfileSchema), Controller.updateProfile)
```

Ordem dos middlewares: **rate limit → auth → validate → controller**. Da
verificação mais barata para a mais cara — não faz sentido validar o corpo de
uma requisição que será recusada por falta de token.

Rotas de autenticação precisam de rate limiter. Prefira contar apenas as
tentativas que falham (no `express-rate-limit`,
`skipSuccessfulRequests: true`), para não punir quem acerta a senha.

## Validação

A validação mora num middleware `validate(Schema)`, nunca dentro do
controller. Ele responde **422** com a lista de `errors` no formato do
envelope e só chama `next()` com os dados já convertidos.

Manter isso fora do controller é o que garante que toda rota falhe da mesma
maneira — e o cliente só precisa entender um formato de erro de validação.

## Códigos de erro

Todo erro novo entra em dois lugares:

1. O enum de códigos (`ErrorCode`)
2. O mapa de status HTTP

```ts
export const errorHttpStatusMap: Record<ErrorCode, number> = {
  [ErrorCode.NOT_FOUND]: 404,
  [ErrorCode.INVALID_CREDENTIALS]: 401,
  // ...
}
```

Tipar o mapa como `Record<ErrorCode, number>` é intencional: adicionar um
código sem definir o status **quebra a compilação**, em vez de virar um 400
silencioso em produção.

## Acesso ao banco

Use sempre o cliente de **menor privilégio** que resolve a tarefa. Projetos
costumam ter um cliente administrativo que ignora as regras de acesso por
linha e um cliente de usuário que as respeita. Ler dado de usuário com o
cliente administrativo funciona, passa nos testes e desliga silenciosamente a
proteção — a partir daí, um bug de filtro vira vazamento entre contas.

Ao mexer numa lista de colunas de `SELECT`, confira contra as migrations. A
maioria dos bancos rejeita a **query inteira** quando uma coluna não existe,
então um campo errado não derruba um campo: derruba o endpoint.

## Passo a passo para um endpoint novo

1. Migration, se envolver coluna ou tabela nova
2. Schema de validação, se houver corpo ou query
3. Método no service, devolvendo `ServiceResult`
4. Código novo no enum + no mapa de status, se houver erro novo
5. Método no controller, na forma acima
6. Rota, com os middlewares na ordem certa
7. Checagem de tipos antes de encerrar
8. Do lado do cliente: a função correspondente e a constante da rota

## Higiene de configuração

- Valide as variáveis de ambiente na subida e **falhe cedo** se faltar algo —
  descobrir chave ausente no primeiro request de produção é caro.
- Desligue parsers que você não usa. `express.urlencoded`, por exemplo, é
  superfície de prototype pollution numa API que só fala JSON.
- Limite o tamanho do corpo (`express.json({ limit: "10kb" })`).
- CORS por allowlist. Requisições sem `Origin` (apps nativos) passam; clientes
  web precisam entrar na lista explicitamente.
