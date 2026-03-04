# Requisitos Não Funcionais (RNF)

## Metadados
- Projeto: **L&J Doces**
- Produto: Aplicativo móvel de gestão e cardápio digital
- Versão do documento: `1.0.0`
- Última atualização: `2026-03-04`

## Objetivo
Definir critérios de qualidade, desempenho, segurança e restrições técnicas que o sistema deve atender.

## Lista de Requisitos

| ID | Categoria | Descrição | Meta / Critério | Prioridade |
|---|---|---|---|---|
| RNF-01 | Plataforma | O aplicativo deve ser desenvolvido em Flutter com Dart. | Build estável para Android (e iOS quando aplicável). | Alta |
| RNF-02 | Responsividade | A interface deve se adaptar a diferentes tamanhos de tela de dispositivos móveis. | Layout sem quebra em resoluções comuns de smartphones. | Alta |
| RNF-03 | Desempenho | Atualizações de estoque e disponibilidade devem refletir rapidamente. | Atualização visível em até 2 segundos em condição normal de rede. | Alta |
| RNF-04 | Usabilidade | O fluxo principal (consultar cardápio e registrar venda) deve ser simples. | Até 3 toques para ações frequentes. | Média |
| RNF-05 | Confiabilidade Offline | O sistema deve manter operação básica sem internet. | Nenhuma perda de dados locais durante indisponibilidade de rede. | Alta |
| RNF-06 | Segurança | Dados de vendas e clientes devem ser protegidos. | Armazenamento local com boas práticas e comunicação segura (HTTPS). | Alta |
| RNF-07 | Manutenibilidade | Código deve seguir padrões consistentes para facilitar evolução. | Lint sem erros críticos e organização por módulos. | Média |
| RNF-08 | Testabilidade | Regras críticas devem ser testáveis de forma automatizada. | Cobertura mínima para camadas de domínio prioritárias. | Média |

## Critérios de Validação
- Cada RNF deve ser comprovado por teste, benchmark, checklist técnico ou evidência em PR.
- RNFs impactados por mudança de arquitetura devem ser revisados na mesma entrega.

## Histórico de Alterações
| Data | Versão | Alteração | Responsável |
|---|---|---|---|
| 2026-03-04 | 1.0.0 | Criação inicial do documento. | Equipe L&J Doces |
