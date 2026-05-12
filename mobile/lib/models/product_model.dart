class Product {
  final String id;
  final String name;
  final String description;
  final String ingredients;
  final double price;
  final double costPrice;
  final List<String> images; // max 5
  final String categoryId;
  final String? subcategoryId;
  final Map<int, bool> availableDays; // 0=Sunday, 1=Monday... 6=Saturday
  final int stockQuantity;

  bool get isAvailableToday {
    // Se availableDays estiver vazio, considera disponível (padrão = todos os dias)
    if (availableDays.isEmpty) return true;

    final now = DateTime.now();
    final todayIndex =
        now.weekday % 7; // dart: 1=Mon...7=Sun -> map: 0=Sun, 1=Mon
    return availableDays[todayIndex] == true;
  }

  String get availableDaysString {
    // Se vazio, disponível todos os dias
    if (availableDays.isEmpty) return 'Todos os dias';

    const diaNomes = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    List<String> ativos = [];
    for (int i = 0; i < 7; i++) {
      if (availableDays[i] == true) ativos.add(diaNomes[i]);
    }
    return ativos.isNotEmpty ? ativos.join(', ') : 'Indisponível';
  }

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.price,
    required this.costPrice,
    required this.images,
    required this.categoryId,
    this.subcategoryId,
    required this.availableDays,
    required this.stockQuantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      ingredients: json['ingredients']?.toString() ?? '',
      price: _toDouble(json['price']),
      costPrice: _toDouble(json['cost_price'] ?? json['costPrice']),
      images: (json['images'] as List? ?? []).map((image) => image.toString()).toList(),
      categoryId: (json['category_id'] ?? json['categoryId'])?.toString() ?? '',
      subcategoryId: (json['subcategory_id'] ?? json['subcategoryId'])?.toString(),
      availableDays: _availableDaysFromJson(
        json['available_days'] ?? json['availableDays'],
      ),
      stockQuantity: _toInt(json['stock_quantity'] ?? json['stockQuantity']),
    );
  }

  static Map<int, bool> _availableDaysFromJson(dynamic value) {
    if (value is! Map) return {};

    return value.map<int, bool>((key, rawValue) {
      return MapEntry(
        int.tryParse(key.toString()) ?? 0,
        _toBool(rawValue),
      );
    });
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value?.toString().toLowerCase().trim();
    return normalized == 'true' || normalized == '1' || normalized == 'sim';
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
