# 🏗️ Arquitetura da Integração de IA

## Fluxo de Requisição

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENTE (Mobile/Web)                     │
│  Faz requisição GET para /analytics/operational-summary     │
└─────────────────┬───────────────────────────────────────────┘
                  │ Com Token JWT
                  ▼
┌─────────────────────────────────────────────────────────────┐
│               NEST.JS API (backend)                         │
│  AnalyticsController → valida JWT                           │
└─────────────────┬───────────────────────────────────────────┘
                  │
     ┌────────────┼────────────┬──────────────┐
     ▼            ▼            ▼              ▼
┌──────────┐  ┌──────────┐  ┌────────────┐  ┌──────────┐
│ Sales    │  │ Products │  │Profitability│ │ Payments │
│Analytics │  │ Analytics│  │  Analytics  │ │Analytics │
└──────────┘  └──────────┘  └────────────┘  └──────────┘
     │            │            │              │
     └────────────┼────────────┬──────────────┘
                  ▼
        ┌──────────────────────┐
        │  AnalyticsService    │
        │  - getSalesData()    │
        │  - getProductData()  │
        │  - getProfitData()   │
        │  - getPaymentData()  │
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │   SUPABASE (PostgreSQL) Database │
        │  ├─ orders           │
        │  ├─ order_items      │
        │  ├─ products         │
        │  ├─ payments         │
        │  └─ categories       │
        └──────────┬───────────┘
                   │ Dados Agregados
                   ▼
        ┌──────────────────────┐
        │   AIService          │
        │ buildPrompt()        │
        │ generateSummary()    │
        └──────────┬───────────┘
                   │ Com dados em JSON
                   ▼
        ┌──────────────────────┐
        │   OpenAI API         │
        │   (GPT-4)            │
        └──────────┬───────────┘
                   │ Análise com IA
                   ▼
        ┌──────────────────────┐
        │  Resumo Executivo    │
        │  em Texto (markdown) │
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  Response JSON       │
        │  {                   │
        │    success: true,    │
        │    summary: "...",   │
        │    rawData: {...}    │
        │  }                   │
        └──────────┬───────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│              CLIENTE recebe Resumo                          │
│         Exibe para administrador                            │
└─────────────────────────────────────────────────────────────┘
```

## Estrutura de Diretórios

```
backend/
├── src/
│   ├── analytics/
│   │   ├── analytics.module.ts      ← Módulo principal
│   │   ├── analytics.service.ts     ← Lógica de dados (Supabase)
│   │   ├── analytics.controller.ts  ← Endpoints HTTP
│   │   ├── ai.service.ts            ← Integração OpenAI
│   │   ├── analytics.types.ts       ← Tipos TypeScript
│   │   ├── EXAMPLES.md              ← Exemplos de código
│   │   └── ARCHITECTURE.md          ← Este arquivo
│   │
│   ├── app.module.ts                ← Importa AnalyticsModule
│   ├── main.ts                      ← Entry point
│   └── ... (outros módulos)
│
├── QUICK_START.md                   ← Guia rápido (5 min)
├── ANALYTICS_SETUP.md               ← Setup completo
├── .env.example                     ← Variáveis de exemplo
├── package.json                     ← Dependências (openai adicionado)
└── ... (outros arquivos)
```

## Componentes Principais

### 1. **AnalyticsController**
- Recebe requisições HTTP
- Valida JWT (autenticação)
- Chama serviços de análise
- Retorna JSON

**Endpoints:**
- `GET /analytics/operational-summary` - Resumo com IA ⭐
- `GET /analytics/sales` - Dados de vendas
- `GET /analytics/products` - Produtos e estoque
- `GET /analytics/profitability` - Lucratividade
- `GET /analytics/payments` - Status de pagamentos
- `GET /analytics/temporal` - Picos de venda

### 2. **AnalyticsService**
Extrai dados do Supabase:

```typescript
- getSalesAnalytics()          → totalOrders, revenue, ticket médio
- getProductAnalytics()        → top 10 produtos, estoque baixo
- getProfitabilityAnalysis()   → lucro, margem, produtos com prejuízo
- getPaymentAnalytics()        → status, taxa de conversão
- getTemporalAnalytics()       → vendas por hora/dia, picos
```

Queries SQL no Supabase:
- Total de vendas por período
- Produtos mais vendidos (com custo)
- Estoque crítico
- Taxa de conversão de pagamentos
- Padrões temporais

### 3. **AiService**
Comunica com OpenAI:

```typescript
generateOperationalSummary(data)
├── Constrói prompt com dados
├── Envia para OpenAI API (GPT-4)
├── Aguarda resposta
└── Retorna resumo em markdown
```

**Modelo:** GPT-4 (pode alterar para GPT-3.5 ou outro)

**Análises Automáticas:**
- Desempenho de vendas
- Análise de lucratividade
- Produtos top performers
- Análise temporal
- Estoque e recomendações
- Status de pagamentos
- Recomendações estratégicas

### 4. **AnalyticsModule**
Integra tudo:

```typescript
@Module({
  imports: [SupabaseModule],
  providers: [AnalyticsService, AiService],
  controllers: [AnalyticsController],
})
```

## Fluxo de Dados

### Exemplo: Requisição de Resumo Operacional

```
1. Cliente faz GET /analytics/operational-summary?startDate=2024-01-01&endDate=2024-01-31
   ↓
