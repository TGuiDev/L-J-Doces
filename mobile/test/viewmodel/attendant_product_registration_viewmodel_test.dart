import 'package:flutter_test/flutter_test.dart';
import 'package:lejdoces/models/product_model.dart';
import 'package:lejdoces/viewmodel/attendant_product_registration_viewmodel.dart';

void main() {
  group('AttendantProductRegistrationViewModel', () {
    test('rejeita formulario invalido sem chamar o gateway', () async {
      final gateway = _FakeProductRegistrationGateway();
      final viewModel = AttendantProductRegistrationViewModel(
        gateway: gateway,
      );

      final result = await viewModel.register(
        const AttendantProductRegistrationForm(
          name: '',
          description: 'Brigadeiro tradicional',
          ingredients: 'Chocolate, leite condensado',
          price: '8,50',
          costPrice: '3,20',
          images: [],
          categoryId: 'doces',
          stockQuantity: '10',
        ),
      );

      expect(result, isFalse);
      expect(gateway.createdProducts, isEmpty);
      expect(viewModel.errorMessage, 'Informe o nome do produto.');
    });

    test('cadastra produto valido com dados normalizados', () async {
      final gateway = _FakeProductRegistrationGateway();
      final viewModel = AttendantProductRegistrationViewModel(
        gateway: gateway,
      );

      final result = await viewModel.register(
        const AttendantProductRegistrationForm(
          name: '  Bolo de Pote  ',
          description: '  Massa de chocolate  ',
          ingredients: 'Chocolate, creme',
          price: '12,90',
          costPrice: '5.50',
          images: [' https://cdn.test/bolo.png ', ''],
          categoryId: ' bolos ',
          subcategoryId: ' pote ',
          availableDays: {1: true, 2: false, 6: true},
          stockQuantity: '15',
        ),
      );

      expect(result, isTrue);
      expect(viewModel.errorMessage, isNull);
      expect(gateway.createdProducts, hasLength(1));

      final product = gateway.createdProducts.single;
      expect(product.id, isEmpty);
      expect(product.name, 'Bolo de Pote');
      expect(product.description, 'Massa de chocolate');
      expect(product.price, 12.90);
      expect(product.costPrice, 5.50);
      expect(product.images, ['https://cdn.test/bolo.png']);
      expect(product.categoryId, 'bolos');
      expect(product.subcategoryId, 'pote');
      expect(product.availableDays, {1: true, 2: false, 6: true});
      expect(product.stockQuantity, 15);
      expect(viewModel.lastRegisteredProduct, product);
      expect(viewModel.isSubmitting, isFalse);
    });

    test('informa erro quando o gateway falha', () async {
      final gateway = _FakeProductRegistrationGateway(shouldFail: true);
      final viewModel = AttendantProductRegistrationViewModel(
        gateway: gateway,
      );

      final result = await viewModel.register(
        const AttendantProductRegistrationForm(
          name: 'Trufa',
          description: 'Trufa de chocolate',
          ingredients: 'Chocolate',
          price: '7.00',
          costPrice: '2.00',
          images: [],
          categoryId: 'doces',
          stockQuantity: '20',
        ),
      );

      expect(result, isFalse);
      expect(viewModel.errorMessage, 'Nao foi possivel cadastrar o produto.');
      expect(viewModel.isSubmitting, isFalse);
      expect(gateway.createdProducts, hasLength(1));
    });
  });
}

class _FakeProductRegistrationGateway
    implements AttendantProductRegistrationGateway {
  final bool shouldFail;
  final List<Product> createdProducts = [];

  _FakeProductRegistrationGateway({this.shouldFail = false});

  @override
  Future<void> createProduct(Product product) async {
    createdProducts.add(product);

    if (shouldFail) {
      throw Exception('Falha simulada');
    }
  }
}
