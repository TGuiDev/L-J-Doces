import { Injectable, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { StockGateway } from '../websockets/stock.gateway';
import { OrdersGateway } from '../websockets/orders.gateway';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class OrdersService {
  constructor(
    private supabaseService: SupabaseService,
    private stockGateway: StockGateway,
    private ordersGateway: OrdersGateway,
  ) {}

  private isFunctionMissingError(error: any): boolean {
    const message = String(error?.message || '').toLowerCase();
    return (
      message.includes('could not find the function') ||
      message.includes('apply_order_stock_deduction') ||
      error?.code === 'PGRST202'
    );
  }

  private isTableMissingError(error: any, tableName: string): boolean {
    const message = String(error?.message || '').toLowerCase();
    return (
      message.includes(`relation "public.${tableName}" does not exist`) ||
      message.includes(`relation "${tableName}" does not exist`) ||
      message.includes(tableName.toLowerCase())
    );
  }

  private async applyStockDeductionFallback(orderId: string, reason: string) {
    const supabase = this.supabaseService.getClient();

    const { data: orderItems, error: itemsError } = await supabase
      .from('order_items')
      .select('product_id, quantity, products(id, name, stock_quantity)')
      .eq('order_id', orderId);

    if (itemsError) {
      throw new BadRequestException(itemsError.message);
    }

    const items = (orderItems || []) as any[];
    if (items.length === 0) {
      throw new BadRequestException('Pedido sem itens para deduzir estoque');
    }

    const requestedByProduct = items.reduce((acc, item) => {
      acc[item.product_id] = (acc[item.product_id] || 0) + Number(item.quantity || 0);
      return acc;
    }, {} as Record<string, number>);

    const productIds = Object.keys(requestedByProduct);
    const { data: products, error: productsError } = await supabase
      .from('products')
      .select('id, name, stock_quantity')
      .in('id', productIds);

    if (productsError) {
      throw new BadRequestException(productsError.message);
    }

    const productsById = new Map<string, any>((products || []).map((product: any) => [product.id, product]));

    for (const productId of productIds) {
      const product = productsById.get(productId);
      if (!product) {
        throw new BadRequestException(`Produto não encontrado para baixa de estoque: ${productId}`);
      }

      const requested = requestedByProduct[productId];
      const currentStock = Number(product.stock_quantity || 0);

      if (requested > currentStock) {
        throw new BadRequestException(
          `Estoque insuficiente para ${product.name}. Disponível: ${currentStock}, solicitado: ${requested}`,
        );
      }
    }

    for (const productId of productIds) {
      const product = productsById.get(productId);
      const requested = requestedByProduct[productId];
      const currentStock = Number(product.stock_quantity || 0);
      const nextStock = currentStock - requested;

      const { error: updateError } = await supabase
        .from('products')
        .update({ stock_quantity: nextStock })
        .eq('id', productId);

      if (updateError) {
        throw new BadRequestException(updateError.message);
      }

      // Broadcast atualização de estoque em tempo real
      this.stockGateway.broadcastProductStockUpdate(
        productId,
        nextStock,
        product.name,
      );
    }

    // Tenta registrar movimentação se a tabela existir; se não existir, segue sem bloquear o fluxo.
    for (const productId of productIds) {
      const product = productsById.get(productId);
      const requested = requestedByProduct[productId];
      const currentStock = Number(product.stock_quantity || 0);
      const nextStock = currentStock - requested;

      const { error: movementError } = await supabase
        .from('stock_movements')
        .insert({
          id: uuidv4(),
          order_id: orderId,
          product_id: productId,
          movement_type: 'sale',
          quantity: requested,
          stock_before: currentStock,
          stock_after: nextStock,
          reason,
          created_at: new Date().toISOString(),
        });

      if (movementError && !this.isTableMissingError(movementError, 'stock_movements')) {
        throw new BadRequestException(movementError.message);
      }
    }
  }

  private async validateStockAvailability(supabase: any, items: CreateOrderDto['items']) {
    const requestedQuantities = items.reduce((acc, item) => {
      acc[item.product_id] = (acc[item.product_id] || 0) + item.quantity;
      return acc;
    }, {} as Record<string, number>);

    const productIds = Object.keys(requestedQuantities);
    if (productIds.length === 0) {
      throw new BadRequestException('O pedido precisa ter ao menos um item');
    }

    const { data: products, error } = await supabase
      .from('products')
      .select('id, name, stock_quantity, price, cost_price')
      .in('id', productIds);

    if (error) throw new BadRequestException(error.message);

    const productsById = new Map<string, any>(
      (products || []).map((product: any) => [product.id, product]),
    );

    for (const productId of productIds) {
      const product = productsById.get(productId);
      if (!product) {
        throw new BadRequestException(`Produto não encontrado: ${productId}`);
      }

      const requestedQuantity = requestedQuantities[productId];
      const availableQuantity = Number(product.stock_quantity || 0);

      if (requestedQuantity > availableQuantity) {
        throw new BadRequestException(
          `Estoque insuficiente para ${product.name}. Disponível: ${availableQuantity}, solicitado: ${requestedQuantity}`,
        );
      }
    }

    return { productsById, requestedQuantities };
  }

  private async applyStockDeduction(orderId: string, reason: string) {
    const supabase = this.supabaseService.getClient();
    const { error } = await supabase.rpc('apply_order_stock_deduction', {
      p_order_id: orderId,
      p_reason: reason,
    });

    if (error) {
      if (this.isFunctionMissingError(error)) {
        await this.applyStockDeductionFallback(orderId, reason);
        return;
      }

      throw new BadRequestException(error.message);
    }

    // Se a função RPC foi bem-sucedida, buscar e fazer broadcast dos produtos atualizados
    await this.broadcastUpdatedStock(supabase, orderId);
  }

  private async broadcastUpdatedStock(supabase: any, orderId: string) {
    // Buscar os itens do pedido com dados do produto
    const { data: orderItems, error: itemsError } = await supabase
      .from('order_items')
      .select('product_id, products(id, name, stock_quantity)')
      .eq('order_id', orderId);

    if (itemsError || !orderItems) {
      return;
    }

    // Fazer broadcast para cada produto
    (orderItems as any[]).forEach((item: any) => {
      const product = item.products as any;
      if (product) {
        this.stockGateway.broadcastProductStockUpdate(
          product.id,
          product.stock_quantity,
          product.name,
        );
      }
    });
  }

  private async updateDailySalesSnapshot(orderData: any) {
    const supabase = this.supabaseService.getClient();
    const snapshotDate = new Date().toISOString().slice(0, 10);

    const orderItems = orderData?.order_items || [];
    const totalRevenue = Number(orderData?.total_amount || 0);
    const totalCost = orderItems.reduce((sum: number, item: any) => {
      const costPrice = Number(item?.products?.cost_price || 0);
      return sum + costPrice * Number(item?.quantity || 0);
    }, 0);
    const totalProfit = totalRevenue - totalCost;
    const averageTicket = totalRevenue;

    const { data: existingSnapshot, error: snapshotError } = await supabase
      .from('daily_sales_snapshots')
      .select('*')
      .eq('snapshot_date', snapshotDate)
      .maybeSingle();

    if (snapshotError) {
      if (this.isTableMissingError(snapshotError, 'daily_sales_snapshots')) {
        return;
      }
      throw new BadRequestException(snapshotError.message);
    }

    const nextValues = existingSnapshot
      ? {
          snapshot_date: snapshotDate,
          total_orders: Number(existingSnapshot.total_orders || 0) + 1,
          total_revenue: Number(existingSnapshot.total_revenue || 0) + totalRevenue,
          total_cost: Number(existingSnapshot.total_cost || 0) + totalCost,
          total_profit: Number(existingSnapshot.total_profit || 0) + totalProfit,
          completed_payments: Number(existingSnapshot.completed_payments || 0) + 1,
          average_ticket:
            (Number(existingSnapshot.total_revenue || 0) + totalRevenue) /
            (Number(existingSnapshot.total_orders || 0) + 1),
          updated_at: new Date().toISOString(),
        }
      : {
          snapshot_date: snapshotDate,
          total_orders: 1,
          total_revenue: totalRevenue,
          total_cost: totalCost,
          total_profit: totalProfit,
          completed_payments: 1,
          average_ticket: averageTicket,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        };

    const payload = existingSnapshot
      ? nextValues
      : {
          id: uuidv4(),
          ...nextValues,
        };

    const { error: upsertError } = await supabase
      .from('daily_sales_snapshots')
      .upsert(payload as any, { onConflict: 'snapshot_date' });

    if (upsertError) {
      if (this.isTableMissingError(upsertError, 'daily_sales_snapshots')) {
        return;
      }
      throw new BadRequestException(upsertError.message);
    }

    // Broadcast atualização de vendas em tempo real para admin dashboard
    this.ordersGateway.broadcastSalesSnapshot(nextValues);
  }

  async createOrder(userId: string, createOrderDto: CreateOrderDto) {
    const supabase = this.supabaseService.getClient();
    const orderId = uuidv4();
    const now = new Date().toISOString();

    try {
      await this.validateStockAvailability(supabase, createOrderDto.items);

      // Criar pedido
      const { data: orderData, error: orderError } = await supabase
        .from('orders')
        .insert({
          id: orderId,
          user_id: userId,
          status: 'pending',
          total_amount: createOrderDto.total_amount,
          created_at: now,
          updated_at: now,
        })
        .select();

      if (orderError) throw orderError;

      // Criar itens do pedido
      const orderItems = createOrderDto.items.map((item) => ({
        id: uuidv4(),
        order_id: orderId,
        product_id: item.product_id,
        quantity: item.quantity,
        unit_price: item.unit_price,
        observation: item.observation || null,
        created_at: now,
      }));

      const { error: itemsError } = await supabase
        .from('order_items')
        .insert(orderItems);

      if (itemsError) throw itemsError;

      // Criar registro de pagamento
      const { error: paymentError } = await supabase
        .from('payments')
        .insert({
          id: uuidv4(),
          order_id: orderId,
          amount: createOrderDto.total_amount,
          status: 'pending',
          payment_method: 'simulated',
          created_at: now,
          updated_at: now,
        });

      if (paymentError) throw paymentError;

      // Criar rastreamento inicial
      const { error: trackingError } = await supabase
        .from('order_tracking')
        .insert({
          id: uuidv4(),
          order_id: orderId,
          status: 'pending',
          message: 'Pedido criado com sucesso',
          created_at: now,
        });

      if (trackingError) throw trackingError;

      return this.getOrderById(orderId);
    } catch (error) {
      throw error;
    }
  }

  async simulatePayment(orderId: string, userId: string) {
    const supabase = this.supabaseService.getClient();
    const now = new Date().toISOString();

    try {
      // Verificar se o pedido pertence ao usuário
      const { data: order, error: orderError } = await supabase
        .from('orders')
        .select('*, order_items(*, products(*))')
        .eq('id', orderId)
        .eq('user_id', userId)
        .single();

      if (orderError || !order) {
        throw new Error('Pedido não encontrado');
      }

      if (['confirmed', 'completed'].includes(order.status)) {
        return this.getOrderById(orderId);
      }

      const { data: payment, error: paymentFetchError } = await supabase
        .from('payments')
        .select('*')
        .eq('order_id', orderId)
        .single();

      if (paymentFetchError) {
        throw paymentFetchError;
      }

      if (payment?.status === 'completed' && ['confirmed', 'completed'].includes(order.status)) {
        return this.getOrderById(orderId);
      }

      await this.applyStockDeduction(orderId, 'payment_completed');

      // Atualizar status do pagamento
      const transactionId = `TXN-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      const receiptNumber = `RCP-${uuidv4().slice(0, 8).toUpperCase()}`;

      const { error: paymentError } = await supabase
        .from('payments')
        .update({
          status: 'completed',
          transaction_id: transactionId,
          receipt_number: receiptNumber,
          paid_at: now,
          updated_at: now,
        })
        .eq('order_id', orderId);

      if (paymentError) throw paymentError;

      // Atualizar status do pedido
      const orderUpdatePayload: Record<string, any> = {
        status: 'confirmed',
        updated_at: now,
      };

      if (['confirmed', 'completed'].includes(order.status) || payment?.status === 'completed') {
        orderUpdatePayload.stock_deducted_at = now;
      }

      const { error: updateError } = await supabase
        .from('orders')
        .update(orderUpdatePayload)
        .eq('id', orderId);

      if (updateError) throw updateError;

      // Broadcast atualização de status do pedido em tempo real
      this.ordersGateway.broadcastOrderStatusUpdate(orderId, 'confirmed', userId);
      this.ordersGateway.broadcastAdminOrderUpdate(orderId, {
        status: 'confirmed',
        userId,
      });

      // Adicionar rastreamento
      const { error: trackingError } = await supabase
        .from('order_tracking')
        .insert({
          id: uuidv4(),
          order_id: orderId,
          status: 'confirmed',
          message: `Pagamento confirmado. Comprovante: ${receiptNumber}`,
          created_at: now,
        });

      if (trackingError) throw trackingError;

      await this.updateDailySalesSnapshot(order);

      return this.getOrderById(orderId);
    } catch (error) {
      throw error;
    }
  }

  async getUserOrders(userId: string) {
    const supabase = this.supabaseService.getClient();

    try {
      const { data, error } = await supabase
        .from('orders')
        .select(
          `
          *,
          order_items(*, products(*)),
          payments(*),
          order_tracking(*)
        `
        )
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      // Attach basic user info to each order (name/email) using admin API
      try {
        const augmented = await Promise.all((data as any[]).map(async (order) => {
          try {
            const userRes = await supabase.auth.admin.getUserById(order.user_id);
            const user = (userRes as any)?.data?.user || null;
            order.user = user ? { id: user.id, email: user.email, name: user.user_metadata?.name || null } : null;
          } catch (e) {
            order.user = null;
          }
          return order;
        }));
        return augmented;
      } catch (e) {
        return data;
      }
    } catch (error) {
      throw error;
    }
  }

  async getAllOrders() {
    const supabase = this.supabaseService.getClient();

    try {
      const { data, error } = await supabase
        .from('orders')
        .select(
          `
          *,
          order_items(*, products(*)),
          payments(*),
          order_tracking(*)
        `
        )
        .order('created_at', { ascending: false });

      if (error) throw error;
      // Attach basic user info to each order (name/email)
      try {
        const augmented = await Promise.all((data as any[]).map(async (order) => {
          try {
            const userRes = await supabase.auth.admin.getUserById(order.user_id);
            const user = (userRes as any)?.data?.user || null;
            order.user = user ? { id: user.id, email: user.email, name: user.user_metadata?.name || null } : null;
          } catch (e) {
            order.user = null;
          }
          return order;
        }));
        return augmented;
      } catch (e) {
        return data;
      }
    } catch (error) {
      throw error;
    }
  }

  async getOrderById(orderId: string) {
    const supabase = this.supabaseService.getClient();

    try {
      const { data, error } = await supabase
        .from('orders')
        .select(
          `
          *,
          order_items(*, products(*)),
          payments(*),
          order_tracking(*)
        `
        )
        .eq('id', orderId)
        .single();

      if (error) throw error;
      try {
        const userRes = await supabase.auth.admin.getUserById(data.user_id);
        const user = (userRes as any)?.data?.user || null;
        data.user = user ? { id: user.id, email: user.email, name: user.user_metadata?.name || null } : null;
      } catch (e) {
        data.user = null;
      }
      return data;
    } catch (error) {
      throw error;
    }
  }

  async updateOrderStatus(orderId: string, status: string, message: string) {
    const supabase = this.supabaseService.getClient();
    const now = new Date().toISOString();

    try {
      const shouldDeductStock = ['confirmed', 'completed'].includes(status);

      if (shouldDeductStock) {
        const { data: order, error: orderError } = await supabase
          .from('orders')
          .select('id, status, total_amount, order_items(*, products(*))')
          .eq('id', orderId)
          .single();

        if (orderError || !order) {
          throw new BadRequestException('Pedido não encontrado');
        }

        await this.applyStockDeduction(orderId, `status_${status}`);
        await this.updateDailySalesSnapshot(order);
      }

      const updatePayload: Record<string, any> = {
        status: status,
        updated_at: now,
      };

      if (shouldDeductStock) {
        updatePayload.stock_deducted_at = now;
      }

      const { error: updateError } = await supabase
        .from('orders')
        .update(updatePayload)
        .eq('id', orderId);

      if (updateError) throw updateError;

      const { error: trackingError } = await supabase
        .from('order_tracking')
        .insert({
          id: uuidv4(),
          order_id: orderId,
          status: status,
          message: message,
          created_at: now,
        });

      if (trackingError) throw trackingError;

      return this.getOrderById(orderId);
    } catch (error) {
      throw error;
    }
  }
}