2. Controller recebe requisição
   - Valida JWT (usuário autenticado)
   - Converte datas para objetos Date
   ↓
3. AnalyticsService.getSalesAnalytics(start, end)
   - Query Supabase: SELECT * FROM orders WHERE created_at BETWEEN start AND end
   - Calcula: total, receita, ticket médio
   - Retorna: { totalOrders: 45, totalRevenue: 2250.50, ... }
   ↓
4. AnalyticsService.getProductAnalytics(start, end)
   - Query complexa com JOINs (orders → order_items → products)
   - Calcula: top 10 produtos, estoque < 10
   - Retorna: { topProducts: [...], lowStockProducts: [...] }
   ↓
5. AnalyticsService.getProfitabilityAnalysis(start, end)
   - Busca unit_price e cost_price
   - Calcula: lucro = revenue - cost
   - Identifica produtos com prejuízo
   - Retorna: { profit: 1150.25, marginPercentage: "51.13", ... }
   ↓
6. AnalyticsService.getPaymentAnalytics(start, end)
   - Query payments com agregações
   - Calcula: taxa de conversão, métodos mais usados
   - Retorna: { completedPayments: 40, paymentRate: "88.89", ... }
   ↓
7. AnalyticsService.getTemporalAnalytics(start, end)
   - Agrupa por dia da semana e hora
   - Identifica picos de venda
   - Retorna: { salesByDayOfWeek: {...}, peakDay: ["Sexta-feira", 450], ... }
   ↓
8. Dados são consolidados em AnalysisData
   ↓
9. AiService.generateOperationalSummary(data)
   - Constrói prompt detalhado com os dados
   - Chama OpenAI API
   - OpenAI analisa e gera resumo em português
   ↓
10. Resumo é retornado ao cliente em JSON:
    {
      success: true,
      summary: "## RESUMO EXECUTIVO\n\n### 📈 Desempenho...",
      rawData: { sales, products, profitability, ... }
    }
    ↓
11. Cliente renderiza summary para o administrador
```

## Performance e Otimizações

### Pontos de Atenção

1. **Queries ao Supabase**
   - Total: ~5-10 queries por requisição
   - Tempo esperado: 2-5 segundos
   - Índices criados em: user_id, status, created_at

2. **Chamada à OpenAI**
   - Tempo: ~10-30 segundos (depende de carga)
   - Custo: ~$0.09 por análise (GPT-4)
   - Rate limit: 3500 RPM (requisições/min)

3. **Melhorias Possíveis**
   - Cache de resultados (Redis)
   - Pré-processar dados agregados
   - Usar GPT-3.5 ao invés de GPT-4
   - Agendamento de análises em horários off-peak

## Segurança

```
Camadas de Proteção:
├── JWT Authentication (JwtAuthGuard em todos endpoints)
├── Validação de Query Parameters (startDate, endDate)
├── SUPABASE_SERVICE_ROLE_KEY (restrito ao backend)
├── OPENAI_API_KEY (nunca exposto ao cliente)
├── Variáveis de ambiente (.env não commitado)
└── HTTPS em produção
```

## Limitações Atuais e Melhorias Futuras

### Limitações
- Sem verificação de permissões (qualquer autenticado acessa)
- Sem cache (nova requisição = nova análise)
- Sem agendamento automático
- Sem histórico de análises

### Melhorias Possíveis
- ✅ Adicionar verificação de role (apenas admins)
- ✅ Implementar cache com Redis
- ✅ Agendar análises com node-cron
- ✅ Salvar histórico em banco de dados
- ✅ Alertas quando margens caem
- ✅ Comparação período a período
- ✅ Exportação para PDF/Excel
- ✅ Dashboard de visualização

## Dependências

```json
{
  "openai": "^4.26.0",           // Cliente OpenAI
  "@nestjs/common": "^10.3.0",   // Framework NestJS
  "@supabase/supabase-js": "^2.39.3"  // Cliente Supabase
}
```

## Variáveis de Ambiente Necessárias

```env
OPENAI_API_KEY=sk-proj-xxx      # Chave OpenAI
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=xxx
JWT_SECRET=xxx
```

---

**Diagrama criado para: Projeto E-commerce com NestJS + Supabase + OpenAI**
