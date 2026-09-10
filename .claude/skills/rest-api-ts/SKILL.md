---
name: rest-api-ts
description: Padrões de API REST em TypeScript com camadas route/controller/service/model, envelope de resposta único, ServiceResult em vez de exceções, validação com zod no middleware e mapa de código de erro para status HTTP. Use sempre que a tarefa envolver criar ou alterar endpoint, rota, controller, service, schema de validação, middleware, código de erro ou tratamento de erro numa API TypeScript/Express, mesmo que o pedido não use essas palavras — inclui frases como "cria um endpoint de X", "adiciona validação em Y", "esse endpoint está retornando erro", "preciso salvar isso no servidor", ou pedidos que chegam pelo lado do cliente e exigem mudança na API.
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

O fluxo é sempre o mesmo:

```
routes -> controller -> service
routes -> controller -> service -> model   (quando o acesso a dados cresce)
```

```
src/
├── routes/        # caminho + middlewares. Zero lógica.
├── controllers/   # resultado do service -> HTTP. Zero regra de negócio.
├── services/      # regra de negócio. Nunca lança.
├── models/        # acesso a dados e mapeamento de linha -> tipo (opcional)
├── schemas/       # zod, um arquivo por payload, agrupado por domínio
├── middleware/    # auth, validate, rate limit, errorHandler, notFound
├── types/         # ServiceResult, envelope de resposta, códigos de erro
├── errors/        # mapa código -> status HTTP
├── constants/     # listas de colunas, valores fixos
└── utils/         # helpers puros
```

O teste que mantém as camadas honestas: **se você precisa do objeto
`response` dentro de um service, ou do cliente de banco dentro de um
controller, a lógica está na camada errada.**

### Como `schemas/` é organizado

Uma subpasta por domínio, com os mesmos nomes de `types/` — quem procura o
schema de cartão vai em `schemas/cards/` porque `types/cards/` existe. A pasta
já diz que o arquivo é um schema, então o nome dele não repete a palavra.

```
schemas/
├── fields/       # pedaços de campo reaproveitados (passwordField, amountField)
├── auth/         # login, refresh, changePassword, passwordResetRequest
├── users/        # updateProfile, spendingLimit
├── cards/        # card
├── purchases/    # purchase
├── salaries/     # salary
├── expenses/     # expense
└── statements/   # statement
```

`fields/` é a única pasta que não é um domínio: ela guarda os construtores de
campo que os payloads compõem (`entryNameField`, `amountField`,
`usernameField`). Extrair um campo para lá vale a pena quando dois payloads
precisam do mesmo limite — é o que impede que eles divirjam sem ninguém notar.

### Quando criar a camada de model

O model não é obrigatório. Para um CRUD simples, o service falar direto com o
banco é mais claro do que atravessar uma camada que só repassa a chamada.

Crie o model quando aparecer um destes sinais:

- a mesma consulta é usada por mais de um service;
- o service começa a ter mais linhas de montagem de query do que de regra de
  negócio;
- o mapeamento de linha para tipo ficou complexo o bastante para ter casos.

Nesse ponto a camada passa a pagar o próprio custo: a regra de negócio volta a
caber na cabeça, e trocar o banco vira mudança local.

## Nomenclatura e comentários

**Identificadores em inglês** — funções, variáveis, tipos, arquivos.
**Comentários em português**, curtos e só quando fazem falta.

A divisão tem motivo: o vocabulário em volta já é inglês (`request`,
`response`, `next`, `data`, `error`), e misturar idiomas produz coisas como
`buscarUserById`. Comentário é outra coisa — é conversa entre pessoas do
time, e ali o português comunica melhor e mais rápido.

Comentário bom explica **por quê**, não **o quê**. O código já diz o quê:

```ts
// Ruim: repete o que a linha abaixo já mostra
// Incrementa o contador
attempts += 1

// Bom: explica a decisão, que o código não consegue mostrar
// Só tentativas que falharam contam, para não punir quem acerta a senha
attempts += 1
```

Quando o código precisa de um comentário para ser entendido, considere antes
renomear ou extrair — costuma resolver melhor que a explicação.

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

**`create` e `update` respondem só com o `id`**, não com o recurso inteiro. O
cliente acabou de enviar os demais campos, então devolvê-los é tráfego sem
uso — e no banco significa um `SELECT` de todas as colunas em vez de uma. As
leituras (`GET`) é que trazem o recurso completo.

Quando o cliente precisar reagir a um erro específico — por exemplo, apagar a
sessão local só quando a sessão foi revogada, e não quando a rede falhou —
inclua também o `code` no corpo do erro. Trate isso como contrato: mudar
aquele código muda o comportamento do cliente.

### Onde colocam-se os helpers de cada camada

Métodos de controller são passados soltos para o roteador
(`router.get(..., Controller.list)`), então **`this` é `undefined` dentro
deles**. A consequência prática importa: helper de controller vai para
`utils/`, nunca para método privado — o método privado compila normalmente e
quebra só em runtime, no primeiro request. Se precisar mesmo de `this`, a
rota tem que passar `Controller.metodo.bind(Controller)`.

Em service é o contrário: eles são sempre chamados como `Service.metodo()`,
então `this` funciona. Lógica que só aquele service usa pertence a um método
privado dele; o que serve a vários vira helper em `utils/`.

