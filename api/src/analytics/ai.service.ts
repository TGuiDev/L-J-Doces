import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';

interface Product {
  name?: string;
  productName?: string;
  stock?: number;
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
}

interface OrdersData {
  profitability?: ProfitabilityData;
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

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private readonly openai: OpenAI | null = null;
  private readonly apiKey?: string;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = this.configService.get<string>('OPENAI_API_KEY');

    if (!this.apiKey) {
      this.logger.warn('OPENAI_API_KEY nao configurada');
      return;
    }

    this.openai = new OpenAI({
      apiKey: this.apiKey,
    });

    this.logger.log('OpenAI inicializado');
  }

  async generateOperationalSummary(data: AnalysisData): Promise<string> {
    try {
      if (!this.openai) {
        this.logger.warn('OpenAI indisponivel. Usando fallback.');
        return this.getDefaultSummary(data);
      }

      const prompt = this.buildPrompt(data);

      this.logger.log('Chamando OpenAI...');

      const response = await this.openai.chat.completions.create(
        {
          model: 'gpt-4o-mini',
          temperature: 0.2,
          max_tokens: 450,
          messages: [
            {
              role: 'system',
              content: `
Voce e um consultor operacional especializado em varejo fisico, delivery e retirada em loja.

Seu objetivo e conversar diretamente com a pessoa que administra as vendas.
Explique os numeros em linguagem simples, com tom profissional, claro e acolhedor.
Mostre o que esta bom, o que precisa de atencao e o que fazer em seguida.
Sugira acoes rapidas para vender mais, recuperar pedidos, reduzir cancelamentos e melhorar margem.

Regras:
Responda em portugues do Brasil.
Nao use markdown.
Nao use #, *, -, tabelas ou emojis.
Nao use listas com hifen.
Use blocos curtos com titulos simples.
Foque em vendas, atendimento ao cliente, estoque, pagamentos e lucro.
              `,
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
        this.logger.warn('IA retornou conteudo vazio. Usando fallback.');
        return this.getDefaultSummary(data);
      }

      this.logger.log('Resposta IA recebida');
      return this.cleanPlainText(content);
    } catch (error: any) {
      if (this.isQuotaOrRateLimitError(error)) {
        this.logger.warn('Quota ou rate limit atingido. Usando fallback.');
        return this.getDefaultSummary(data);
      }

      this.logger.error('Erro OpenAI', error?.stack || error);
      return this.getDefaultSummary(data);
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

    return `Resumo do periodo
No periodo ${data.dateRange}, sua loja registrou ${totalOrders} pedidos e R$ ${this.formatCurrency(totalRevenue)} em receita. O ticket medio ficou em R$ ${this.formatCurrency(averageOrderValue)}.

Leitura dos pedidos
A situacao ficou assim: ${statusLine}. ${cancellationLine}

Vendas e produtos
${productLine}
Produtos no catalogo: ${totalProducts}.\n${stockLine}

Lucro
A receita analisada foi de R$ ${this.formatCurrency(profitabilityRevenue)}, com custo estimado de R$ ${this.formatCurrency(profitabilityCost)} e lucro de R$ ${this.formatCurrency(totalProfit)}. A margem esta em ${this.formatPercent(marginPercentage)}%. Esse numero mostra quanto sobra depois dos custos dos produtos.

Pagamentos
Foram registrados ${totalPaymentCount} pagamentos, com ${completedPayments} concluidos. A taxa de pagamento esta em ${this.formatPercent(paymentRate)}% e o valor processado foi R$ ${this.formatCurrency(totalPayments)}. Quanto mais rapido o pagamento for confirmado, menor a chance de perda do pedido.

Dicas para melhorar agora
${this.buildRecommendations({
      marginPercentage,
      lowStockProducts,
      negativeMarginProducts,
      conversionRate,
      cancelledOrders,
      cancellationRate,
      pendingOrders,
      averageOrderValue,
    })}`;
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

Gere uma analise para a pessoa que administra as vendas com:
Resumo do periodo
Leitura dos pedidos e pagamentos
Oportunidades de venda
Riscos de estoque, cancelamento ou margem
Dicas praticas para aplicar hoje no atendimento ao cliente

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
    return value.toFixed(2);
  }

  private formatPercent(value: number): string {
    return value.toFixed(2);
  }

  private sanitize(value: string): string {
    return value.replace(/[<>]/g, '');
  }
}
