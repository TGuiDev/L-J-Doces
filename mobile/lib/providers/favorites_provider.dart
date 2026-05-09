import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final ApiService _apiService;

  FavoritesProvider({
    required ApiService apiService,
  }) : _apiService = apiService;

  // =========================
  // STATE
  // =========================

  List<String> _favoriteProductIds = [];

  bool _isLoading = false;

  bool _isToggling = false;

  String? _error;

  // =========================
  // GETTERS
  // =========================

  List<String> get favoriteProductIds =>
      _favoriteProductIds;

  bool get isLoading => _isLoading;

  bool get isToggling => _isToggling;

  String? get error => _error;

  bool isFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  // =========================
  // FETCH FAVORITES
  // =========================

  Future<void> fetchFavorites(
    String token,
  ) async {
    _setLoading(true);

    try {
      final favorites =
          await _apiService.getFavorites(token);

      _favoriteProductIds = favorites;

      _error = null;

      print(
        '[FAVORITES] Favoritos carregados: ${favorites.length}',
      );
    } catch (e) {
      _error =
          'Erro ao carregar favoritos';

      print(
        '[FAVORITES] fetchFavorites error: $e',
      );
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // TOGGLE FAVORITE
  // =========================

  Future<void> toggleFavorite(
    String token,
    String productId,
  ) async {
    // Evita múltiplos cliques simultâneos
    if (_isToggling) return;

    _isToggling = true;

    final currentlyFavorite =
        isFavorite(productId);

    // =========================
    // OPTIMISTIC UPDATE
    // =========================

    if (currentlyFavorite) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }

    notifyListeners();

    try {
      print(
        '[FAVORITES] Toggle product: $productId',
      );

      if (currentlyFavorite) {
        await _apiService.removeFavorite(
          token,
          productId,
        );

        print(
          '[FAVORITES] Favorito removido',
        );
      } else {
        await _apiService.addFavorite(
          token,
          productId,
        );

        print(
          '[FAVORITES] Favorito adicionado',
        );
      }

      _error = null;
    } catch (e) {
      print(
        '[FAVORITES] toggleFavorite error: $e',
      );

      // =========================
      // ROLLBACK
      // =========================

      if (currentlyFavorite) {
        _favoriteProductIds.add(productId);
      } else {
        _favoriteProductIds.remove(productId);
      }

      _error =
          'Erro ao atualizar favoritos';

      notifyListeners();
    } finally {
      _isToggling = false;
    }
  }

  // =========================
  // CLEAR
  // =========================

  void clearFavorites() {
    _favoriteProductIds.clear();

    _error = null;

    notifyListeners();
  }

  // =========================
  // HELPERS
  // =========================

  void _setLoading(bool value) {
    _isLoading = value;

    notifyListeners();
  }
}