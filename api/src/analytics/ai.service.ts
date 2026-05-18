import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import OpenAI from 'openai';

interface Product {
  id?: string;
  name?: string;
  productName?: string;
  quantity?: number;
  revenue?: number;
  profit?: number;
  stock?: number;
  stock_quantity?: number;
  currentStock?: number;
  price?: number;
  unitPrice?: number;
  cost_price?: number;
  costPrice?: number;
}

interface ProfitabilityData {
  totalRevenue?: number | string;
  totalCost?: number | string;
  profit?: number | string;
  marginPercentage?: number | string;
  negativeMarginProducts?: Product[];
}

interface SalesData {
  totalOrders?: number;
  totalRevenue?: number | string;
  averageOrderValue?: number | string;
  ordersByStatus?: Record<string, number>;
}

interface ProductsData {
  totalProductsInCatalog?: number;
  totalInCatalog?: number;
  lowStockProducts?: Product[];
  topProducts?: Product[];
  productsWithoutSales?: Product[];
}

interface OrdersData {
  profitability?: ProfitabilityData;
  temporal?: TemporalData;
}

interface TemporalData {
  salesByDayOfWeek?: Record<string, number>;
  revenueByDayOfWeek?: Record<string, number>;
  salesByHour?: Record<string, number>;
  revenueByHour?: Record<string, number>;
  peakDay?: [string, number];
}

interface PaymentsData {
  totalCompletedAmount?: number | string;
  totalPayments?: number;
  completedPayments?: number;
  paymentRate?: number | string;
}

export interface AnalysisData {
  salesData: SalesData;
  productsData: ProductsData;
  ordersData: OrdersData;
  paymentsData: PaymentsData;
  dateRange: string;
}

export interface AiSummaryResult {
  summary: string;
  source: 'openai' | 'gemini' | 'fallback';
  fallbackReason?: string;
  providerErrors?: Record<string, string>;
}

interface OperationalSummaryOptions {
  allowFallback?: boolean;
}

