# Documentação do Projeto

Este diretório centraliza a documentação funcional, técnica e de processo do projeto **L&J Doces**.

## Estrutura

- `01-visao/`
  - `visao-geral.md`: mapa macro do sistema (API, app e integrações).
  - `mvp.md`: escopo mínimo viável, casos de uso e rastreabilidade.
- `02-requisitos/`
  - `RF.md`: requisitos funcionais.
  - `RN.md`: regras de negócio.
  - `RNF.md`: requisitos não funcionais.
- `03-processo/`
  - `organograma.md`: papéis, responsabilidades e apoios da equipe.
- `04-guias/`
  - guias operacionais e de setup do projeto.
- `05-arquitetura/diagramas/`
  - `README.md`: guia de organização e convenções dos diagramas.
  - `puml/`: arquivos PlantUML (`.puml`) para arquitetura e fluxos.

## Como usar

- Comece por `01-visao/visao-geral.md`.
- Depois leia `01-visao/mvp.md` para entender os fluxos prioritários.
- Use `02-requisitos/` como base para implementação e validação.
- Consulte `03-processo/organograma.md` para responsabilidades.
- Use `04-guias/` em setup, operação e onboarding.
- Use `05-arquitetura/diagramas/puml/` para manter os diagramas versionados junto do código.

## Convenções

- IDs de requisitos:
  - `RF-XX` para requisitos funcionais.
  - `RNF-XX` para requisitos não funcionais.
  - `RN-XX` para regras de negócio.
- Sempre que um requisito for alterado:
  1. Atualizar o conteúdo no documento correspondente.
  2. Registrar data da alteração no histórico do arquivo.
  3. Referenciar a mudança na Pull Request.

## Rastreabilidade

- Requisitos e regras devem ser citados em PRs, issues e commits quando aplicável.
- Exemplo de referência: `Implementa RF-03 e RN-02`.