O objetivo dos dois lados é o mesmo: arquivos de controller e service com
imports e a classe, sem funções soltas no topo.

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
- **Desfecho esperado não é `console.error`.** Nome já em uso, registro não
  encontrado, credencial errada: são respostas normais da API (409, 404,
  401), não falhas. Registrá-los como erro faz o uso corriqueiro do app
  poluir o log e, em produção, disparar alerta à toa. Trate esses casos
  *antes* da linha de log.
- **Nunca logar token, senha ou credencial.** É o vazamento mais fácil de
  cometer sem perceber, e o mais difícil de auditar depois.
- **Sempre mapear a linha do banco para um tipo próprio** antes de devolver.
  Retornar a linha crua vaza colunas internas para o cliente na primeira vez
  que alguém adicionar um campo na tabela.

## Funções pequenas e sem repetição

Quando um método faz mais de uma coisa — valida, transforma, consulta e
formata — extraia as partes. O sinal prático: **se você precisou de um
comentário para separar "seções" dentro da função, cada seção provavelmente é
uma função.** Nomeie a extração pelo que ela decide, não pelo passo do
processo (`mapPasswordUpdateError` diz mais que `step2`).

Isso não é estética. Função que faz uma coisa só é a que dá para testar
isoladamente, reaproveitar e ler sem rolar a tela.

Nesta arquitetura a duplicação aparece quase sempre nos mesmos três lugares —
vale extrair já na segunda ocorrência:

- **o bloco de erro do controller** (traduzir código para status e montar o
  corpo). Extraia um `sendFailure(response, error, statusMap)` genérico no
  código de erro, recebendo o mapa por parâmetro — assim ele serve a todos os
  recursos, e o genérico amarra enum e mapa: passar o mapa de outro domínio
  não compila;
- **o mapeamento de linha do banco para tipo**, repetido entre `get` e
  `update` do mesmo recurso;
- **listas de colunas de `SELECT`**, que devem morar em `constants/`, senão
  divergem entre as consultas do mesmo recurso.

Duplicação que ainda não se repetiu não é duplicação: duas coisas parecidas
que mudam por razões diferentes devem continuar separadas. Abstrair cedo
demais custa mais caro que copiar uma vez.

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

## Validação com zod

**Todo dado vindo do cliente passa por um schema zod** — corpo, query e
params — antes de chegar ao controller. Sem exceção. Endpoint que confia no
formato enviado pelo cliente é por onde entra dado malformado, e depois
payload construído de propósito.

A validação mora num middleware `validate(Schema)`, nunca dentro do
controller. Ele responde **422** com a lista de `errors` no formato do
envelope e só chama `next()` com os dados já convertidos.

```ts
// schemas/cards/card.ts
export const CreateCardSchema = z.object({
  name: z.string().trim().min(1, "Informe o nome do cartão.").max(60, "Nome muito longo."),
})

export type CreateCardDTO = z.infer<typeof CreateCardSchema>
```

Três detalhes que fazem diferença:

- **Mensagens em português**, porque elas chegam ao usuário final pelo campo
  `errors[].message`.
- **O tipo sai do schema com `z.infer`**, nunca declarado à mão em paralelo.
  Assim o schema é a única fonte da verdade e não existe o caso de o tipo
  dizer uma coisa e a validação aceitar outra.
- **Normalize na validação** (`trim`, `toLowerCase`), não no controller — o
  resto do código recebe o dado já limpo.

Manter isso fora do controller é o que garante que toda rota falhe da mesma
maneira, e o cliente só precisa entender um formato de erro de validação.

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

**Nunca decida de quem é o dado por um id vindo do cliente.** O dono sai do
token autenticado; o id do corpo ou da URL serve no máximo para dizer *qual*
registro, e ainda assim filtrado pelo dono. É a diferença entre um endpoint
correto e um que entrega a conta de outra pessoa para quem trocar um número
na requisição.

## Desempenho

Antes de otimizar, meça — mas estes quatro erros são caros e fáceis de evitar
desde o início:

- **Chamadas independentes vão em paralelo** (`Promise.all`). `await`
  encadeado soma latências que poderiam correr juntas; num endpoint que faz
  três consultas, isso é a diferença entre 90ms e 270ms.
- **Filtre, ordene e pagine no banco**, não em JavaScript. Trazer mil linhas
  para descartar novecentas gasta rede, memória e tempo de serialização.
- **Selecione só as colunas que usa.** Além de mais leve, evita vazar coluna
  nova sem querer.
- **Cuidado com N+1**: consulta dentro de laço vira N consultas. Busque em
  lote e junte na memória.

## Passo a passo para um endpoint novo

1. Migration, se envolver coluna ou tabela nova
2. Schema zod em `schemas/<domínio>/`, com o DTO saindo de `z.infer`
3. Acesso a dados: no service mesmo, ou no model se algum dos sinais acima
   aparecer
4. Método no service, devolvendo `ServiceResult`
5. Código novo no enum + no mapa de status, se houver erro novo
6. Método no controller, na forma acima
7. Rota, com os middlewares na ordem certa
8. Checagem de tipos antes de encerrar
9. Do lado do cliente: a função correspondente e a constante da rota

## Higiene de configuração

- Valide as variáveis de ambiente na subida e **falhe cedo** se faltar algo —
  descobrir chave ausente no primeiro request de produção é caro.
- Desligue parsers que você não usa. `express.urlencoded`, por exemplo, é
  superfície de prototype pollution numa API que só fala JSON.
- Limite o tamanho do corpo (`express.json({ limit: "10kb" })`).
- CORS por allowlist. Requisições sem `Origin` (apps nativos) passam; clientes
  web precisam entrar na lista explicitamente.
