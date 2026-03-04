# Requisitos Funcionais (RF)

## Metadados
- Projeto: **L&J Doces**
- Produto: Aplicativo móvel de gestão e cardápio digital
- Versão do documento: `1.0.0`
- Última atualização: `2026-03-04`

## Objetivo
Descrever as funcionalidades obrigatórias do sistema para atender às necessidades operacionais da L&J Doces e da experiência dos clientes.

## Lista de Requisitos

| ID | Título | Descrição | Prioridade | Status |
|---|---|---|---|---|
| RF-01 | Cadastro de Produtos | O sistema deve permitir cadastrar produtos com nome, categoria, preço, custo e status de disponibilidade. | Alta | Proposto |
| RF-02 | Edição e Exclusão de Produtos | O sistema deve permitir editar e excluir produtos com controle de confirmação para evitar remoções acidentais. | Alta | Proposto |
| RF-03 | Catálogo Digital em Tempo Real | O sistema deve exibir cardápio atualizado com disponibilidade de itens para o cliente. | Alta | Proposto |
| RF-04 | Controle de Estoque | O sistema deve registrar entrada e saída de insumos e produtos finalizados. | Alta | Proposto |
| RF-05 | Alertas de Estoque Crítico | O sistema deve emitir alertas quando itens atingirem limite mínimo configurado. | Alta | Proposto |
| RF-06 | Registro de Vendas | O sistema deve registrar vendas com data, itens, valor total, forma de pagamento e responsável. | Alta | Proposto |
| RF-07 | Registro de Vendas a Prazo (Penduricalhos) | O sistema deve permitir registrar vendas a prazo com identificação do cliente e status de quitação. | Média | Proposto |
| RF-08 | Cálculo de Lucro | O sistema deve calcular lucro por produto e por período com base em custo e receita. | Média | Proposto |
| RF-09 | Modo Offline com Sincronização | O sistema deve permitir registro de operações sem internet e sincronizar dados quando a conexão retornar. | Alta | Proposto |
| RF-10 | Sugestão de Produção (IA) | O sistema deve sugerir volume de produção diária com base no histórico de vendas. | Média | Proposto |

## Critérios Gerais de Aceite
- Cada RF deve possuir evidência de implementação (tela, endpoint, teste ou demonstração).
- Cada RF deve estar vinculado a pelo menos uma issue ou tarefa de backlog.
- PRs devem citar explicitamente os IDs de RF impactados.

## Histórico de Alterações
| Data | Versão | Alteração | Responsável |
|---|---|---|---|
| 2026-03-04 | 1.0.0 | Criação inicial do documento. | Equipe L&J Doces |
