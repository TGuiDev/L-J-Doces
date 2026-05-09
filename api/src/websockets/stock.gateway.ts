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
  namespace: 'stock',
})
export class StockGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;
  private logger = new Logger('StockGateway');

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  /**
   * Broadcast para todos os clientes conectados quando estoque é atualizado
   * @param productId - ID do produto
   * @param newQuantity - Nova quantidade em estoque
   * @param productName - Nome do produto (opcional, para contexto)
   */
  broadcastStockUpdate(
    productId: string,
    newQuantity: number,
    productName?: string,
  ) {
    this.server.emit('stock:updated', {
      productId,
      newQuantity,
      productName,
      timestamp: new Date().toISOString(),
    });
    this.logger.debug(
      `Stock updated: ${productName} (${productId}) - ${newQuantity}`,
    );
  }

  /**
   * Subscribe a um produto específico para atualizações de estoque
   * Cliente emite: subscribe:product { productId }
   */
  subscribeToProduct(client: Socket, data: { productId: string }) {
    const room = `product:${data.productId}`;
    client.join(room);
    this.logger.debug(`Client ${client.id} subscribed to ${room}`);
  }

  /**
   * Unsubscribe de um produto
   * Cliente emite: unsubscribe:product { productId }
   */
  unsubscribeFromProduct(client: Socket, data: { productId: string }) {
    const room = `product:${data.productId}`;
    client.leave(room);
    this.logger.debug(`Client ${client.id} unsubscribed from ${room}`);
  }

  /**
   * Broadcast estoque para produto específico
   * Útil quando múltiplos clientes estão vendo o mesmo produto
   */
  broadcastProductStockUpdate(
    productId: string,
    newQuantity: number,
    productName?: string,
  ) {
    const room = `product:${productId}`;
    this.server.to(room).emit('stock:updated', {
      productId,
      newQuantity,
      productName,
      timestamp: new Date().toISOString(),
    });
    this.logger.debug(
      `Stock updated to room ${room}: ${productName} - ${newQuantity}`,
    );
  }

  /**
   * Broadcast de múltiplos produtos (útil para cart)
   */
  broadcastMultipleStockUpdates(
    updates: Array<{ productId: string; newQuantity: number; productName?: string }>,
  ) {
    updates.forEach((update) => {
      this.broadcastProductStockUpdate(
        update.productId,
        update.newQuantity,
        update.productName,
      );
    });
  }
}
