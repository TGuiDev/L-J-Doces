class Order {
  final String id;
  final String userId;
  final String? customerName;
  final String status; // pending, confirmed, delivered, cancelled
  final double totalAmount;
  final List<OrderItem> items;
  final Payment? payment;
  final List<OrderTracking> tracking;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalAmount,
    required this.items,
    this.payment,
    required this.tracking,
    this.customerName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      customerName: (json['user'] != null && json['user']['name'] != null)
          ? json['user']['name'].toString()
          : (json['user'] != null && json['user']['email'] != null)
              ? json['user']['email'].toString()
              : null,
      status: (json['status'] ?? 'unknown').toString(),
      totalAmount: (() {
        try {
          return double.parse((json['total_amount'] ?? 0).toString());
        } catch (_) {
          return 0.0;
        }
      })(),
      items: (json['order_items'] as List?)
              ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      payment: json['payments'] != null && (json['payments'] as List).isNotEmpty
          ? Payment.fromJson(
              Map<String, dynamic>.from((json['payments'] as List)[0] ?? {}))
          : null,
      tracking: (json['order_tracking'] as List?)
              ?.map((track) =>
                  OrderTracking.fromJson(track as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        if (customerName != null) 'user_name': customerName,
        'status': status,
        'total_amount': totalAmount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final String? observation;
  final DateTime createdAt;
  final Map<String, dynamic>? product; // Product data if available

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.observation,
    required this.createdAt,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: (json['id'] ?? '').toString(),
      orderId: (json['order_id'] ?? '').toString(),
      productId: (json['product_id'] ?? '').toString(),
      quantity: (json['quantity'] ?? 0) is int
          ? (json['quantity'] as int)
          : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      unitPrice: (() {
        try {
          return double.parse((json['unit_price'] ?? 0).toString());
        } catch (_) {
          return 0.0;
        }
      })(),
      observation: json['observation'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      // Supabase retorna como array: 'products' ou pode vir como 'product'
      product: (() {
        if (json['products'] is List) {
          final products = json['products'] as List?;
          return products?.isNotEmpty == true
              ? products![0] as Map<String, dynamic>?
              : null;
        } else {
          return json['product'] as Map<String, dynamic>?;
        }
      })(),
    );
  }

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'observation': observation,
      };
}

class Payment {
  final String id;
  final String orderId;
  final double amount;
  final String status; // pending, completed, failed
  final String paymentMethod;
  final String? transactionId;
  final String? receiptNumber;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.transactionId,
    this.receiptNumber,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: (json['id'] ?? '').toString(),
      orderId: (json['order_id'] ?? '').toString(),
      amount: (() {
        try {
          return double.parse((json['amount'] ?? 0).toString());
        } catch (_) {
          return 0.0;
        }
      })(),
      status: (json['status'] ?? 'pending').toString(),
      paymentMethod: (json['payment_method'] ?? 'simulated').toString(),
      transactionId: json['transaction_id']?.toString(),
      receiptNumber: json['receipt_number']?.toString(),
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'amount': amount,
        'status': status,
        'payment_method': paymentMethod,
        'transaction_id': transactionId,
        'receipt_number': receiptNumber,
      };
}

class OrderTracking {
  final String id;
  final String orderId;
  final String status;
  final String message;
  final DateTime createdAt;

  OrderTracking({
    required this.id,
    required this.orderId,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    return OrderTracking(
      id: (json['id'] ?? '').toString(),
      orderId: (json['order_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
