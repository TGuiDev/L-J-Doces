import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/banner_model.dart';

import '../services/api_service.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Category> _categories = [];
  List<Product> _products = [];
  List<Product> _allProducts = [];
  List<BannerModel> _banners = [];
  bool _isLoadingCategories = false;
  bool _isLoadingProducts = false;
  bool _isLoadingBanners = false;
  int _currentProductPage = 0;
  bool _hasMoreProducts = true;
  int _productsRequestVersion = 0;
  static const int _productsPageSize = 12;

  AdminProvider({required ApiService apiService}) : _apiService = apiService;

  List<Category> get categories => _categories;
  List<Product> get products => _products;
  List<Product> get allProducts => _allProducts;
  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoadingCategories || _isLoadingBanners;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get hasMoreProducts => _hasMoreProducts;

  Future<void> fetchCategories() async {
    _isLoadingCategories = true;
    notifyListeners();
    try {
      _categories = await _apiService.getCategories();
    } catch (e) {
      print('Erro ao carregar categorias: $e');
    }
    _isLoadingCategories = false;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    await fetchProductsPage(refresh: true);
  }

  Future<void> fetchProductsPage({
    bool refresh = false,
    bool forceApiRefresh = false,
    String? categoryId,
    String? subcategoryId,
  }) async {
    if (_isLoadingProducts && !refresh) return;

    final requestVersion = ++_productsRequestVersion;

    _isLoadingProducts = true;
    notifyListeners();
    try {
      // Load products from API if needed
      if (forceApiRefresh || _allProducts.isEmpty) {
        if (categoryId != null) {
          // Se há filtro de categoria, buscar apenas dessa categoria
          _allProducts = await _apiService.getProductsByCategory(categoryId);
        } else {
          // Se não há filtro, buscar todos os produtos
          _allProducts = await _apiService.getProducts();
        }
      }

      if (requestVersion != _productsRequestVersion) {
        return;
      }

      if (refresh) {
        _currentProductPage = 0;
        _hasMoreProducts = true;
        _products = [];
      }

      // Filter products locally (if needed)
      final filteredProducts = _allProducts.where((product) {
        final matchesCategory =
            categoryId == null || product.categoryId == categoryId;
        final matchesSubcategory =
            subcategoryId == null || product.subcategoryId == subcategoryId;
        return matchesCategory && matchesSubcategory;
      }).toList();

      // If no category filter is applied ("Todas"), show the full list
      // instead of paginating, so the admin sees all products when "Todos"
      // está selecionado.
      if (categoryId == null) {
        if (refresh) {
          _products = filteredProducts;
        } else {
          // Append any new items if loading more (rare for this branch)
          _products = [..._products, ...filteredProducts];
        }
        _currentProductPage = 0;
        _hasMoreProducts = false;
        return;
      }

      // Paginação padrão quando há filtro de categoria
      final startIndex = _currentProductPage * _productsPageSize;
      if (startIndex >= filteredProducts.length) {
        _hasMoreProducts = false;
        return;
      }

      final endIndex = (startIndex + _productsPageSize)
          .clamp(0, filteredProducts.length);
      final nextPage = filteredProducts.sublist(startIndex, endIndex);

      if (refresh) {
        _products = nextPage;
      } else {
        _products = [..._products, ...nextPage];
      }

      _currentProductPage++;
      _hasMoreProducts = endIndex < filteredProducts.length;
    } catch (e) {
      print('Erro ao carregar produtos: $e');
      if (refresh) {
        _products = [];
        _hasMoreProducts = false;
      }
    } finally {
      if (requestVersion == _productsRequestVersion) {
        _isLoadingProducts = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createCategory(Category category) async {
    try {
      await _apiService.createCategory(category);
      await fetchCategories();
      return true;
    } catch (e) {
      print('Erro ao criar categoria: $e');
      return false;
    }
  }

  Future<bool> updateCategory(String id, Category category) async {
    try {
      await _apiService.updateCategory(id, category);
      await fetchCategories();
      return true;
    } catch (e) {
      print('Erro ao atualizar categoria: $e');
      return false;
    }
  }

  Future<bool> updateCategoriesOrder(List<Category> updatedList) async {
    try {
      _categories = updatedList; // update local instantly for UI
      notifyListeners();

      final orders = updatedList.asMap().entries.map((e) => {
        'id': e.value.id,
        'order_index': e.key,
      }).toList();

      await _apiService.updateCategoriesOrder(orders);
      return true;
    } catch (e) {
      print('Erro ao atualizar ordem das categorias: $e');
      await fetchCategories(); // revert on fail
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _apiService.deleteCategory(id);
      await fetchCategories();
      return true;
    } catch (e) {
      print('Erro ao excluir categoria: $e');
      return false;
    }
  }

  Future<bool> createSubcategory(SubCategory subcategory) async {
    try {
      await _apiService.createSubcategory(subcategory);
      await fetchCategories();
      return true;
    } catch (e) {
      print('Erro ao criar subcategoria: $e');
      return false;
    }
  }

  Future<bool> updateSubcategory(String id, SubCategory subcategory) async {
    try {
      await _apiService.updateSubcategory(id, subcategory);
      await fetchCategories();
      return true;
    } catch (e) {
      print('Erro ao atualizar subcategoria: $e');
      return false;
    }
  }

  Future<bool> updateSubcategoriesOrder(String categoryId, List<SubCategory> updatedList) async {
    try {
      // Find category locally and update it
      final catIndex = _categories.indexWhere((c) => c.id == categoryId);
      if (catIndex != -1) {
        _categories[catIndex] = Category(
          id: _categories[catIndex].id,
          name: _categories[catIndex].name,
          description: _categories[catIndex].description,
          imageUrl: _categories[catIndex].imageUrl,
          orderIndex: _categories[catIndex].orderIndex,
          subcategories: updatedList,
        );
        notifyListeners();
      }

      final orders = updatedList.asMap().entries.map((e) => {
        'id': e.value.id,
        'order_index': e.key,
      }).toList();

      await _apiService.updateSubcategoriesOrder(orders);
      return true;
    } catch (e) {
      print('Erro ao atualizar ordem das subcategorias: $e');
      await fetchCategories(); // revert on fail
      return false;
    }
  }

  Future<bool> deleteSubcategory(String id) async {
    try {
      await _apiService.deleteSubcategory(id);
      await fetchCategories();
      return true;
    } catch (e) {
      print('Erro ao excluir subcategoria: $e');
      return false;
    }
  }

  Future<bool> createProduct(Product product) async {
    try {
      await _apiService.createProduct(product);
      await fetchProducts();
      return true;
    } catch (e) {
      print('Erro ao criar produto: $e');
      return false;
    }
  }

  Future<bool> updateProduct(String id, Product product) async {
    try {
      await _apiService.updateProduct(id, product);
      await fetchProducts();
      return true;
    } catch (e) {
      print('Erro ao atualizar produto: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _apiService.deleteProduct(id);
      await fetchProducts();
      return true;
    } catch (e) {
      print('Erro ao excluir produto: $e');
      return false;
    }
  }

  Future<void> fetchBanners() async {
    _isLoadingBanners = true;
    notifyListeners();
    try {
      final data = await _apiService.getBanners();
      _banners = data.map((json) => BannerModel.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar banners: $e');
    }
    _isLoadingBanners = false;
    notifyListeners();
  }

  Future<bool> createBanner(String token, String imageUrl, bool active) async {
    _isLoadingBanners = true;
    notifyListeners();
    try {
      final response = await _apiService.createBanner(token, imageUrl, active);
      final newBanner = BannerModel.fromJson(response);
      _banners.insert(0, newBanner);
      _isLoadingBanners = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro ao adicionar banner: $e');
      _isLoadingBanners = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBanner(String token, String id) async {
    _isLoadingBanners = true;
    notifyListeners();
    try {
      await _apiService.deleteBanner(token, id);
      _banners.removeWhere((b) => b.id == id);
      _isLoadingBanners = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro ao remover banner: $e');
      _isLoadingBanners = false;
      notifyListeners();
      return false;
    }
  }
}
