import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class SocketService extends ChangeNotifier {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  late IO.Socket _stockSocket;
  late IO.Socket _ordersSocket;

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Inicializar conexões WebSocket com o backend
  Future<void> initialize(String backendUrl) async {
    try {
      final parsedUri = Uri.parse(backendUrl);
      final socketUrl = parsedUri.hasScheme
          ? '${parsedUri.scheme}://${parsedUri.authority}'
          : 'http://${backendUrl.replaceAll(RegExp(r'^//|/$'), '')}';

      // Opções de conexão
      final socketOptions = {
        'transports': ['polling', 'websocket'],
        'autoConnect': true,
        'forceNew': true,
      };

      // Conectar ao namespace /stock para sincronização de estoque
      _stockSocket = IO.io(
        '$socketUrl/stock',
        socketOptions,
      );

      // Conectar ao namespace /orders para sincronização de pedidos
      _ordersSocket = IO.io(
        '$socketUrl/orders',
        socketOptions,
      );

      // Listeners para conexão do stock socket
      _stockSocket.onConnect((_) {
        print('[SocketService] Stock socket connected');
        _isConnected = true;
        notifyListeners();
      });

      _stockSocket.onDisconnect((_) {
        print('[SocketService] Stock socket disconnected');
        _isConnected = false;
        notifyListeners();
      });

      _stockSocket.onError((data) {
        print('[SocketService] Stock socket error: $data');
      });

      // Listeners para conexão do orders socket
      _ordersSocket.onConnect((_) {
        print('[SocketService] Orders socket connected');
      });

      _ordersSocket.onDisconnect((_) {
        print('[SocketService] Orders socket disconnected');
      });

      _ordersSocket.onError((data) {
        print('[SocketService] Orders socket error: $data');
      });
    } catch (e) {
      print('[SocketService] Error initializing: $e');
    }
  }

  /// ===== STOCK LISTENERS =====

  /// Escutar atualizações de estoque de um produto específico
  void onStockUpdated(Function(String productId, int newQuantity) callback) {
    _stockSocket.on('stock:updated', (data) {
      if (data is Map) {
        final productId = data['productId'] as String?;
        final newQuantity = data['newQuantity'] as int?;

        if (productId != null && newQuantity != null) {
          callback(productId, newQuantity);
        }
      }
    });
  }

  /// Remover listener de atualização de estoque
  void offStockUpdated() {
    _stockSocket.off('stock:updated');
  }

  /// Subscribe a um produto para receber atualizações de estoque
  void subscribeToProduct(String productId) {
    _stockSocket.emit('subscribe:product', {'productId': productId});
    print('[SocketService] Subscribed to product: $productId');
  }

  /// Unsubscribe de um produto
  void unsubscribeFromProduct(String productId) {
    _stockSocket.emit('unsubscribe:product', {'productId': productId});
    print('[SocketService] Unsubscribed from product: $productId');
  }

  /// ===== ORDERS LISTENERS =====

  /// Escutar mudanças de status do pedido
  void onOrderStatusUpdated(
    Function(String orderId, String newStatus) callback,
  ) {
    _ordersSocket.on('order:status:updated', (data) {
      if (data is Map) {
        final orderId = data['orderId'] as String?;
        final newStatus = data['newStatus'] as String?;

        if (orderId != null && newStatus != null) {
          callback(orderId, newStatus);
        }
      }
    });
  }

  /// Remover listener de mudança de status
  void offOrderStatusUpdated() {
    _ordersSocket.off('order:status:updated');
  }

  /// Subscribe a um pedido específico
  void subscribeToOrder(String orderId) {
    _ordersSocket.emit('subscribe:order', {'orderId': orderId});
    print('[SocketService] Subscribed to order: $orderId');
  }

  /// Unsubscribe de um pedido
  void unsubscribeFromOrder(String orderId) {
    _ordersSocket.emit('unsubscribe:order', {'orderId': orderId});
    print('[SocketService] Unsubscribed from order: $orderId');
  }

  /// Subscribe a todos os pedidos do usuário
  void subscribeToUserOrders(String userId) {
    _ordersSocket.emit('subscribe:user-orders', {'userId': userId});
    print('[SocketService] Subscribed to user orders: $userId');
  }

  /// Subscribe a todos os pedidos (admin)
  void subscribeToAllOrders() {
    _ordersSocket.emit('subscribe:all-orders', {});
    print('[SocketService] Subscribed to all orders');
  }

  /// Escutar atualizações de vendas (para dashboard admin)
  void onSalesUpdated(Function(Map<String, dynamic> sales) callback) {
    _ordersSocket.on('admin:sales:updated', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  /// Remover listener de vendas
  void offSalesUpdated() {
    _ordersSocket.off('admin:sales:updated');
  }

  /// Escutar atualização de pedidos para admin
  void onAdminOrderUpdated(
    Function(String orderId, Map<String, dynamic> orderData) callback,
  ) {
    _ordersSocket.on('admin:order:updated', (data) {
      if (data is Map) {
        final orderId = data['orderId'] as String?;
        if (orderId != null) {
          callback(orderId, Map<String, dynamic>.from(data));
        }
      }
    });
  }

  /// Remover listener de pedidos admin
  void offAdminOrderUpdated() {
    _ordersSocket.off('admin:order:updated');
  }

  /// Desconectar todos os sockets
  void disconnect() {
    _stockSocket.disconnect();
    _ordersSocket.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  /// Reconectar sockets
  void reconnect() {
    _stockSocket.connect();
    _ordersSocket.connect();
  }

  /// Obter socket de estoque (para testes ou uso avançado)
  IO.Socket get stockSocket => _stockSocket;

  /// Obter socket de pedidos (para testes ou uso avançado)
  IO.Socket get ordersSocket => _ordersSocket;
}
