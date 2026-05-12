# Documentação de Requisitos

Este diretório centraliza os documentos de requisitos do projeto **L&J Doces**.

## Estrutura
- `visao-geral.md`: mapa macro do sistema, cobrindo API, app e integrações.
- `mvp.md`: casos de uso e rastreabilidade do escopo mínimo viável.
- `organograma.md`: responsabilidades, apoios e vínculos por integrante.
- `RF.md`: Requisitos Funcionais.
- `RNF.md`: Requisitos Não Funcionais.
- `RN.md`: Regras de Negócio.
- `../README.md`: porta de entrada do projeto.

## Como usar

- Comece por `visao-geral.md` para entender o sistema como um todo.
- Consulte `mvp.md` para os fluxos principais do produto.
- Use `RF.md`, `RN.md` e `RNF.md` para detalhar o que o sistema deve fazer e como deve se comportar.
- Use `organograma.md` para saber quem é responsável por cada frente.

## Convenções
- IDs seguem o padrão:
  - `RF-XX` para requisitos funcionais.
  - `RNF-XX` para requisitos não funcionais.
  - `RN-XX` para regras de negócio.
- Sempre que um requisito for alterado:
  1. Atualizar o conteúdo no documento correspondente.
  2. Registrar data da alteração no histórico.
  3. Referenciar a mudança na Pull Request.

## Rastreabilidade
- Requisitos e regras devem ser citados em PRs, issues e commits quando aplicável.
- Exemplo de referência: `Implementa RF-03 e RN-02`.
