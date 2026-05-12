import 'product_model.dart';

/// Modelo ideal para um item do carrinho, considerando um app de doces/salgados
class CartItem {
  final String id;
  final Product product;
  int quantity;
  String observation;
  final DateTime addedAt;

  // Exemplo: para combos ou adicionais no futuro
  final List<Product>? additions;

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.observation = '',
    DateTime? addedAt,
    this.additions,
  }) : addedAt = addedAt ?? DateTime.now();

  double get totalPrice {
    double total = product.price * quantity;
    if (additions != null) {
      for (final add in additions!) {
        total += add.price;
      }
    }
    return total;
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    String? observation,
    DateTime? addedAt,
    List<Product>? additions,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      observation: observation ?? this.observation,
      addedAt: addedAt ?? this.addedAt,
      additions: additions ?? this.additions,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      product: Product.fromJson(Map<String, dynamic>.from(json['product'] ?? {})),
      quantity: json['quantity'] as int,
      observation: json['observation'] as String? ?? '',
      addedAt: DateTime.tryParse(json['addedAt'] ?? '') ?? DateTime.now(),
      additions: json['additions'] != null
          ? (json['additions'] as List)
              .map((e) => Product.fromJson(Map<String, dynamic>.from(e ?? {})))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'ingredients': product.ingredients,
        'price': product.price,
        'costPrice': product.costPrice,
        'images': product.images,
        'categoryId': product.categoryId,
        'subcategoryId': product.subcategoryId,
        'availableDays': product.availableDays,
        'stockQuantity': product.stockQuantity,
      },
      'quantity': quantity,
      'observation': observation,
      'addedAt': addedAt.toIso8601String(),
      'additions': additions?.map((e) => {
            'id': e.id,
            'name': e.name,
            'description': e.description,
            'ingredients': e.ingredients,
            'price': e.price,
            'costPrice': e.costPrice,
            'images': e.images,
            'categoryId': e.categoryId,
            'subcategoryId': e.subcategoryId,
            'availableDays': e.availableDays,
            'stockQuantity': e.stockQuantity,
          }).toList(),
    };
  }
}
