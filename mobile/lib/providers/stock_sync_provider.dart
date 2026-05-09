import 'package:flutter/foundation.dart';
import '../services/socket_service.dart';

/// Provider que sincroniza estoque em tempo real com o servidor
/// Mantém cache de quantidades de estoque por produto
class StockSyncProvider extends ChangeNotifier {
  final SocketService _socketService = SocketService();

  /// Map de productId -> quantity
  final Map<String, int> _stockCache = {};

  /// Map de productId -> List de callbacks
  final Map<String, List<Function(int)>> _productListeners = {};

  StockSyncProvider() {
    _initializeStockUpdates();
  }

  void _initializeStockUpdates() {
    // Escutar atualizações de estoque do server
    _socketService.onStockUpdated((productId, newQuantity) {
      updateProductStock(productId, newQuantity);
    });
  }

  /// Atualizar estoque de um produto específico
  void updateProductStock(String productId, int newQuantity) {
    _stockCache[productId] = newQuantity;

    // Notificar listeners específicos do produto
    if (_productListeners.containsKey(productId)) {
      for (var callback in _productListeners[productId]!) {
        callback(newQuantity);
      }
    }

    notifyListeners();
  }

  /// Obter estoque em cache de um produto
  int? getProductStock(String productId) {
    return _stockCache[productId];
  }

  /// Pré-carregar estoque de um produto (atualizar cache)
  void setProductStock(String productId, int quantity) {
    _stockCache[productId] = quantity;
  }

  /// Subscribe a mudanças de estoque de um produto específico
  void subscribeToProductStock(String productId, Function(int) callback) {
    _productListeners.putIfAbsent(productId, () => []);
    _productListeners[productId]!.add(callback);

    // Também notificar o server para começar a ouvir
    _socketService.subscribeToProduct(productId);
  }

  /// Unsubscribe de mudanças de estoque
  void unsubscribeFromProductStock(String productId, Function(int) callback) {
    _productListeners[productId]?.remove(callback);
    if (_productListeners[productId]?.isEmpty ?? false) {
      _productListeners.remove(productId);
      _socketService.unsubscribeFromProduct(productId);
    }
  }

  /// Limpar cache e listeners
  void clear() {
    _stockCache.clear();
    _productListeners.clear();
  }

  @override
  void dispose() {
    _socketService.offStockUpdated();
    super.dispose();
  }
}
