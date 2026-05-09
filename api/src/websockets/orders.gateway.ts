import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: true,
  },
  namespace: 'orders',
})
export class OrdersGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;
  private logger = new Logger('OrdersGateway');

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  /**
   * Subscribe a um pedido específico para atualizações
   * Util para "Minhas compras" e "Gerenciar pedidos"
   */
  subscribeToOrder(client: Socket, data: { orderId: string }) {
    const room = `order:${data.orderId}`;
    client.join(room);
    this.logger.debug(`Client ${client.id} subscribed to ${room}`);
  }

  /**
   * Unsubscribe de um pedido
   */
  unsubscribeFromOrder(client: Socket, data: { orderId: string }) {
    const room = `order:${data.orderId}`;
    client.leave(room);
    this.logger.debug(`Client ${client.id} unsubscribed from ${room}`);
  }

  /**
   * Broadcast de mudança de status de pedido
   * Emitido quando status muda: pending -> confirmed -> completed
   */
  broadcastOrderStatusUpdate(
    orderId: string,
    newStatus: string,
    userId?: string,
  ) {
    // Emit para o pedido específico
    const room = `order:${orderId}`;
    this.server.to(room).emit('order:status:updated', {
      orderId,
      newStatus,
      timestamp: new Date().toISOString(),
    });

    // Se houver userId, também emit para o admin listening todos os pedidos do usuário
    if (userId) {
      const userRoom = `user-orders:${userId}`;
      this.server.to(userRoom).emit('order:status:updated', {
        orderId,
        newStatus,
        userId,
        timestamp: new Date().toISOString(),
      });
    }

    this.logger.debug(`Order ${orderId} status updated to: ${newStatus}`);
  }

  /**
   * Broadcast para "Gerenciar pedidos" (admin)
   * Todos os pedidos da loja
   */
  broadcastAdminOrderUpdate(orderId: string, orderData: any) {
    this.server.emit('admin:order:updated', {
      orderId,
      ...orderData,
      timestamp: new Date().toISOString(),
    });
    this.logger.debug(`Admin notified of order update: ${orderId}`);
  }

  /**
   * Subscribe a todos os pedidos do usuário
   * Para sincronizar "Minhas compras"
   */
  subscribeToUserOrders(client: Socket, data: { userId: string }) {
    const room = `user-orders:${data.userId}`;
    client.join(room);
    this.logger.debug(`Client ${client.id} subscribed to user orders: ${room}`);
  }

  /**
   * Subscribe a todos os pedidos (admin)
   * Para sincronizar "Gerenciar pedidos" e "Vendas"
   */
  subscribeToAllOrders(client: Socket) {
    const room = 'admin:all-orders';
    client.join(room);
    this.logger.debug(`Client ${client.id} subscribed to all orders`);
  }

  /**
   * Broadcast para novos pedidos (admin dashboard)
   */
  broadcastNewOrder(orderId: string, orderData: any) {
    this.server.emit('admin:order:created', {
      orderId,
      ...orderData,
      timestamp: new Date().toISOString(),
    });
    this.logger.debug(`Admin notified of new order: ${orderId}`);
  }

  /**
   * Broadcast para atualizar vendas totais (dashboard admin)
   */
  broadcastSalesSnapshot(snapshot: any) {
    this.server.emit('admin:sales:updated', {
      ...snapshot,
      timestamp: new Date().toISOString(),
    });
    this.logger.debug(`Sales snapshot updated`);
  }
}
