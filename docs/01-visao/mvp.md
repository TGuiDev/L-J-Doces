# Documentacao de Casos de Uso - MVP L&J Doces

## Metadados
- Projeto: **L&J Doces**
- Tipo: Documento de escopo e casos de uso do MVP
- Versao do documento: `1.1.2`
- Ultima atualizacao: `2026-05-13`

## Objetivo

Consolidar os casos de uso essenciais do MVP, cobrindo jornada do cliente, operacao administrativa, autenticacao, pedidos, sincronizacao em tempo real e suporte por IA.

## Atores

- Cliente: consulta catalogo, favoritos, checkout e historico de pedidos.
- Administrador/Proprietario: opera catalogo, estoque, banners, pedidos e analytics.
- Sistema: executa validacoes, sincronizacao offline/online e regras de negocio.
- IA: apoia recomendacao de producao com base em historico.

## Matriz de Rastreabilidade do MVP

| Caso de Uso | Ator Principal | RF Relacionado | RN Relacionada | RNF Relacionada |
|---|---|---|---|---|
| UC01 - Consultar catalogo em tempo real | Cliente | RF-03 | RN-01 | RNF-02, RNF-03, RNF-11 |
| UC02 - Autenticar e recuperar acesso | Cliente | RF-11, RF-12 | RN-10, RN-16 | RNF-09, RNF-10, RNF-14, RNF-15 |
| UC03 - Gerenciar perfil e favoritos | Cliente | RF-13, RF-15 | RN-10 | RNF-09, RNF-10 |
| UC04 - Gerenciar catalogo e categorias | Administrador/Proprietario | RF-01, RF-02, RF-14 | RN-03, RN-09, RN-13 | RNF-07, RNF-13 |
| UC05 - Controlar estoque e alertas | Administrador/Proprietario | RF-04, RF-05 | RN-02, RN-05 | RNF-03, RNF-11 |
| UC06 - Registrar vendas e penduricalhos | Administrador/Proprietario | RF-06, RF-07 | RN-04, RN-05 | RNF-03, RNF-06 |
| UC07 - Checkout e pedidos | Cliente | RF-17, RF-18 | RN-10, RN-11, RN-14, RN-15 | RNF-10, RNF-11, RNF-12 |
| UC08 - Operar offline e sincronizar | Sistema | RF-09, RF-20 | RN-07, RN-15 | RNF-05, RNF-11, RNF-12 |
| UC09 - Administrar banners e destaques | Administrador/Proprietario | RF-16 | RN-09, RN-12 | RNF-06, RNF-10 |
| UC10 - Consultar resumo e analytics | Administrador/Proprietario | RF-08, RF-19 | RN-09 | RNF-10, RNF-16 |
| UC11 - Receber atualizacoes por websocket | Sistema | RF-20 | RN-15 | RNF-11, RNF-12 |
| UC12 - Receber sugestao de producao por IA | IA/Administrador | RF-10 | RN-08 | RNF-08, RNF-16 |

## Descricao dos Casos de Uso

### UC01 - Consultar catalogo em tempo real
- Objetivo: permitir visualizacao de produtos, preco e disponibilidade atualizada.
- Fluxo principal: abrir app, carregar catalogo, exibir disponibilidade e destaque.
- Regra critica: produto sem estoque deve ser marcado como indisponivel.
- No diagrama: aparece dentro da jornada do cliente e esta ligado diretamente ao ator Cliente, representando o primeiro contato do usuario com a plataforma para consultar produtos disponiveis em tempo real.

```plantuml
@startuml
left to right direction
actor Cliente
rectangle "UC01 - Consultar catalogo em tempo real" {
  usecase "Abrir app" as Abrir
  usecase "Carregar catalogo" as Catalogo
  usecase "Exibir preco e disponibilidade" as Disponibilidade
  usecase "Marcar produto sem estoque\ncomo indisponivel" as SemEstoque
}
Cliente --> Abrir
Abrir --> Catalogo
Catalogo --> Disponibilidade
Disponibilidade .> SemEstoque : <<include>>
@enduml
```

### UC02 - Autenticar e recuperar acesso
- Objetivo: permitir cadastro, login por email/senha, login Google e recuperacao de acesso.
- Fluxo principal: autenticar, manter sessao e, quando necessario, iniciar fluxo de reset.
- Regra critica: deep link de reset deve abrir tela correta no app.
- No diagrama: aparece dentro da jornada do cliente e esta ligado diretamente ao ator Cliente, indicando que a autenticacao e a recuperacao de acesso fazem parte da entrada segura do usuario no aplicativo.

