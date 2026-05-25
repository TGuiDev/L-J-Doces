import 'package:flutter/foundation.dart';

import '../models/product_model.dart';

abstract class AttendantProductRegistrationGateway {
  Future<void> createProduct(Product product);
}

class AttendantProductRegistrationForm {
  final String name;
  final String description;
  final String ingredients;
  final String price;
  final String costPrice;
  final List<String> images;
  final String categoryId;
  final String? subcategoryId;
  final Map<int, bool> availableDays;
  final String stockQuantity;

  const AttendantProductRegistrationForm({
    required this.name,
    required this.description,
    required this.ingredients,
    required this.price,
    required this.costPrice,
    required this.images,
    required this.categoryId,
    this.subcategoryId,
    this.availableDays = const {},
    required this.stockQuantity,
  });

  Product toProduct() {
    return Product(
      id: '',
      name: name.trim(),
      description: description.trim(),
      ingredients: ingredients.trim(),
      price: _parseMoney(price),
      costPrice: _parseMoney(costPrice),
      images: images.map((image) => image.trim()).where((image) {
        return image.isNotEmpty;
      }).toList(),
      categoryId: categoryId.trim(),
      subcategoryId:
          subcategoryId == null || subcategoryId!.trim().isEmpty
              ? null
              : subcategoryId!.trim(),
      availableDays: availableDays,
      stockQuantity: _parseStock(stockQuantity),
    );
  }

  static double _parseMoney(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  static int _parseStock(String value) {
    return int.tryParse(value.trim()) ?? -1;
  }
}

class AttendantProductRegistrationViewModel extends ChangeNotifier {
  final AttendantProductRegistrationGateway _gateway;

  bool _isSubmitting = false;
  String? _errorMessage;
  Product? _lastRegisteredProduct;

  AttendantProductRegistrationViewModel({
    required AttendantProductRegistrationGateway gateway,
  }) : _gateway = gateway;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  Product? get lastRegisteredProduct => _lastRegisteredProduct;

  Future<bool> register(AttendantProductRegistrationForm form) async {
    final validationError = validate(form);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = form.toProduct();
      await _gateway.createProduct(product);
      _lastRegisteredProduct = product;
      return true;
    } catch (_) {
      _errorMessage = 'Nao foi possivel cadastrar o produto.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String? validate(AttendantProductRegistrationForm form) {
    final product = form.toProduct();

    if (product.name.isEmpty) {
      return 'Informe o nome do produto.';
    }

    if (product.categoryId.isEmpty) {
      return 'Selecione uma categoria.';
    }

    if (product.price <= 0) {
      return 'Informe um preco de venda maior que zero.';
    }

    if (product.costPrice < 0) {
      return 'Informe um preco de custo valido.';
    }

    if (product.stockQuantity < 0) {
      return 'Informe uma quantidade de estoque valida.';
    }

    if (product.images.length > 5) {
      return 'Informe no maximo 5 imagens.';
    }

    return null;
  }
}
