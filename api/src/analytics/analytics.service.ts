import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class AnalyticsService {
  constructor(private supabaseService: SupabaseService) {}

  async getSalesAnalytics(startDate?: Date, endDate?: Date) {
    const client = this.supabaseService.getClient();

    // Definir datas padrão (últimos 30 dias)
    const end = endDate || new Date();
    const start = startDate || new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000);

    const startISO = start.toISOString();
    const endISO = end.toISOString();

    try {
      // Total de vendas
      const { data: orders } = await client
        .from('orders')
        .select('*')
        .gte('created_at', startISO)
        .lte('created_at', endISO);

      // Diagnostics: log counts by status and sample date range
      const totalFetched = (orders || []).length;
      const statuses = {} as Record<string, number>;
      let minDate: string | null = null;
      let maxDate: string | null = null;
      (orders || []).forEach((o: any) => {
        statuses[o.status] = (statuses[o.status] || 0) + 1;
        const d = o.created_at;
        if (d) {
          if (!minDate || d < minDate) minDate = d;
          if (!maxDate || d > maxDate) maxDate = d;
        }
      });
      console.log(`[ANALYTICS] Sales fetch: requested ${startISO}..${endISO} - fetched=${totalFetched} statuses=${JSON.stringify(statuses)} range=${minDate}..${maxDate}`);

      // Calcular receita total de todos os pedidos do perÇðodo
      const totalRevenue = (orders || []).reduce(
        (sum, order) => sum + parseFloat(order.total_amount || 0),
        0,
      );

      // Status de pedidos
      const ordersByStatus = {};
      orders?.forEach((order) => {
        ordersByStatus[order.status] =
          (ordersByStatus[order.status] || 0) + 1;
      });

      return {
        totalOrders: orders?.length || 0,
        totalRevenue,
        averageOrderValue: orders?.length ? totalRevenue / orders.length : 0,
        ordersByStatus,
        dateRange: `${start.toLocaleDateString('pt-BR')} a ${end.toLocaleDateString('pt-BR')}`,
      };
    } catch (error) {
      console.error('Erro ao buscar análise de vendas:', error);
      throw error;
    }
  }

  async getProductAnalytics(startDate?: Date, endDate?: Date) {
    const client = this.supabaseService.getClient();

    const end = endDate || new Date();
    const start = startDate || new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000);

    const startISO = start.toISOString();
    const endISO = end.toISOString();

    try {
      const { data: orders, error: ordersError } = await client
        .from('orders')
        .select('id')
        .gte('created_at', startISO)
        .lte('created_at', endISO)
        .neq('status', 'cancelled');

      if (ordersError) throw ordersError;

      const orderIds = (orders || []).map((order) => order.id);

      const { data: products, error: productsError } = await client
        .from('products')
        .select('id, name, stock_quantity, price, cost_price');

      if (productsError) throw productsError;

      const productSales = {};

      if (orderIds.length > 0) {
        const { data: orderItems, error: itemsError } = await client
          .from('order_items')
          .select('product_id, quantity, unit_price')
          .in('order_id', orderIds);

        if (itemsError) throw itemsError;

        orderItems?.forEach((item) => {
          if (!productSales[item.product_id]) {
            productSales[item.product_id] = { quantity: 0, revenue: 0 };
          }

          productSales[item.product_id].quantity += Number(item.quantity || 0);
          productSales[item.product_id].revenue +=
            Number(item.quantity || 0) * Number(item.unit_price || 0);
        });
      }

      const topProducts = Object.entries(productSales)
        .map(([productId, sales]: any) => {
          const product = products?.find((p) => p.id === productId);
          const costPrice = Number(product?.cost_price || 0);

          return {
            productId,
            productName: product?.name || 'Desconhecido',
            quantity: sales.quantity,
            revenue: sales.revenue,
            profit: sales.revenue - costPrice * sales.quantity,
            currentStock: Number(product?.stock_quantity || 0),
            unitPrice: Number(product?.price || 0),
            costPrice,
          };
        })
        .sort((a, b) => b.quantity - a.quantity || b.revenue - a.revenue)
        .slice(0, 10);

      const soldProductIds = new Set(Object.keys(productSales));
      const productsWithoutSales = (products || [])
        .filter((product) => !soldProductIds.has(product.id))
        .sort(
          (a, b) =>
            Number(b.stock_quantity || 0) - Number(a.stock_quantity || 0),
        )
        .slice(0, 10);

      const lowStockProducts = (products || [])
        .filter((product) => Number(product.stock_quantity || 0) < 10)
        .sort(
          (a, b) =>
            Number(a.stock_quantity || 0) - Number(b.stock_quantity || 0),
        );

      console.log(
        `[ANALYTICS] Product fetch: orders=${orderIds.length} top=${topProducts.length} withoutSales=${productsWithoutSales.length} lowStock=${lowStockProducts.length}`,
      );

      return {
        topProducts,
        lowStockProducts,
        productsWithoutSales,
        totalProductsInCatalog: products?.length || 0,
      };
    } catch (error) {
      console.error('Erro ao buscar análise de produtos:', error);
      throw error;
    }
  }

  async getProfitabilityAnalysis(startDate?: Date, endDate?: Date) {
    const client = this.supabaseService.getClient();

    const end = endDate || new Date();
    const start = startDate || new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000);

    const startISO = start.toISOString();
    const endISO = end.toISOString();

    try {
      const { data: orders, error: ordersError } = await client
        .from('orders')
        .select('id')
        .gte('created_at', startISO)
        .lte('created_at', endISO)
        .neq('status', 'cancelled');

      if (ordersError) throw ordersError;

      const orderIds = (orders || []).map((order) => order.id);

      let orderItems = [];

      if (orderIds.length > 0) {
        const { data, error: itemsError } = await client
          .from('order_items')
          .select('product_id, quantity, unit_price')
          .in('order_id', orderIds);

        if (itemsError) throw itemsError;
        orderItems = data || [];
      }

      // Buscar custos dos produtos
      const { data: products, error: productsError } = await client
        .from('products')
        .select('id, name, cost_price, price');

      if (productsError) throw productsError;

      let totalRevenue = 0;
      let totalCost = 0;

      orderItems?.forEach((item) => {
          const product = products?.find((p) => p.id === item.product_id);
          if (product) {
            totalRevenue += parseFloat(item.unit_price) * item.quantity;
            totalCost += (parseFloat(product.cost_price) || 0) * item.quantity;
          }
      });

      console.log(
        `[ANALYTICS] Profitability fetch: orders=${orderIds.length} items=${orderItems.length} revenue=${totalRevenue} cost=${totalCost}`,
      );

      const profit = totalRevenue - totalCost;
      const marginPercentage = totalRevenue > 0 ? (profit / totalRevenue) * 100 : 0;

      // Produtos com margem negativa
      const negativeMarginProducts = [];
      const productMetrics = {};

      orderItems?.forEach((item) => {
          const product = products?.find((p) => p.id === item.product_id);
          if (product) {
            if (!productMetrics[item.product_id]) {
              productMetrics[item.product_id] = {
                revenue: 0,
                cost: 0,
                quantity: 0,
                name: product.name || 'Desconhecido',
              };
            }
            const itemRevenue = parseFloat(item.unit_price) * item.quantity;
            const itemCost =
              (parseFloat(product.cost_price) || 0) * item.quantity;

            productMetrics[item.product_id].revenue += itemRevenue;
            productMetrics[item.product_id].cost += itemCost;
            productMetrics[item.product_id].quantity += item.quantity;
          }
      });

      Object.entries(productMetrics).forEach(([, metric]: any) => {
        const margin = metric.revenue - metric.cost;
        if (margin < 0) {
          negativeMarginProducts.push({
            name: metric.name,
            revenue: metric.revenue,
            cost: metric.cost,
            loss: margin,
          });
        }
      });

      return {
        totalRevenue,
        totalCost,
        profit,
        marginPercentage: marginPercentage.toFixed(2),
        hasLosses: profit < 0,
        negativeMarginProducts,
      };
    } catch (error) {
      console.error('Erro ao buscar análise de lucratividade:', error);
      throw error;
    }
  }

  async getPaymentAnalytics(startDate?: Date, endDate?: Date) {
    const client = this.supabaseService.getClient();

    const end = endDate || new Date();
    const start = startDate || new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000);

    const startISO = start.toISOString();
    const endISO = end.toISOString();

    try {
      const { data: payments } = await client
        .from('payments')
        .select('*')
        .gte('created_at', startISO)
        .lte('created_at', endISO);

      const paymentByStatus = {};
      const paymentByMethod = {};

      payments?.forEach((payment) => {
        paymentByStatus[payment.status] =
          (paymentByStatus[payment.status] || 0) + 1;
        paymentByMethod[payment.payment_method] =
          (paymentByMethod[payment.payment_method] || 0) + 1;
      });

      const completedPayments = payments?.filter(
        (p) => p.status === 'completed',
      ) || [];
      const totalCompletedAmount = completedPayments.reduce(
        (sum, p) => sum + parseFloat(p.amount || 0),
        0,
      );

      return {
        totalPayments: payments?.length || 0,
        completedPayments: completedPayments.length,
        paymentRate:
          payments?.length > 0
            ? ((completedPayments.length / payments.length) * 100).toFixed(2)
            : 0,
        totalCompletedAmount,
        paymentsByStatus: paymentByStatus,
        paymentsByMethod: paymentByMethod,
      };
    } catch (error) {
      console.error('Erro ao buscar análise de pagamentos:', error);
      throw error;
    }
  }

  async getTemporalAnalytics(startDate?: Date, endDate?: Date) {
    const client = this.supabaseService.getClient();

    const end = endDate || new Date();
    const start = startDate || new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000);

    const startISO = start.toISOString();
    const endISO = end.toISOString();

    try {
      const { data: orders } = await client
        .from('orders')
        .select('created_at, total_amount')
        .gte('created_at', startISO)
        .lte('created_at', endISO);

      // Agrupar por dia da semana
      const salesByDayOfWeek = {
        'Segunda-feira': 0,
        'Terça-feira': 0,
        'Quarta-feira': 0,
        'Quinta-feira': 0,
        'Sexta-feira': 0,
        'Sábado': 0,
        'Domingo': 0,
      };

      const daysOfWeek = [
        'Domingo',
        'Segunda-feira',
        'Terça-feira',
        'Quarta-feira',
        'Quinta-feira',
        'Sexta-feira',
        'Sábado',
      ];

      const revenueByDayOfWeek = { ...salesByDayOfWeek };

      orders?.forEach((order) => {
        const date = new Date(order.created_at);
        const day = daysOfWeek[date.getDay()];
        salesByDayOfWeek[day]++;
        revenueByDayOfWeek[day] +=
          parseFloat(order.total_amount) || 0;
      });

      // Agrupar por hora do dia
      const salesByHour = {};
      const revenueByHour = {};

      for (let i = 0; i < 24; i++) {
        salesByHour[`${i}:00`] = 0;
        revenueByHour[`${i}:00`] = 0;
      }

      orders?.forEach((order) => {
        const date = new Date(order.created_at);
        const hour = `${date.getHours()}:00`;
        salesByHour[hour]++;
        revenueByHour[hour] += parseFloat(order.total_amount) || 0;
      });

      return {
        salesByDayOfWeek,
        revenueByDayOfWeek,
        salesByHour,
        revenueByHour,
        peakDay: Object.entries(revenueByDayOfWeek).reduce((a, b) =>
          b[1] > a[1] ? b : a,
        ),
      };
    } catch (error) {
      console.error('Erro ao buscar análise temporal:', error);
      throw error;
    }
  }
}
