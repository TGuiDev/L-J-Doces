import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { ProductsService } from './products.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  async getProducts() {
    return this.productsService.getProducts();
  }

  @Get('category/:categoryId')
  async getProductsByCategory(@Param('categoryId') categoryId: string) {
    return this.productsService.getProductsByCategory(categoryId);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  async createProduct(@Body() body: any) {
    return this.productsService.createProduct(body);
  }

  @UseGuards(JwtAuthGuard)
  @Put(':id')
  async updateProduct(@Param('id') id: string, @Body() body: any) {
    return this.productsService.updateProduct(id, body);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  async deleteProduct(@Param('id') id: string) {
    return this.productsService.deleteProduct(id);
  }
}
