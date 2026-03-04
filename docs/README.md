# Documentação de Requisitos

Este diretório centraliza os documentos de requisitos do projeto **L&J Doces**.

## Estrutura
- `RF.md`: Requisitos Funcionais.
- `RNF.md`: Requisitos Não Funcionais.
- `RN.md`: Regras de Negócio.

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
