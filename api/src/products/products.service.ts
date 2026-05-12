import { Injectable, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class ProductsService {
  constructor(private supabase: SupabaseService) {}

  async getProducts() {
    const client = this.supabase.getClient();
    const { data, error } = await client
      .from('products')
      .select(
        `id, name, description, price, images, category_id, subcategory_id, stock_quantity, created_at, category:categories(id, name), subcategory:subcategories(id, name)`
      );
    if (error) throw new BadRequestException(error.message);
    return data;
  }

  async getProductsByCategory(categoryId: string) {
    const client = this.supabase.getClient();
    const { data, error } = await client
      .from('products')
      .select(
        `id, name, description, price, images, category_id, subcategory_id, stock_quantity, created_at, category:categories(id, name), subcategory:subcategories(id, name)`
      )
      .eq('category_id', categoryId);
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