```plantuml
@startuml
left to right direction
actor Cliente
rectangle "UC02 - Autenticar e recuperar acesso" {
  usecase "Cadastrar conta" as Cadastro
  usecase "Entrar com email/senha" as LoginEmail
  usecase "Entrar com Google" as LoginGoogle
  usecase "Recuperar acesso" as Reset
  usecase "Abrir tela pelo deep link" as DeepLink
}
Cliente --> Cadastro
Cliente --> LoginEmail
Cliente --> LoginGoogle
Cliente --> Reset
Reset .> DeepLink : <<include>>
@enduml
```

### UC03 - Gerenciar perfil e favoritos
- Objetivo: permitir atualizacao de perfil e gestao de produtos favoritos.
- Fluxo principal: usuario autenticado acessa perfil, salva alteracoes e marca/desmarca favoritos.
- Regra critica: operacoes exigem sessao valida.
- No diagrama: aparece dentro da jornada do cliente, ligado ao ator Cliente, e inclui a regra compartilhada Validar Sessao porque somente usuarios autenticados podem alterar perfil ou favoritos.

```plantuml
@startuml
left to right direction
actor Cliente
rectangle "UC03 - Gerenciar perfil e favoritos" {
  usecase "Validar sessao" as Sessao
  usecase "Atualizar perfil" as Perfil
  usecase "Marcar favorito" as Marcar
  usecase "Desmarcar favorito" as Desmarcar
}
Cliente --> Perfil
Cliente --> Marcar
Cliente --> Desmarcar
Perfil .> Sessao : <<include>>
Marcar .> Sessao : <<include>>
Desmarcar .> Sessao : <<include>>
@enduml
```

### UC04 - Gerenciar catalogo e categorias
- Objetivo: manter produtos, categorias e subcategorias organizados para exibicao no app.
- Fluxo principal: criar/editar/inativar produto, manter categorias e ordenacao.
- Regra critica: apenas perfil autorizado pode operar funcoes administrativas.
- No diagrama: aparece dentro da jornada administrativa, ligado ao ator Administrador, e inclui Validar Sessao para reforcar que a manutencao do catalogo depende de acesso administrativo autenticado.

```plantuml
@startuml
left to right direction
actor Administrador
rectangle "UC04 - Gerenciar catalogo e categorias" {
  usecase "Validar sessao" as Sessao
  usecase "Criar produto" as Criar
  usecase "Editar produto" as Editar
  usecase "Inativar produto" as Inativar
  usecase "Manter categorias\ne ordenacao" as Categorias
}
Administrador --> Criar
Administrador --> Editar
Administrador --> Inativar
Administrador --> Categorias
Criar .> Sessao : <<include>>
Editar .> Sessao : <<include>>
Inativar .> Sessao : <<include>>
Categorias .> Sessao : <<include>>
@enduml
```

### UC05 - Controlar estoque e alertas
- Objetivo: registrar entradas/saidas e detectar nivel critico de itens.
- Fluxo principal: atualizar quantidade, recalcular saldo e emitir alerta de minimo.
- Regra critica: venda confirmada deve baixar estoque automaticamente.
- No diagrama: aparece dentro da jornada administrativa, ligado ao ator Administrador, e inclui Validar Estoque para mostrar que toda movimentacao precisa manter saldos e disponibilidade consistentes.

```plantuml
@startuml
left to right direction
actor Administrador
rectangle "UC05 - Controlar estoque e alertas" {
  usecase "Registrar entrada" as Entrada
  usecase "Registrar saida" as Saida
  usecase "Recalcular saldo" as Saldo
  usecase "Validar estoque" as Estoque
  usecase "Emitir alerta de minimo" as Alerta
}
Administrador --> Entrada
Administrador --> Saida
Entrada .> Saldo : <<include>>
Saida .> Saldo : <<include>>
Saldo .> Estoque : <<include>>
Estoque .> Alerta : <<extend>>
@enduml
```

