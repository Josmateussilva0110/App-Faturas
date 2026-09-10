---
name: flutter-app
description: Padrões do app Flutter — camadas feature/state/repository/service, estado com ChangeNotifier e Provider, repositório atrás de interface para trocar mock por API, camada de rede que devolve envelope em vez de lançar, mapeamento JSON no modelo e widgets compartilhados com tokens de tema. Use sempre que a tarefa tocar qualquer arquivo em lib/ ou test/ do app, mesmo que o pedido não cite Flutter — criar ou alterar tela, formulário, widget, estado, repositório, chamada de API, modelo, tema ou teste de widget. Vale também para pedidos que chegam pelo lado visual ("a tela tal está estranha", "adiciona um campo no formulário") e para os que chegam pelo backend e precisam aparecer no app.
---

# App Flutter — camadas, estado e rede

O app é organizado para que a interface possa ser construída e testada sem
depender do backend, e para que trocar a origem dos dados não encoste em
nenhuma tela.

Se existir `references/project.md` ao lado deste arquivo, leia também: é onde
ficam as escolhas específicas do projeto (rotas, sessão, o que já está ligado
na API e o que ainda é mock).

## Camadas

```
tela (features/) → estado (state/) → repositório (data/) → service (data/services/) → requestData
```

```
lib/
├── core/       tema, formatação, toast, configuração de build
├── data/
│   ├── api/        cliente HTTP, envelope, rotas, sessão
│   ├── services/   uma função por endpoint
│   └── *_repository.dart   a interface e suas implementações
├── models/     entidades + fromJson/toJson
├── state/      ChangeNotifier com o estado do app
├── features/   uma pasta por tela; widgets/ para os pedaços dela
└── widgets/    widgets compartilhados entre telas
```

A regra que mantém isso honesto: **tela não conhece repositório nem service.**
Ela fala com o estado, e só. Se uma tela precisa importar algo de `data/`,
provavelmente falta um método no estado.

## Nomenclatura e comentários

**Identificadores em inglês** — classes, métodos, variáveis, arquivos.
**Comentários em português**, curtos e só quando fazem falta.

O vocabulário em volta já é inglês (`build`, `context`, `state`, `widget`), e
misturar idiomas produz coisas como `construirCardWidget`. Comentário é
conversa entre pessoas do time, e ali o português comunica melhor.

Texto que o usuário lê — rótulos, mensagens, títulos — é português, e mora no
widget, não em constante distante.

Comentário bom explica **por quê**. O código já diz o quê.

## Estado

Um `ChangeNotifier` central, exposto por `Provider`. As telas leem assim:

- `context.watch<AppState>()` — reconstrói a tela quando qualquer coisa muda.
  Use quando a tela mostra várias partes do estado.
- `context.select<AppState, T>((s) => s.campo)` — reconstrói só quando aquele
  campo muda. Prefira em telas grandes ou em widgets que dependem de um dado
  só; `watch` num widget caro reconstrói tudo à toa.
- `context.read<AppState>()` — **nunca no `build`**. É para callbacks:
  `onPressed: () => context.read<AppState>().addCard(name)`.

Regra de negócio mora no estado, não na tela. Cálculo derivado (totais,
filtros por mês, agrupamentos) é getter do estado — assim duas telas que
mostram o mesmo número não podem discordar.

## Repositório atrás de interface

O estado depende de uma **interface** de repositório, nunca de uma
implementação. Isso paga em três momentos:

- a interface pode ter uma implementação em memória, e aí a interface inteira
  é construída e navegável antes de o backend existir;
- os testes rodam sem rede;
- trocar a origem dos dados é mudar uma linha na injeção, sem tocar em tela.

Implementações parciais são legítimas: quando só parte dos endpoints existe,
a implementação de API delega o resto para a de memória, numa seção marcada.
É melhor que travar a interface esperando o backend ficar pronto.

## Rede

**A camada de API nunca lança.** Toda chamada volta num envelope com
`success`, `message` e o dado — inclusive falha de rede. Assim nenhum ponto
do app precisa de `try/catch` para uma chamada dar errado; o código decide
olhando o resultado.

A conversão acontece na fronteira do repositório: ele expõe valores
(`List<Purchase>`, não envelope), então traduz falha em **exceção tipada** do
app.

O estado é quem captura essa exceção. E aqui está a regra que evita o bug
mais chato dessa arquitetura: **quando a escrita falha, o estado local não
muda.** Se a lista da tela for atualizada antes da confirmação do servidor, o
usuário vê algo que não foi salvo e que some no próximo boot.

```dart
Future<void> addCard(String name) async {
  final created = await _guard(() => _repository.createCard(name));
  if (created == null) return;   // falhou: avisou o usuário e não mexeu na lista

  cards = [...cards, created];
  notifyListeners();
}
```

