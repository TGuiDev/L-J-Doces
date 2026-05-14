import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class OrdersProvider extends ChangeNotifier {
  final ApiService apiService;

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  OrdersProvider({required this.apiService});

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<Order?> createOrder(String token, List<Map<String, dynamic>> items, double totalAmount) async {
    try {
      _isLoading = true;
      _error = null;
      _safeNotify();

      final response = await apiService.post(
        '/orders',
        data: {
          'items': items,
          'total_amount': totalAmount,
        },
        token: token,
      );

      if (response != null) {
        final order = Order.fromJson(response);
        _orders.insert(0, order);
        _safeNotify();
        return order;
      }
      return null;
    } catch (e) {
      _error = ApiService.friendlyErrorMessage(e);
      _safeNotify();
      return null;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<Order?> simulatePayment(String token, String orderId) async {
    try {
      _isLoading = true;
      _error = null;
      _safeNotify();

      final response = await apiService.post(
        '/orders/$orderId/pay',
        data: {},
        token: token,
      );

      if (response != null) {
        final order = Order.fromJson(response);
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = order;
        }
        _safeNotify();
        return order;
      }
      return null;
    } catch (e) {
      _error = ApiService.friendlyErrorMessage(e);
      _safeNotify();
      return null;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> fetchUserOrders(String token) async {
    try {
      _isLoading = true;
      _error = null;
      _safeNotify();

      final response = await apiService.get('/orders', token: token);

      // Debug: log response shape
      print('[ORDERS_PROVIDER] fetchUserOrders response type: ${response.runtimeType}');
      if (response is List && response.isNotEmpty) {
        print('[ORDERS_PROVIDER] first item keys: ${(response[0] as Map).keys.toList()}');
      }

      if (response != null) {
        try {
          _orders = (response as List).map((json) => Order.fromJson(json)).toList();
        } catch (e, st) {
          print('[ORDERS_PROVIDER] Error parsing orders: $e');
          print(st);
          _error = 'Erro ao processar pedidos: $e';
          _orders = [];
        }
        _safeNotify();
      }
    } catch (e) {
      _error = ApiService.friendlyErrorMessage(e);
      _safeNotify();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> fetchAllOrders(String token) async {
    try {
      _isLoading = true;
      _error = null;
      _safeNotify();

      final response = await apiService.get('/orders/admin', token: token);

      if (response != null) {
        _orders = (response as List).map((json) => Order.fromJson(json)).toList();
        _safeNotify();
      }
    } catch (e) {
      _error = ApiService.friendlyErrorMessage(e);
      _safeNotify();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<Order?> getOrderDetails(String token, String orderId) async {
    try {
      final response = await apiService.get('/orders/$orderId', token: token);

      if (response != null) {
        return Order.fromJson(response);
      }
      return null;
    } catch (e) {
      _error = ApiService.friendlyErrorMessage(e);
      _safeNotify();
      return null;
    }
  }

  Future<Order?> updateOrderStatus(String token, String orderId, String newStatus) async {
    try {
      _isLoading = true;
      _error = null;
      _safeNotify();

      final response = await apiService.post(
        '/orders/$orderId/status',
        data: {'status': newStatus},
        token: token,
      );

      if (response != null) {
        final order = Order.fromJson(response);
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = order;
        }
        _safeNotify();
        return order;
      }
      return null;
    } catch (e) {
      _error = ApiService.friendlyErrorMessage(e);
      _safeNotify();
      return null;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void clearError() {
    _error = null;
    _safeNotify();
  }

  void _safeNotify() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      if (hasListeners) notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }
}