### UC06 - Registrar vendas e penduricalhos
- Objetivo: registrar venda imediata e venda a prazo com rastreabilidade.
- Fluxo principal: selecionar itens, validar disponibilidade, finalizar e registrar forma de pagamento.
- Regra critica: penduricalho exige identificacao do cliente.
- No diagrama: aparece dentro da jornada administrativa e esta ligado ao ator Administrador, representando a venda feita pela operacao interna, inclusive casos de venda a prazo registrados como penduricalhos.

```plantuml
@startuml
left to right direction
actor Administrador
rectangle "UC06 - Registrar vendas e penduricalhos" {
  usecase "Selecionar itens" as Itens
  usecase "Validar disponibilidade" as Disponibilidade
  usecase "Registrar forma de pagamento" as Pagamento
  usecase "Identificar cliente" as Cliente
  usecase "Finalizar venda" as Finalizar
}
Administrador --> Itens
Itens --> Disponibilidade
Disponibilidade --> Pagamento
Pagamento --> Finalizar
Pagamento .> Cliente : <<extend>>\npenduricalho
@enduml
```

### UC07 - Checkout e pedidos
- Objetivo: permitir que o cliente conclua pedido e acompanhe status.
- Fluxo principal: montar carrinho, validar quantidade, confirmar checkout e consultar historico.
- Regra critica: quantidade do carrinho nao pode exceder estoque disponivel.
- No diagrama: aparece dentro da jornada do cliente, ligado ao ator Cliente, e inclui Validar Sessao e Validar Estoque para indicar que o pedido depende de usuario autenticado e disponibilidade dos produtos.

```plantuml
@startuml
left to right direction
actor Cliente
rectangle "UC07 - Checkout e pedidos" {
  usecase "Validar sessao" as Sessao
  usecase "Montar carrinho" as Carrinho
  usecase "Validar quantidade" as Quantidade
  usecase "Validar estoque" as Estoque
  usecase "Confirmar checkout" as Checkout
  usecase "Consultar historico" as Historico
}
Cliente --> Carrinho
Cliente --> Historico
Carrinho --> Quantidade
Quantidade .> Estoque : <<include>>
Checkout .> Sessao : <<include>>
Quantidade --> Checkout
Historico .> Sessao : <<include>>
@enduml
```

### UC08 - Operar offline e sincronizar
- Objetivo: manter operacao basica sem internet com reconciliacao posterior.
- Fluxo principal: gravar localmente, detectar reconexao e sincronizar em ordem cronologica.
- Regra critica: conflitos devem ser resolvidos com consistencia de dados.
- No diagrama: aparece em capacidades transversais e esta ligado ao ator Sistema, pois a sincronizacao offline/online e uma responsabilidade automatizada da plataforma; tambem inclui Sincronizar Eventos.

```plantuml
@startuml
left to right direction
actor Sistema
rectangle "UC08 - Operar offline e sincronizar" {
  usecase "Gravar dados localmente" as Local
  usecase "Detectar reconexao" as Reconexao
  usecase "Sincronizar eventos" as Sync
  usecase "Resolver conflitos" as Conflitos
  usecase "Confirmar consistencia" as Consistencia
}
Sistema --> Local
Local --> Reconexao
Reconexao --> Sync
Sync .> Conflitos : <<include>>
Conflitos --> Consistencia
@enduml
```

### UC09 - Administrar banners e destaques
- Objetivo: publicar campanhas visuais com controle de status ativo.
- Fluxo principal: cadastrar banner, definir ativo/inativo e refletir no app cliente.
- Regra critica: banner inativo nao deve aparecer como destaque principal.
- No diagrama: aparece dentro da jornada administrativa, ligado ao ator Administrador, e inclui Validar Sessao para garantir que apenas usuarios autorizados alterem destaques exibidos aos clientes.

```plantuml
@startuml
left to right direction
actor Administrador
rectangle "UC09 - Administrar banners e destaques" {
  usecase "Validar sessao" as Sessao
  usecase "Cadastrar banner" as Cadastrar
  usecase "Definir ativo/inativo" as Status
  usecase "Publicar destaque" as Publicar
  usecase "Ocultar banner inativo" as Ocultar
}
Administrador --> Cadastrar
Cadastrar .> Sessao : <<include>>
Cadastrar --> Status
Status --> Publicar
Status .> Ocultar : <<extend>>
@enduml
```

### UC10 - Consultar resumo e analytics
- Objetivo: apoiar decisao operacional com indicadores por periodo.
- Fluxo principal: selecionar periodo, carregar metricas e analisar desempenho.
- Regra critica: acesso restrito ao perfil administrativo.
- No diagrama: aparece dentro da jornada administrativa, ligado ao ator Administrador, inclui Validar Sessao e estende UC12 quando a analise pode acionar sugestoes de producao por IA.

