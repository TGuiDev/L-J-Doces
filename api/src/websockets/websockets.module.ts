import { Module } from '@nestjs/common';
import { StockGateway } from './stock.gateway';
import { OrdersGateway } from './orders.gateway';

@Module({
  providers: [StockGateway, OrdersGateway],
  exports: [StockGateway, OrdersGateway],
})
export class WebSocketsModule {}