Na carga inicial, falha **não pode** travar a tela de abertura nem parecer
sessão expirada: mostre o motivo e abra o app vazio, para o usuário poder
tentar de novo.

## Modelos e formato de rede

A API costuma usar `snake_case` (espelhando o banco) e o Dart usa
`camelCase`. Essa tradução mora no `fromJson`/`toJson` do modelo, **e em
nenhum outro lugar** — espalhar `json['card_id']` pelas telas é o que faz uma
renomeação no backend virar caça ao tesouro.

Dois cuidados que economizam depuração:

- **Campo nulo tem significado.** Decida no `fromJson` o que ele vira e
  comente. Um `card_id` nulo pode ser "cartão removido", não erro.
- **`toJson` não manda o `id`** em criação: quem o define é o servidor.

Quando o `POST`/`PUT` responde só com o id, o objeto é remontado localmente a
partir do que foi enviado (`draft.withId(id)`), em vez de um `GET` para reler
o que o app acabou de mandar.

## Widgets

**Cores, espaçamentos e raios vêm dos tokens do tema**, nunca literais no
widget. `Theme.of(context).colorScheme` e as constantes de espaçamento
existem para o tema escuro não apodrecer: um `Colors.white` cravado fica
invisível no escuro e ninguém percebe até alguém reclamar.

**Componentes modularizados.** Um widget resolve uma coisa, recebe o que
precisa por parâmetro e não busca dado do estado por conta própria. Widget
que aparece em duas telas vira compartilhado; widget que só serve a uma tela
mora em `features/<tela>/widgets/`.

**Formulário é um arquivo só, usado por criar e editar.** O padrão são três
arquivos: os campos (`*_form_fields.dart`), a tela de criação e a de edição,
ambas importando os mesmos campos. Duplicar o formulário parece mais simples
no dia, e o resultado é sempre o mesmo: um dos dois ganha uma validação ou um
campo novo e o outro fica para trás, sem ninguém notar até o usuário
reclamar. O arquivo de campos devolve um objeto de valores já validado; quem
decide o que fazer com ele é cada tela.

Quando um `build` cresce, extraia widgets em vez de métodos `_buildAlgo()`:
widget tem `const`, chave própria e reconstrói sozinho; método privado
reconstrói junto com o pai.

## Tema central e cores

**Um arquivo de tema para o app inteiro**, acessível por contexto
(`Theme.of(context)`), definindo o esquema a partir de uma cor semente. Nunca
uma cor literal dentro de um widget: além de quebrar o tema escuro, espalha
uma decisão visual por dezenas de arquivos, e mudar a identidade do app vira
busca e substituição.

Ao escolher cores, use as relações entre elas em vez de gosto pontual:

- **Uma cor semente gera o esquema.** Primária, superfícies e estados saem
  dela em harmonia; inventar uma cor por tela produz um app que parece
  remendado.
- **Matiz carrega significado, e isso é convenção cultural.** Verde para
  entrada e confirmação, vermelho para erro e saída, âmbar para atenção.
  Contrariar isso obriga o usuário a ler o que poderia reconhecer.
- **Contraste é requisito, não estética.** Texto precisa de contraste
  suficiente com o fundo nos dois temas — o que fica elegante no claro
  costuma sumir no escuro.
- **Saturação alta em área grande cansa.** Cor forte funciona em acento
  (botão, ícone, badge); fundo pede tom dessaturado.
- **Categorias com cor fixa por rótulo**, derivada de hash, mantêm a mesma
  pessoa ou cartão sempre da mesma cor em todas as telas — o usuário passa a
  reconhecer sem ler.

Espaçamento e raio de borda seguem a mesma lógica: constantes no tema, não
números soltos. Uma escala pequena e repetida é o que faz telas diferentes
parecerem o mesmo app.

## Fronteira de confiança

**O cliente nunca é fonte de verdade.** Ele roda no aparelho do usuário, pode
ser inspecionado, modificado e ter as requisições forjadas. Disso decorre:

- **Regra de negócio e validação valem no backend.** A validação no app é
  conveniência — evita ida à rede e dá erro imediato no campo certo. Ela não
  substitui a do servidor; as duas existem, e a que protege é a de lá.
- **Nunca envie identificador de dono.** Quem é o usuário sai do token, no
  servidor. Se o app manda `user_id` no corpo e o backend confia, trocar um
  número na requisição alcança dado alheio.
- **Filtros, ordenação e paginação vêm do backend.** Trazer tudo e filtrar em
  Dart parece mais rápido de escrever e quebra na primeira conta com muitos
  registros: gasta rede, memória e bateria para descartar a maior parte. O
  banco tem índice para isso; o app não.
