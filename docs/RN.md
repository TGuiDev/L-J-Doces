# Regras de Negócio (RN)

## Metadados
- Projeto: **L&J Doces**
- Produto: Aplicativo móvel de gestão e cardápio digital
- Versão do documento: `1.0.0`
- Última atualização: `2026-03-04`

## Objetivo
Registrar políticas operacionais que orientam como os processos da L&J Doces devem funcionar no sistema.

## Lista de Regras

| ID | Regra | Descrição | RF Relacionado |
|---|---|---|---|
| RN-01 | Produto sem estoque não disponível | Itens com estoque igual a zero devem aparecer como indisponíveis no cardápio. | RF-03, RF-04 |
| RN-02 | Limite mínimo por item | Todo item de estoque deve ter um limite mínimo configurável para alerta preventivo. | RF-05 |
| RN-03 | Venda exige produto ativo | Apenas produtos ativos e com preço válido podem ser vendidos. | RF-01, RF-06 |
| RN-04 | Registro obrigatório de penduricalho | Toda venda a prazo deve possuir identificação do cliente e data prevista de pagamento. | RF-07 |
| RN-05 | Atualização de saldo após venda | Ao finalizar uma venda, o sistema deve baixar automaticamente o saldo do estoque correspondente. | RF-04, RF-06 |
| RN-06 | Lucro calculado por custo vigente | O cálculo de lucro deve usar o custo vigente no momento da venda para preservar histórico. | RF-08 |
| RN-07 | Sincronização com prioridade cronológica | No modo offline, registros devem ser sincronizados na ordem de criação para evitar inconsistência. | RF-09 |
| RN-08 | Sugestão de produção não automática | A sugestão da IA é recomendação e não deve alterar produção sem confirmação do usuário. | RF-10 |

## Exceções e Tratamento
- Em caso de conflito de sincronização, deve prevalecer a versão mais recente validada pelo usuário responsável.
- Exclusões de produto com histórico de vendas devem ser bloqueadas ou convertidas em inativação lógica.

## Histórico de Alterações
| Data | Versão | Alteração | Responsável |
|---|---|---|---|
| 2026-03-04 | 1.0.0 | Criação inicial do documento. | Equipe L&J Doces |
