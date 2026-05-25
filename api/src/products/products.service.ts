import { Injectable, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class ProductsService {
  constructor(private supabase: SupabaseService) {}

  private readonly productSelect =
    'id, name, description, ingredients, price, cost_price, images, category_id, subcategory_id, available_days, stock_quantity, created_at, category:categories(id, name), subcategory:subcategories(id, name)';

  async getProducts() {
    const client = this.supabase.getClient();
    const { data, error } = await client
      .from('products')
      .select(this.productSelect);
    if (error) throw new BadRequestException(error.message);
    return data;
  }

  async getTopOrderedProducts(limit = 10) {
    const client = this.supabase.getClient();
    const completedStatuses = ['confirmed', 'delivered', 'completed'];

    const { data: orders, error: ordersError } = await client
      .from('orders')
      .select('id')
      .in('status', completedStatuses);

    if (ordersError) throw new BadRequestException(ordersError.message);
    if (!orders?.length) return [];

    const orderIds = orders.map((order) => order.id);
    const { data: orderItems, error: orderItemsError } = await client
      .from('order_items')
      .select('product_id, quantity')
      .in('order_id', orderIds);

    if (orderItemsError) throw new BadRequestException(orderItemsError.message);
    if (!orderItems?.length) return [];

    const quantityByProduct = new Map<string, number>();
    for (const item of orderItems) {
      const productId = item.product_id;
      const quantity = Number(item.quantity || 0);
      quantityByProduct.set(
        productId,
        (quantityByProduct.get(productId) || 0) + quantity,
      );
    }

    const rankedProductIds = Array.from(quantityByProduct.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit)
      .map(([productId]) => productId);

    if (!rankedProductIds.length) return [];

    const { data: products, error: productsError } = await client
      .from('products')
      .select(this.productSelect)
      .in('id', rankedProductIds);

    if (productsError) throw new BadRequestException(productsError.message);

    const productsById = new Map((products || []).map((product) => [product.id, product]));

    return rankedProductIds
      .map((productId) => productsById.get(productId))
      .filter(Boolean);
  }

  async getProductsByCategory(categoryId: string) {
    const client = this.supabase.getClient();
    const { data, error } = await client
      .from('products')
      .select(this.productSelect)
      .eq('category_id', categoryId);
    if (error) throw new BadRequestException(error.message);
    return data;
  }

  async getProductById(id: string) {
    const client = this.supabase.getClient();
    const { data, error } = await client
      .from('products')
      .select(this.productSelect)
      .eq('id', id)
      .single();

    if (error) throw new BadRequestException(error.message);
    return data;
  }

  async createProduct(data: any) {
    const client = this.supabase.getClient();
    const { data: result, error } = await client
      .from('products')
      .insert([data])
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);
    return result;
  }

  async updateProduct(id: string, data: any) {
    const client = this.supabase.getClient();
    const { data: result, error } = await client
      .from('products')
      .update(data)
      .eq('id', id)
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);
    return result;
  }

  async deleteProduct(id: string) {
    const client = this.supabase.getClient();
    const { error } = await client.from('products').delete().eq('id', id);
    if (error) throw new BadRequestException(error.message);
    return { success: true };
  }
}
