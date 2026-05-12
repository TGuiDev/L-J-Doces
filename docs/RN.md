# Regras de Negócio (RN)

## Metadados
- Projeto: **L&J Doces**
- Produto: Aplicativo móvel de gestão e cardápio digital
- Versão do documento: `1.1.0`
- Última atualização: `2026-05-12`

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
| RN-09 | Acesso administrativo restrito | Operações de administração (produtos, categorias, banners, pedidos e analytics) exigem perfil autorizado. | RF-14, RF-16, RF-18, RF-19 |
| RN-10 | Operação autenticada obrigatória | Perfil, favoritos e pedidos só podem ser manipulados por usuário autenticado com sessão válida. | RF-13, RF-15, RF-17, RF-18 |
| RN-11 | Limite de quantidade no carrinho | O carrinho não pode aceitar quantidade acima do estoque disponível do produto. | RF-17 |
| RN-12 | Banner inativo não deve ser destaque | Apenas banners ativos podem ser exibidos como destaque principal ao cliente. | RF-16 |
| RN-13 | Ordenação persistente de catálogo | Alterações de ordem de categorias/subcategorias devem ser persistidas e reaplicadas nas próximas consultas. | RF-14 |
| RN-14 | Integridade do pedido | Todo pedido deve conter itens válidos, quantidade positiva e total coerente com os itens informados. | RF-17, RF-18 |
| RN-15 | Status de pedido sincronizado | Mudanças de status do pedido devem ser propagadas em tempo real para as telas inscritas. | RF-18, RF-20 |
| RN-16 | Deep link direcionado para reset | Links do esquema `lejdoces://reset-password` devem abrir a tela de redefinição de senha no app. | RF-21, RF-12 |

## Exceções e Tratamento
- Em caso de conflito de sincronização, deve prevalecer a versão mais recente validada pelo usuário responsável.
- Exclusões de produto com histórico de vendas devem ser bloqueadas ou convertidas em inativação lógica.

## Histórico de Alterações
| Data | Versão | Alteração | Responsável |
|---|---|---|---|
| 2026-05-12 | 1.1.0 | Inclusão de RN-09 a RN-16 para cobrir autenticação, admin, pedidos, banners e tempo real. | Equipe L&J Doces |
| 2026-03-04 | 1.0.0 | Criação inicial do documento. | Equipe L&J Doces |
