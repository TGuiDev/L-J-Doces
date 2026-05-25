import '../models/product_model.dart';

class AttendantProductRegistrationSupabaseMapper {
  const AttendantProductRegistrationSupabaseMapper._();

  static Map<String, dynamic> toInsertPayload(Product product) {
    return {
      'name': product.name,
      'description': product.description,
      'ingredients': product.ingredients,
      'price': product.price,
      'cost_price': product.costPrice,
      'images': product.images,
      'category_id': product.categoryId,
      'subcategory_id': product.subcategoryId,
      'available_days': {
        for (final entry in product.availableDays.entries)
          entry.key.toString(): entry.value,
      },
      'stock_quantity': product.stockQuantity,
    };
  }
}
