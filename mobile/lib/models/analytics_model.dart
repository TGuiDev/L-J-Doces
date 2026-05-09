// Model para resposta Analytics + Gemini safe parsing

class OperationalSummary {
  final bool success;
  final String summary;
  final Map<String, dynamic> rawData;

  OperationalSummary({
    required this.success,
    required this.summary,
    required this.rawData,
  });

  factory OperationalSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return OperationalSummary(
      success: json['success'] ?? false,

      // Gemini pode retornar null
      summary:
          json['summary']?.toString() ??
          'Sem dados',

      rawData:
          Map<String, dynamic>.from(
            json['rawData'] ?? {},
          ),
    );
  }
}

class SalesAnalytics {
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final Map<String, int> ordersByStatus;

  SalesAnalytics({
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.ordersByStatus,
  });

  factory SalesAnalytics.fromJson(
    Map<String, dynamic> json,
  ) {
    return SalesAnalytics(
      totalOrders:
          (json['totalOrders'] ?? 0) as int,

      totalRevenue:
          _toDouble(json['totalRevenue']),

      averageOrderValue:
          _toDouble(
            json['averageOrderValue'],
          ),

      ordersByStatus:
          Map<String, int>.from(
            json['ordersByStatus'] ?? {},
          ),
    );
  }
}

class ProductAnalytics {
  final List<TopProduct> topProducts;

  final List<LowStockProduct>
      lowStockProducts;

  final int totalInCatalog;

  ProductAnalytics({
    required this.topProducts,
    required this.lowStockProducts,
    required this.totalInCatalog,
  });

  factory ProductAnalytics.fromJson(
    Map<String, dynamic> json,
  ) {
    final topList =
        (json['topProducts'] as List?)
            ?.map(
              (p) => TopProduct.fromJson(p),
            )
            .toList() ??
        [];

    final lowList =
        (json['lowStockProducts'] as List?)
            ?.map(
              (p) =>
                  LowStockProduct.fromJson(p),
            )
            .toList() ??
        [];

    return ProductAnalytics(
      topProducts: topList,

      lowStockProducts: lowList,

      totalInCatalog:
          json['totalInCatalog'] ?? 0,
    );
  }
}

class TopProduct {
  final String productId;

  final String productName;

  final int quantity;

  final double revenue;

  final double? profit;

  TopProduct({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.revenue,
    this.profit,
  });

  factory TopProduct.fromJson(
    Map<String, dynamic> json,
  ) {
    return TopProduct(
      productId:
          json['productId']?.toString() ??
          '',

      productName:
          json['productName']
              ?.toString() ??
          'Desconhecido',

      quantity:
          (json['quantity'] ?? 0) as int,

      revenue:
          _toDouble(json['revenue']),

      profit:
          json['profit'] != null
              ? _toDouble(json['profit'])
              : null,
    );
  }
}

class LowStockProduct {
  final String id;

  final String name;

  final int stockQuantity;

  final double price;

  LowStockProduct({
    required this.id,
    required this.name,
    required this.stockQuantity,
    required this.price,
  });

  factory LowStockProduct.fromJson(
    Map<String, dynamic> json,
  ) {
    return LowStockProduct(
      id: json['id']?.toString() ?? '',

      name:
          json['name']?.toString() ??
          'Desconhecido',

      stockQuantity:
          json['stock_quantity'] ?? 0,

      price:
          _toDouble(json['price']),
    );
  }
}

class ProfitabilityAnalytics {
  final double totalRevenue;

  final double totalCost;

  final double profit;

  final String marginPercentage;

  final bool hasLosses;

  ProfitabilityAnalytics({
    required this.totalRevenue,
    required this.totalCost,
    required this.profit,
    required this.marginPercentage,
    required this.hasLosses,
  });

  factory ProfitabilityAnalytics.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProfitabilityAnalytics(
      totalRevenue:
          _toDouble(json['totalRevenue']),

      totalCost:
          _toDouble(json['totalCost']),

      profit:
          _toDouble(json['profit']),

      marginPercentage:
          json['marginPercentage']
              ?.toString() ??
          '0',

      hasLosses:
          json['hasLosses'] ?? false,
    );
  }
}

class PaymentAnalytics {
  final int totalPayments;

  final int completedPayments;

  final String paymentRate;

  final double totalCompletedAmount;

  PaymentAnalytics({
    required this.totalPayments,
    required this.completedPayments,
    required this.paymentRate,
    required this.totalCompletedAmount,
  });

  factory PaymentAnalytics.fromJson(
    Map<String, dynamic> json,
  ) {
    return PaymentAnalytics(
      totalPayments:
          json['totalPayments'] ?? 0,

      completedPayments:
          json['completedPayments'] ?? 0,

      paymentRate:
          json['paymentRate']
              ?.toString() ??
          '0',

      totalCompletedAmount:
          _toDouble(
            json['totalCompletedAmount'],
          ),
    );
  }
}

class TemporalAnalytics {
  final Map<String, int>
      salesByDayOfWeek;

  final Map<String, double>
      revenueByDayOfWeek;

  final List<dynamic>? peakDay;

  TemporalAnalytics({
    required this.salesByDayOfWeek,
    required this.revenueByDayOfWeek,
    this.peakDay,
  });

  factory TemporalAnalytics.fromJson(
    Map<String, dynamic> json,
  ) {
    return TemporalAnalytics(
      salesByDayOfWeek:
          Map<String, int>.from(
            json['salesByDayOfWeek'] ??
                {},
          ),

      revenueByDayOfWeek:
          Map<String, double>.from(
            (json['revenueByDayOfWeek']
                        as Map?)
                    ?.map(
                      (k, v) => MapEntry(
                        k.toString(),
                        _toDouble(v),
                      ),
                    ) ??
                {},
          ),

      peakDay: json['peakDay'],
    );
  }
}

// ===============================
// HELPERS
// ===============================

double _toDouble(dynamic value) {
  if (value == null) return 0;

  if (value is double) return value;

  if (value is int) return value.toDouble();

  if (value is String) {
    return double.tryParse(value) ?? 0;
  }

  return 0;
}