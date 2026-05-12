# Requisitos Não Funcionais (RNF)

## Metadados
- Projeto: **L&J Doces**
- Produto: Aplicativo móvel de gestão e cardápio digital
- Versão do documento: `1.1.0`
- Última atualização: `2026-05-12`

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
| RNF-09 | Persistência de Sessão | Sessão do usuário deve ser mantida entre aberturas do app. | Token e dados básicos salvos localmente com recuperação automática da sessão. | Alta |
| RNF-10 | Latência de API | Chamadas de API devem ter controle de timeout para evitar bloqueio de interface. | Timeout de conexão e resposta em até 30 segundos. | Alta |
| RNF-11 | Tempo Real | Atualizações de estoque e pedidos devem ser recebidas sem recarga manual. | Comunicação por WebSocket com eventos de atualização em tempo quase real. | Alta |
| RNF-12 | Resiliência de Conexão | A camada de socket deve tolerar oscilações de rede e permitir reconexão. | Capacidade de reconectar e retomar inscrições de eventos. | Alta |
| RNF-13 | Escalabilidade de Listagem | Listas administrativas devem evitar carregamento excessivo em uma única requisição. | Paginação incremental de produtos para reduzir custo de renderização. | Média |
| RNF-14 | Interoperabilidade de Acesso | O app deve suportar login tradicional e social. | Compatibilidade com autenticação por Google e email/senha. | Média |
| RNF-15 | Navegação por Deep Link | O app deve aceitar deep link para fluxos críticos de recuperação de acesso. | Abertura direta da tela de reset pelo esquema `lejdoces://`. | Média |
| RNF-16 | Observabilidade de Integração | Eventos de requisição e falha devem ser rastreáveis em ambiente de desenvolvimento. | Logs de request/response/error para diagnóstico técnico. | Média |

## Critérios de Validação
- Cada RNF deve ser comprovado por teste, benchmark, checklist técnico ou evidência em PR.
- RNFs impactados por mudança de arquitetura devem ser revisados na mesma entrega.

## Histórico de Alterações
| Data | Versão | Alteração | Responsável |
|---|---|---|---|
| 2026-05-12 | 1.1.0 | Inclusão de RNF-09 a RNF-16 com foco em sessão, tempo real, resiliência, deep link e observabilidade. | Equipe L&J Doces |
| 2026-03-04 | 1.0.0 | Criação inicial do documento. | Equipe L&J Doces |
