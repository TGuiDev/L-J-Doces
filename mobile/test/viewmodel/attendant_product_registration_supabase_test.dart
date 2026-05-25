import 'package:flutter_test/flutter_test.dart';
import 'package:lejdoces/models/product_model.dart';
import 'package:lejdoces/viewmodel/attendant_product_registration_supabase.dart';

void main() {
  group('AttendantProductRegistrationSupabaseMapper', () {
    test('gera payload em snake_case para cadastro de produto', () {
      final product = Product(
        id: '',
        name: 'Brownie',
        description: 'Brownie recheado',
        ingredients: 'Chocolate, farinha, ovos',
        price: 14.90,
        costPrice: 6.25,
        images: ['https://cdn.test/brownie.png'],
        categoryId: 'cat-doces',
        subcategoryId: 'sub-brownies',
        availableDays: const {0: true, 1: false, 5: true},
        stockQuantity: 30,
      );

      final payload =
          AttendantProductRegistrationSupabaseMapper.toInsertPayload(product);

      expect(payload, {
        'name': 'Brownie',
        'description': 'Brownie recheado',
        'ingredients': 'Chocolate, farinha, ovos',
        'price': 14.90,
        'cost_price': 6.25,
        'images': ['https://cdn.test/brownie.png'],
        'category_id': 'cat-doces',
        'subcategory_id': 'sub-brownies',
        'available_days': {'0': true, '1': false, '5': true},
        'stock_quantity': 30,
      });
    });

    test('mantem subcategoria nula quando produto nao possui subcategoria', () {
      final product = Product(
        id: '',
        name: 'Brigadeiro',
        description: 'Brigadeiro tradicional',
        ingredients: 'Chocolate, leite condensado',
        price: 5,
        costPrice: 2,
        images: const [],
        categoryId: 'cat-doces',
        subcategoryId: null,
        availableDays: const {},
        stockQuantity: 100,
      );

      final payload =
          AttendantProductRegistrationSupabaseMapper.toInsertPayload(product);

      expect(payload['subcategory_id'], isNull);
      expect(payload['available_days'], isEmpty);
    });
  });
}