- **Cálculo que vira dinheiro ou permissão é do servidor.** O app pode
  exibir um total, mas quem o confirma é quem grava.

## Segredos e dados sensíveis

**Tudo que é embarcado no app é legível.** Um APK pode ser extraído e lido;
não existe "esconder" chave no cliente. Portanto:

- **Nenhuma chave de serviço, credencial de banco ou segredo de integração
  vai para o app.** Se uma operação precisa de segredo, ela é um endpoint no
  backend, não uma chamada direta do cliente.
- **Senha nunca é persistida.** Nem em cache, nem em preferências, nem
  "temporariamente".
- **Token de sessão é a exceção necessária, e tem lugar certo.** Um app que
  mantém o usuário logado precisa guardar o token de renovação em algum
  lugar; o lugar é o **armazenamento criptografado do sistema** (keystore /
  keychain), nunca preferências em texto puro. O token de acesso, curto, pode
  viver em memória. E o backup automático do sistema deve excluir esse
  armazenamento, senão a credencial vaza junto com o backup.
- **Nada sensível em log.** Token, senha e corpo de requisição autenticada
  fora do console — log de app vai para o dispositivo e para ferramentas de
  crash.
- **Falha de autenticação não conta detalhe.** "Email ou senha incorreto",
  sem dizer qual dos dois; a distinção confirma quais contas existem.

## Desempenho e cache

Meça antes de otimizar, mas estes evitam retrabalho:

- **Chamadas independentes em paralelo**, não em sequência — `await`
  encadeado soma latências que poderiam correr juntas.
- **`select` em vez de `watch`** onde o widget depende de um campo só; caso
  contrário qualquer mudança no estado reconstrói a tela inteira.
- **`const` em widget que não muda** poupa reconstrução.
- **Lista longa é preguiçosa** (`ListView.builder`), nunca uma coluna com
  todos os itens montados de uma vez.

Cache vale quando o dado é caro de obter e muda pouco. Quando aplicar:

- **Mostre o que já tem enquanto revalida em segundo plano** — a tela abre
  na hora e se corrige sozinha, em vez de encarar um spinner a cada abertura.
- **Invalide na escrita.** Cache que não é invalidado quando o próprio app
  altera o dado é pior que não ter cache: mostra o valor antigo com
  confiança.
- **Não guarde dado autenticado de um usuário onde outro possa ler**, e
  limpe tudo no logout — senão o próximo login herda a tela do anterior.

## Contexto depois de `await`

Toda vez que usar `context` depois de um `await`, cheque antes:

```dart
await algo();
if (!mounted) return;          // em State
if (!context.mounted) return;  // em StatelessWidget
```

A tela pode ter sido fechada durante a espera. Sem a checagem, o app lança
num ponto que não aparece em teste e é difícil de reproduzir.

## Configuração

Dart compila a configuração no binário — não existe leitura de `.env` em
runtime sem pacote extra. Use `String.fromEnvironment` alimentado por
`--dart-define` ou `--dart-define-from-file`.

Duas consequências práticas: **hot reload e hot restart não releem esses
valores** (só um run novo aplica), e um valor ausente cai silenciosamente no
padrão. Vale registrar no console, em debug, qual configuração foi
carregada — do contrário a falha aparece como timeout inexplicável.

## Testes

Teste de widget que sobe **o app de verdade** com um adaptador HTTP falso
vale mais que teste de unidade com tudo simulado: exercita árvore, estado,
repositório e navegação juntos, que é onde os erros realmente moram.

O adaptador falso responde por rota e registra o que saiu, o que permite
verificar o corpo enviado — é assim que se pega um `snake_case` trocado.

Cubra especialmente:

- os **fluxos** (login, logout, sessão restaurada) ponta a ponta;
- as **costuras** de formato (leitura e escrita do JSON, campo nulo);
- os **caminhos de erro** (credencial errada, 422 com campo, falha de rede),
  que são os que ninguém testa à mão.

Cuidado com timers pendentes: um toast com auto-dismiss ou uma latência
simulada que não terminou fazem o teste falhar por motivo alheio ao que ele
verifica. Avance o relógio antes de encerrar.

## Passo a passo para uma tela nova

1. Modelo com `fromJson`/`toJson`, se houver dado novo
2. Função do endpoint em `data/services/`
3. Método na interface do repositório e nas implementações
4. Estado: campo, método de escrita com tratamento de falha, getters derivados
5. Tela em `features/<nome>/`, lendo o estado e usando os widgets compartilhados
6. Teste de widget do fluxo, e teste do mapeamento se houver JSON novo
7. `flutter analyze` e `flutter test` antes de encerrar
