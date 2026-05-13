# Diagramas de Arquitetura

Este diretório concentra os diagramas técnicos versionados no repositório.

## Estrutura

- `puml/`: fontes PlantUML (`.puml`).

## Diagramas Disponiveis

- `contexto-sistema.puml`: visão de contexto do sistema (C1), atores e dependências externas.
- `containers-aplicacao.puml`: visão de containers e integrações técnicas (C2).
- `fluxo-pedido-sequence.puml`: sequência detalhada de criação e atualização de pedido.
- `implantacao-ambientes.puml`: visão de implantação para desenvolvimento e produção.
- `casos-uso-mvp.puml`: diagrama de casos de uso consolidado do MVP (UC01 a UC12).
- `dominio-modelo.puml`: diagrama de domínio com entidades, relacionamentos e enums principais.
- `atividade-checkout-pedido.puml`: diagrama de atividade do checkout ao encerramento do pedido.

## Convenções

- Nome do arquivo em minúsculas e com hífen.
- Um diagrama por arquivo.
- Título claro no topo (`title ...`).
- Sempre atualizar o diagrama quando alterar fluxos críticos.

## Como visualizar

Você pode usar qualquer renderizador PlantUML, por exemplo:

```bash
plantuml docs/05-arquitetura/diagramas/puml/*.puml
```

Também é possível usar extensões do VS Code para preview de `.puml`.
