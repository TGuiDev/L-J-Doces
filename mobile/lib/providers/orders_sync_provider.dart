import 'package:flutter/foundation.dart';
import '../services/socket_service.dart';

/// Provider que sincroniza pedidos em tempo real com o servidor
/// Mantém listeners para mudanças de status de pedidos
class OrdersSyncProvider extends ChangeNotifier {
  final SocketService _socketService = SocketService();

  /// Map de orderId -> List de callbacks para mudanças de status
  final Map<String, List<Function(String)>> _orderStatusListeners = {};

  /// Listeners para pedidos do usuário
  final List<Function(String, String)> _userOrdersListeners = [];

  /// Listeners para pedidos do admin
  final List<Function(Map<String, dynamic>)> _adminOrderListeners = [];

  /// Listeners para vendas
  final List<Function(Map<String, dynamic>)> _salesListeners = [];

  OrdersSyncProvider() {
    _initializeOrderUpdates();
  }

  void _initializeOrderUpdates() {
    // Escutar mudanças de status de pedidos
    _socketService.onOrderStatusUpdated((orderId, newStatus) {
      _notifyOrderStatusChanged(orderId, newStatus);
    });

    // Escutar atualizações admin de pedidos
    _socketService.onAdminOrderUpdated((orderId, orderData) {
      _notifyAdminOrderUpdated(orderData);
    });

    // Escutar atualizações de vendas
    _socketService.onSalesUpdated((salesData) {
      _notifySalesUpdated(salesData);
    });
  }

  void _notifyOrderStatusChanged(String orderId, String newStatus) {
    // Notificar listeners específicos do pedido
    if (_orderStatusListeners.containsKey(orderId)) {
      for (var callback in _orderStatusListeners[orderId]!) {
        callback(newStatus);
      }
    }

    // Notificar listeners de pedidos do usuário
    for (var callback in _userOrdersListeners) {
      callback(orderId, newStatus);
    }

    notifyListeners();
  }

  void _notifyAdminOrderUpdated(Map<String, dynamic> orderData) {
    for (var callback in _adminOrderListeners) {
      callback(orderData);
    }
    notifyListeners();
  }

  void _notifySalesUpdated(Map<String, dynamic> salesData) {
    for (var callback in _salesListeners) {
      callback(salesData);
    }
    notifyListeners();
  }

  /// Subscribe a mudanças de status de um pedido específico
  void subscribeToOrderStatus(String orderId, Function(String) callback) {
    _orderStatusListeners.putIfAbsent(orderId, () => []);
    _orderStatusListeners[orderId]!.add(callback);

    // Notificar o server para começar a ouvir
    _socketService.subscribeToOrder(orderId);
  }

  /// Unsubscribe de mudanças de status
  void unsubscribeFromOrderStatus(String orderId, Function(String) callback) {
    _orderStatusListeners[orderId]?.remove(callback);
    if (_orderStatusListeners[orderId]?.isEmpty ?? false) {
      _orderStatusListeners.remove(orderId);
      _socketService.unsubscribeFromOrder(orderId);
    }
  }

  /// Subscribe a pedidos do usuário
  void subscribeToUserOrders(String userId, Function(String, String) callback) {
    _userOrdersListeners.add(callback);
    _socketService.subscribeToUserOrders(userId);
  }

  /// Unsubscribe de pedidos do usuário
  void unsubscribeFromUserOrders(Function(String, String) callback) {
    _userOrdersListeners.remove(callback);
  }

  /// Subscribe a todos os pedidos (admin)
  void subscribeToAllOrders(Function(Map<String, dynamic>) callback) {
    _adminOrderListeners.add(callback);
    _socketService.subscribeToAllOrders();
  }

  /// Unsubscribe de todos os pedidos
  void unsubscribeFromAllOrders(Function(Map<String, dynamic>) callback) {
    _adminOrderListeners.remove(callback);
  }

  /// Subscribe a atualizações de vendas
  void subscribeToSales(Function(Map<String, dynamic>) callback) {
    _salesListeners.add(callback);
  }

  /// Unsubscribe de atualizações de vendas
  void unsubscribeFromSales(Function(Map<String, dynamic>) callback) {
    _salesListeners.remove(callback);
  }

  /// Limpar listeners
  void clear() {
    _orderStatusListeners.clear();
    _userOrdersListeners.clear();
    _adminOrderListeners.clear();
    _salesListeners.clear();
  }

  @override
  void dispose() {
    _socketService.offOrderStatusUpdated();
    _socketService.offAdminOrderUpdated();
    _socketService.offSalesUpdated();
    super.dispose();
  }
}