```plantuml
@startuml
left to right direction
actor Administrador
rectangle "UC10 - Consultar resumo e analytics" {
  usecase "Validar sessao" as Sessao
  usecase "Selecionar periodo" as Periodo
  usecase "Carregar metricas" as Metricas
  usecase "Analisar desempenho" as Analise
  usecase "Receber sugestao\nde producao por IA" as IA
}
Administrador --> Periodo
Periodo .> Sessao : <<include>>
Periodo --> Metricas
Metricas --> Analise
Analise .> IA : <<extend>>
@enduml
```

### UC11 - Receber atualizacoes por websocket
- Objetivo: refletir alteracoes de estoque/pedidos sem recarga manual.
- Fluxo principal: conectar socket, inscrever eventos e atualizar estado da interface.
- Regra critica: reconexao deve restaurar assinaturas de eventos.
- No diagrama: aparece em capacidades transversais e esta ligado ao ator Sistema, indicando que as atualizacoes em tempo real sao tratadas automaticamente; tambem inclui Sincronizar Eventos.

```plantuml
@startuml
left to right direction
actor Sistema
rectangle "UC11 - Receber atualizacoes por websocket" {
  usecase "Conectar socket" as Socket
  usecase "Inscrever eventos" as Eventos
  usecase "Sincronizar eventos" as Sync
  usecase "Atualizar interface" as Interface
  usecase "Restaurar assinaturas\napos reconexao" as Restaurar
}
Sistema --> Socket
Socket --> Eventos
Eventos .> Sync : <<include>>
Sync --> Interface
Socket .> Restaurar : <<extend>>
@enduml
```

### UC12 - Receber sugestao de producao por IA
- Objetivo: sugerir volume de producao diario baseado em historico.
- Fluxo principal: consolidar dados, processar analise e exibir recomendacao.
- Regra critica: sugestao nao pode executar acao automatica sem confirmacao humana.
- No diagrama: aparece em capacidades transversais, ligado aos atores Administrador e IA, e pode ser acionado como extensao de UC10 para transformar indicadores historicos em recomendacao de producao.

```plantuml
@startuml
left to right direction
actor Administrador
actor IA
rectangle "UC12 - Receber sugestao de producao por IA" {
  usecase "Consolidar historico" as Historico
  usecase "Processar analise" as Analise
  usecase "Exibir recomendacao" as Recomendacao
  usecase "Confirmar decisao humana" as Confirmacao
}
Administrador --> Historico
IA --> Analise
Historico --> Analise
Analise --> Recomendacao
Recomendacao .> Confirmacao : <<include>>
@enduml
```

## Responsabilidades por Area

- Guilherme Portilho: lideranca tecnica e desenvolvimento full stack (frontend e backend).
- Vitoria Karolina: qualidade e validacao, com apoio na analise de requisitos.
- Gabrielly Cristina: apoio em documentacao e operacao.
- Leonardo Delfino Vieira: apoio tecnico e integracao.

## Relacao com a Documentacao

- Requisitos funcionais: [RF.md](../02-requisitos/RF.md)
- Regras de negocio: [RN.md](../02-requisitos/RN.md)
- Requisitos nao funcionais: [RNF.md](../02-requisitos/RNF.md)
- Organograma de responsabilidades: [organograma.md](../03-processo/organograma.md)
- Visao geral: [visao-geral.md](./visao-geral.md)

## Historico de Alteracoes

| Data | Versao | Alteracao | Responsavel |
|---|---|---|---|
| 2026-05-13 | 1.1.2 | Inclusao de um diagrama PlantUML individual abaixo de cada caso de uso do MVP. | Equipe L&J Doces |
| 2026-05-13 | 1.1.1 | Inclusao da explicacao de cada caso de uso conforme sua representacao no diagrama de casos de uso do MVP. | Equipe L&J Doces |
| 2026-05-12 | 1.1.0 | Atualizacao da matriz do MVP para cobrir RF-11 a RF-21 e alinhamento de responsabilidades com organograma 1.1.1. | Equipe L&J Doces |
| 2026-03-04 | 1.0.0 | Criacao inicial do documento de casos de uso do MVP. | Equipe L&J Doces |