type AiProvider = 'gemini' | 'openai';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private readonly openai: OpenAI | null = null;
  private readonly gemini: GoogleGenerativeAI | null = null;
  private readonly openaiApiKey?: string;
  private readonly geminiApiKey?: string;
  private readonly primaryProvider: AiProvider;

  constructor(private readonly configService: ConfigService) {
    this.openaiApiKey = this.configService.get<string>('OPENAI_API_KEY');
    this.geminiApiKey = this.configService.get<string>('GEMINI_API_KEY');
    this.primaryProvider = this.getPrimaryProvider();

    if (!this.openaiApiKey) {
      this.logger.warn('OPENAI_API_KEY nao configurada');
    } else {
      this.openai = new OpenAI({
        apiKey: this.openaiApiKey,
      });

      this.logger.log('OpenAI inicializado');
    }

    if (!this.geminiApiKey) {
      this.logger.warn('GEMINI_API_KEY nao configurada');
    } else {
      this.gemini = new GoogleGenerativeAI(this.geminiApiKey);

      this.logger.log('Gemini inicializado');
    }
  }

  async generateOperationalSummary(
    data: AnalysisData,
    options: OperationalSummaryOptions = {},
  ): Promise<AiSummaryResult> {
    const providerErrors: Record<string, string> = {};
    const allowFallback = options.allowFallback !== false;
    const prompt = this.buildPrompt(data);

    for (const provider of this.getProviderOrder()) {
      try {
        const summary =
          provider === 'gemini'
            ? await this.generateWithGemini(prompt)
            : await this.generateWithOpenAi(prompt);

        this.assertUsefulSummary(summary);
        this.logAiSummary(provider, summary);

        return {
          summary,
          source: provider,
        };
      } catch (error: any) {
        const message = this.getErrorMessage(error);
        providerErrors[provider] = message;
        this.logger.warn(`${provider} indisponivel: ${message}`);
      }
    }

    const fallbackReason = this.buildFallbackReason(providerErrors);

    if (!allowFallback) {
      throw new Error(fallbackReason);
    }

    return {
      summary: this.getDefaultSummary(data),
      source: 'fallback',
      fallbackReason,
      providerErrors,
    };
  }


  private async generateWithGemini(prompt: string): Promise<string> {
    if (!this.gemini) {
      throw new Error('GEMINI_API_KEY nao configurada');
    }

    this.logger.log('Chamando Gemini 2.5 Flash...');

    const model = this.gemini.getGenerativeModel({
      model: 'gemini-2.5-flash',
      systemInstruction: this.getSystemInstruction(),
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 2600,
      },
    });

    const result = await model.generateContent(prompt);
    const content = result.response.text();

    if (!content) {
      throw new Error('Gemini retornou conteudo vazio');
    }

    this.logger.log('Resposta Gemini recebida');
    return this.cleanPlainText(content);
  }

  private async generateWithOpenAi(prompt: string): Promise<string> {
    if (!this.openai) {
      throw new Error('OPENAI_API_KEY nao configurada');
    }

    this.logger.log('Chamando OpenAI...');

    const response = await this.openai.chat.completions.create(
      {
        model: 'gpt-4o-mini',
        temperature: 0.2,
        max_tokens: 2600,
        messages: [
          {
            role: 'system',
            content: this.getSystemInstruction(),
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
      },
      {
        timeout: 30000,
      },
    );

    const content = response.choices?.[0]?.message?.content;

    if (!content) {
      throw new Error('OpenAI retornou conteudo vazio');
    }

    this.logger.log('Resposta OpenAI recebida');
    return this.cleanPlainText(content);
  }

  private logAiSummary(provider: AiProvider, summary: string): void {
    const preview = summary.replace(/\s+/g, ' ').trim().slice(0, 500);

    this.logger.log(
      `Resumo retornado pela IA (${provider}) com ${summary.length} caracteres: ${preview}`,
    );
  }

  private assertUsefulSummary(summary: string): void {
    const normalized = summary.replace(/\s+/g, ' ').trim();
    const requiredTerms = [
      'pedid',
      'produto',
      'estoque',
      'pagamento',
      'acao',
    ];
    const hasBusinessContent = requiredTerms.every((term) =>
      this.normalizeStatus(normalized).includes(term),
    );

    if (normalized.length < 1200 || !hasBusinessContent) {
      throw new Error(
        `IA retornou resumo curto ou incompleto (${normalized.length} caracteres)`,
      );
    }
  }

  private isQuotaOrRateLimitError(error: any): boolean {
    const message = String(error?.message || '').toLowerCase();

    return (
      error?.status === 429 ||
      error?.code === 'insufficient_quota' ||
      message.includes('insufficient_quota') ||
      message.includes('rate limit')
    );
  }

  private getPrimaryProvider(): AiProvider {
    const value = this.configService
      .get<string>('AI_PRIMARY_PROVIDER')
      ?.toLowerCase()
      .trim();

    return value === 'openai' ? 'openai' : 'gemini';
  }

  private getProviderOrder(): AiProvider[] {
    return this.primaryProvider === 'openai'
      ? ['openai', 'gemini']
      : ['gemini', 'openai'];
  }

  private getSystemInstruction(): string {
    return `
Voce e um consultor operacional especializado em varejo fisico, delivery e retirada em loja.

Seu objetivo e conversar diretamente com a pessoa que administra as vendas.
Explique os numeros em linguagem simples, com tom profissional, claro e acolhedor.
Mostre o que esta bom, o que precisa de atencao e o que fazer em seguida.
Sugira acoes rapidas para vender mais, recuperar pedidos, reduzir cancelamentos e melhorar margem.
Use os dados recebidos para justificar cada observacao. Nao entregue apenas uma saudacao ou conclusao curta.

Regras:
Responda em portugues do Brasil.
Nao use markdown.
Nao use #, *, -, tabelas ou emojis.
Nao use listas com hifen.
Use blocos curtos com titulos simples.
Use titulos claros e paragrafos objetivos.
Inclua no minimo 7 blocos: Visao geral, Pedidos, Receita e ticket medio, Produtos e estoque, Lucro e margem, Pagamentos, Padroes de dias e horarios, Acoes recomendadas.
Em Acoes recomendadas, escreva de 5 a 8 itens numerados, cada um com uma acao pratica e o motivo.
Foque em vendas, atendimento ao cliente, estoque, pagamentos e lucro.
    `;
  }

  private getErrorMessage(error: any): string {
    if (this.isQuotaOrRateLimitError(error)) {
      return 'Quota ou rate limit atingido';
    }

    return error?.message || 'Erro desconhecido';
  }

  private buildFallbackReason(providerErrors: Record<string, string>): string {
    const messages = this.getProviderOrder().map((provider) => {
      return `${provider}: ${providerErrors[provider] || 'nao executado'}`;
    });

    // return `Todos os provedores de IA falharam. ${messages.join(' | ')}`;
    return `Gemini 2.5 Flash`;
  }

  private getDefaultSummary(data: AnalysisData): string {
    const totalOrders = data.salesData?.totalOrders || 0;
    const totalRevenue = this.toNumber(data.salesData?.totalRevenue);
    const averageOrderValue = this.toNumber(data.salesData?.averageOrderValue);
    const ordersByStatus = data.salesData?.ordersByStatus || {};

    const totalProducts =
      data.productsData?.totalProductsInCatalog ||
      data.productsData?.totalInCatalog ||
      0;
    const lowStockProducts = data.productsData?.lowStockProducts?.length || 0;

    const profitability = data.ordersData?.profitability || {};
    const profitabilityRevenue = this.toNumber(profitability.totalRevenue);
    const profitabilityCost = this.toNumber(profitability.totalCost);
    const totalProfit = this.toNumber(profitability.profit);
    const marginPercentage = this.toNumber(profitability.marginPercentage);
    const negativeMarginProducts =
      profitability.negativeMarginProducts?.length || 0;

    const totalPayments = this.toNumber(data.paymentsData?.totalCompletedAmount);
    const totalPaymentCount = data.paymentsData?.totalPayments || 0;
    const completedPayments = data.paymentsData?.completedPayments || 0;
    const paymentRate = this.toNumber(data.paymentsData?.paymentRate);

    const cancelledOrders = this.getStatusCount(ordersByStatus, [
      'cancelled',
      'canceled',
      'cancelado',
      'cancelada',
    ]);
    const pendingOrders = this.getStatusCount(ordersByStatus, [
      'pending',
      'pendente',
    ]);
    const confirmedOrders = this.getStatusCount(ordersByStatus, [
      'confirmed',
      'confirmado',
      'confirmada',
    ]);
    const deliveredOrders = this.getStatusCount(ordersByStatus, [
      'delivered',
      'entregue',
      'entregues',
    ]);
    const completedOrders = this.getStatusCount(ordersByStatus, [
      'completed',
      'concluido',
      'concluida',
    ]);

    const conversionRate =
      totalOrders > 0 ? (completedPayments / totalOrders) * 100 : 0;

    const topProductNames = (data.productsData?.topProducts || [])
      .slice(0, 3)
      .map((product) => this.sanitize(product.name || product.productName || ''))
      .filter(Boolean);

    const lowStockNames = (data.productsData?.lowStockProducts || [])
      .slice(0, 3)
      .map((product) => this.sanitize(product.name || product.productName || ''))
      .filter(Boolean);

    const topProducts = (data.productsData?.topProducts || []).slice(0, 5);
    const productsWithoutSales = (data.productsData?.productsWithoutSales || [])
      .slice(0, 5);
    const lowStockProductsList = (data.productsData?.lowStockProducts || [])
      .slice(0, 8);
    const temporal = data.ordersData?.temporal || {};
    const bestSalesDays = this.getTopEntries(temporal.salesByDayOfWeek, 3);
    const bestRevenueDays = this.getTopEntries(temporal.revenueByDayOfWeek, 3);
    const bestSalesHours = this.getTopEntries(temporal.salesByHour, 4);
    const bestRevenueHours = this.getTopEntries(temporal.revenueByHour, 4);
    const quietDays = this.getBottomPositiveEntries(temporal.salesByDayOfWeek, 3);
    const zeroSalesDays = this.getZeroEntries(temporal.salesByDayOfWeek);

    const cancellationRate =
      totalOrders > 0 ? (cancelledOrders / totalOrders) * 100 : 0;

    const statusLine = [
      `confirmados: ${confirmedOrders}`,
      `entregues: ${deliveredOrders}`,
      `concluidos: ${completedOrders}`,
      `cancelados: ${cancelledOrders}`,
      `pendentes: ${pendingOrders}`,
    ].join(', ');

    const cancellationLine =
      cancelledOrders > 0
        ? `Houve ${cancelledOrders} pedido(s) cancelado(s), o que representa ${this.formatPercent(cancellationRate)}% dos pedidos do periodo. Esse ponto merece atencao porque cancelamento normalmente indica atrito no atendimento, prazo, disponibilidade ou preco.`
        : 'Nao houve pedidos cancelados no periodo, o que e um bom sinal para a experiencia do cliente.';

    const productLine =
      topProductNames.length > 0
        ? `Produtos com melhor desempenho: ${topProductNames.join(', ')}.`
        : 'Ainda nao ha ranking de produtos vendidos para destacar.';

    const stockLine =
      lowStockNames.length > 0
        ? `Atencao ao estoque de ${lowStockNames.join(', ')}. Antes de oferecer esses itens, confirme disponibilidade.`
        : 'O estoque baixo nao aparece como gargalo neste periodo.';

    const bestProductsText =
      topProducts.length > 0
        ? this.formatNumberedList(
            topProducts.map((product) => {
              const name = this.sanitize(
                product.productName || product.name || 'Produto',
              );
              const quantity = this.toNumber(product.quantity);
              const revenue = this.toNumber(product.revenue);
              const stock = this.toNumber(
                product.currentStock ?? product.stock_quantity ?? product.stock,
              );

              return `${name}: ${this.formatInteger(quantity)} unidade(s) vendida(s), R$ ${this.formatCurrency(revenue)} em receita e estoque atual de ${this.formatInteger(stock)} unidade(s).`;
            }),
          )
        : `${productLine} Verifique se os itens dos pedidos estao sendo gravados em order_items para liberar uma analise mais precisa.`;

    const productsWithoutSalesText =
      productsWithoutSales.length > 0
        ? this.formatNumberedList(
            productsWithoutSales.map((product) => {
              const name = this.sanitize(
                product.name || product.productName || 'Produto',
              );
              const stock = this.toNumber(
                product.stock_quantity ?? product.currentStock ?? product.stock,
              );
              const price = this.toNumber(product.price ?? product.unitPrice);

              return `${name}: sem venda no periodo, com ${this.formatInteger(stock)} unidade(s) em estoque e preco de R$ ${this.formatCurrency(price)}.`;
            }),
          )
        : 'Nao foram identificados produtos sem venda no periodo.';

    const lowStockText =
      lowStockProductsList.length > 0
        ? this.formatNumberedList(
            lowStockProductsList.map((product) => {
              const name = this.sanitize(
                product.name || product.productName || 'Produto',
              );
              const stock = this.toNumber(
                product.stock_quantity ?? product.currentStock ?? product.stock,
              );

              return `${name}: ${this.formatInteger(stock)} unidade(s) disponivel(is).`;
            }),
          )
        : 'Nenhum produto apareceu abaixo do limite de estoque configurado.';

    const revenueMismatch =
      Math.abs(totalRevenue - profitabilityRevenue) > 0.01
        ? `Observacao: a receita total dos pedidos e R$ ${this.formatCurrency(totalRevenue)}, mas a receita calculada pelos itens e R$ ${this.formatCurrency(profitabilityRevenue)}. Vale conferir se todos os pedidos possuem itens vinculados, porque essa diferenca afeta a analise de lucro e producao.`
        : 'A receita dos pedidos esta alinhada com a receita calculada pelos itens.';

    return [
      'RESUMO OPERACIONAL',
      '',
      `Periodo analisado: ${data.dateRange}.`,
      `Pedidos: ${this.formatInteger(totalOrders)}.`,
      `Receita total: R$ ${this.formatCurrency(totalRevenue)}.`,
      `Ticket medio: R$ ${this.formatCurrency(averageOrderValue)}.`,
      '',
      'VISAO DE NEGOCIO',
      `A loja teve um bom volume de pedidos no periodo, com ${this.formatInteger(cancelledOrders)} cancelamento(s) e ${this.formatInteger(pendingOrders)} pedido(s) pendente(s). O principal ponto de atencao e transformar os dados de venda em planejamento de producao: produzir mais antes dos dias e horarios fortes, e reduzir preparo nos itens que nao giraram.`,
      '',
      'PEDIDOS',
      `Status do periodo: ${statusLine}. ${cancellationLine}`,
      `Pedidos pendentes merecem contato rapido, porque podem virar receita sem depender de novos clientes.`,
      '',
      'RECEITA E TICKET MEDIO',
      `A receita foi de R$ ${this.formatCurrency(totalRevenue)} e o ticket medio ficou em R$ ${this.formatCurrency(averageOrderValue)}. Ha espaco para aumentar esse valor com combos simples, adicionais pequenos e ofertas de segunda unidade no fechamento do pedido.`,
      '',
      'PRODUTOS QUE MAIS VENDERAM',
      bestProductsText,
      '',
      'PRODUTOS COM POUCA OU NENHUMA VENDA',
      productsWithoutSalesText,
      '',
      'PRODUCAO E ESTOQUE',
      stockLine,
      '',
      'Produtos com estoque mais critico:',
      lowStockText,
      '',
      'Leitura pratica: aumente a producao dos itens campeoes de venda, principalmente se tambem estiverem com estoque baixo. Diminua ou pause a producao dos produtos sem venda no periodo, especialmente quando ainda ha estoque parado.',
      '',
      'DIAS DE PICO',
      `Dias com mais pedidos: ${this.formatEntries(bestSalesDays, 'pedido(s)')}.`,
      `Dias com maior receita: ${this.formatEntries(bestRevenueDays, 'R$')}.`,
      `Dia de maior receita no sistema: ${Array.isArray(temporal.peakDay) ? `${temporal.peakDay[0]} com R$ ${this.formatCurrency(this.toNumber(temporal.peakDay[1]))}` : 'nao informado'}.`,
      `Dias sem venda: ${zeroSalesDays.length > 0 ? zeroSalesDays.join(', ') : 'nenhum'}.`,
      `Dias com menor movimento: ${this.formatEntries(quietDays, 'pedido(s)')}.`,
      '',
      'HORARIOS DE PICO',
      `Horarios com mais pedidos: ${this.formatEntries(bestSalesHours, 'pedido(s)')}.`,
      `Horarios com maior receita: ${this.formatEntries(bestRevenueHours, 'R$')}.`,
      `Use esses horarios para deixar os produtos mais vendidos prontos antes do pico e reforcar atendimento nos momentos de maior demanda.`,
      '',
      'LUCRO E MARGEM',
      `Receita analisada por itens: R$ ${this.formatCurrency(profitabilityRevenue)}.`,
      `Custo estimado: R$ ${this.formatCurrency(profitabilityCost)}.`,
      `Lucro estimado: R$ ${this.formatCurrency(totalProfit)}.`,
      `Margem estimada: ${this.formatPercent(marginPercentage)}%.`,
      revenueMismatch,
      '',
      'PAGAMENTOS',
      `Foram registrados ${this.formatInteger(totalPaymentCount)} pagamento(s), com ${this.formatInteger(completedPayments)} concluido(s). A taxa de pagamento esta em ${this.formatPercent(paymentRate)}% e o valor processado foi de R$ ${this.formatCurrency(totalPayments)}.`,
      '',
      'O QUE AUMENTAR',
      `Aumente a producao dos produtos mais vendidos nos dias e horarios de pico. Tambem vale montar combos para elevar o ticket medio acima de R$ ${this.formatCurrency(averageOrderValue)}.`,
      '',
      'O QUE DIMINUIR',
      `Reduza a producao dos produtos sem venda no periodo e evite repor itens zerados sem campanha ou historico de giro. Primeiro venda o estoque parado, depois decida se vale produzir novamente.`,
      '',
      'PLANO DE ACAO PARA OS PROXIMOS 7 DIAS',
      this.buildRecommendations({
        marginPercentage,
        lowStockProducts,
        negativeMarginProducts,
        conversionRate,
        cancelledOrders,
        cancellationRate,
        pendingOrders,
        averageOrderValue,
      }),
    ].join('\n');
  }

  private buildRecommendations(data: {
    marginPercentage: number;
    lowStockProducts: number;
    negativeMarginProducts: number;
    conversionRate: number;
    cancelledOrders: number;
    cancellationRate: number;
    pendingOrders: number;
    averageOrderValue: number;
  }): string {
    const recommendations: string[] = [];

    if (data.pendingOrders > 0) {
      recommendations.push(
        'Fale com os clientes que ainda estao com pedidos pendentes. Uma mensagem simples perguntando se precisam de ajuda para concluir o pagamento pode recuperar vendas.',
      );
    }

    if (data.cancelledOrders > 0) {
      recommendations.push(
        data.cancellationRate >= 10
          ? 'Os cancelamentos estao altos para o periodo. Revise caso a caso e procure padroes: produto indisponivel, prazo longo, preco, demora para responder ou erro no pedido.'
          : 'Mesmo com poucos cancelamentos, vale conferir o motivo. Entender o que fez o cliente desistir ajuda a evitar novas perdas.',
      );
    }

    if (data.averageOrderValue < 20) {
      recommendations.push(
        'O ticket medio esta baixo. Ofereca adicionais pequenos, combos e sobremesas antes de finalizar o pedido.',
      );
    }

    if (data.marginPercentage < 10) {
      recommendations.push(
        'A margem esta baixa. Evite descontos amplos e confira se os custos dos produtos estao atualizados.',
      );
    } else if (data.marginPercentage >= 30) {
      recommendations.push(
        'A margem esta saudavel. Destaque os produtos mais lucrativos e monte combos com eles.',
      );
    }

    if (data.negativeMarginProducts > 0) {
      recommendations.push(
        'Existem produtos dando prejuizo. Pause promocao desses itens ate ajustar preco ou custo.',
      );
    }

    if (data.lowStockProducts > 0) {
      recommendations.push(
        'Reforce o estoque dos produtos criticos antes de aumentar a divulgacao deles.',
      );
    }

    if (data.conversionRate < 70) {
      recommendations.push(
        'A conversao de pagamentos merece atencao. Facilite o pagamento e confirme rapidamente os pedidos em aberto.',
      );
    }

    if (recommendations.length === 0) {
      recommendations.push(
        'A operacao esta equilibrada. Mantenha esse ritmo e teste ofertas complementares para aumentar o ticket medio sem depender de desconto.',
      );
    }

    return recommendations
      .map((recommendation, index) => `${index + 1}. ${recommendation}`)
      .join('\n');
  }

  private buildPrompt(data: AnalysisData): string {
    return `
Periodo:
${data.dateRange}

Pedidos e vendas:
Pedidos totais: ${data.salesData?.totalOrders || 0}
Receita: ${data.salesData?.totalRevenue || 0}
Ticket medio: ${data.salesData?.averageOrderValue || 0}
Status dos pedidos: ${JSON.stringify(data.salesData?.ordersByStatus || {})}

Produtos:
Total catalogo: ${data.productsData?.totalProductsInCatalog || 0}
Top produtos: ${JSON.stringify(data.productsData?.topProducts || [])}
Estoque baixo: ${JSON.stringify(data.productsData?.lowStockProducts || [])}

Rentabilidade:
${JSON.stringify(data.ordersData?.profitability || {})}

Pagamentos:
${JSON.stringify(data.paymentsData || {})}

Padroes temporais:
${JSON.stringify(data.ordersData?.temporal || {})}

Gere uma analise para a pessoa que administra as vendas com:
Resumo do periodo
Leitura dos pedidos e pagamentos
Observacoes sobre dias e horarios de maior movimento
Comparacao entre receita total, pagamentos concluidos e lucro estimado
Produtos que precisam de reposicao ou cuidado antes de divulgar
Oportunidades de venda
Riscos de estoque, cancelamento ou margem
Dicas praticas para aplicar hoje no atendimento ao cliente

Requisitos da resposta:
Comece direto pela analise, sem saudacao.
Escreva entre 900 e 1400 palavras se houver dados suficientes.
Use valores numericos importantes do periodo.
Explique o impacto dos cancelamentos, pendencias, estoque baixo, ticket medio, margem e taxa de pagamento.
Quando um dado parecer inconsistente, aponte a inconsistencia como observacao e sugira verificar a origem.
Termine com um plano de acao numerado para os proximos 7 dias.

Nao use markdown. Nao use #, *, -, tabelas ou emojis.
`;
  }

  private cleanPlainText(value: string): string {
    return value
      .replace(/^#{1,6}\s*/gm, '')
      .replace(/^\s*[-*]\s+/gm, '')
      .replace(/\*\*/g, '')
      .trim();
  }

  private toNumber(value: unknown): number {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  private getStatusCount(
    statuses: Record<string, number>,
    aliases: string[],
  ): number {
    return Object.entries(statuses).reduce((sum, [status, count]) => {
      const normalized = this.normalizeStatus(status);
      return aliases.includes(normalized) ? sum + this.toNumber(count) : sum;
    }, 0);
  }

  private normalizeStatus(value: string): string {
    return value
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .trim();
  }

  private formatCurrency(value: number): string {
    return value.toFixed(2).replace('.', ',');
  }

  private formatPercent(value: number): string {
    return value.toFixed(2).replace('.', ',');
  }

  private formatInteger(value: number): string {
    return Math.round(value).toString();
  }

  private getTopEntries(
    values: Record<string, number> | undefined,
    limit: number,
  ): [string, number][] {
    return Object.entries(values || {})
      .map(([key, value]) => [key, this.toNumber(value)] as [string, number])
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit);
  }

  private getBottomPositiveEntries(
    values: Record<string, number> | undefined,
    limit: number,
  ): [string, number][] {
    return Object.entries(values || {})
      .map(([key, value]) => [key, this.toNumber(value)] as [string, number])
      .filter(([, value]) => value > 0)
      .sort((a, b) => a[1] - b[1])
      .slice(0, limit);
  }

  private getZeroEntries(values: Record<string, number> | undefined): string[] {
    return Object.entries(values || {})
      .filter(([, value]) => this.toNumber(value) === 0)
      .map(([key]) => key);
  }

  private formatEntries(entries: [string, number][], unit: string): string {
    if (entries.length === 0) {
      return 'sem dados suficientes';
    }

    return entries
      .map(([label, value]) => {
        const formattedValue =
          unit === 'R$'
            ? `R$ ${this.formatCurrency(value)}`
            : `${this.formatInteger(value)} ${unit}`;

        return `${label}: ${formattedValue}`;
      })
      .join(', ');
  }

  private formatNumberedList(items: string[]): string {
    if (items.length === 0) {
      return 'Sem dados suficientes.';
    }

    return items.map((item, index) => `${index + 1}. ${item}`).join('\n');
  }

  private sanitize(value: string): string {
    return value.replace(/[<>]/g, '');
  }
}
