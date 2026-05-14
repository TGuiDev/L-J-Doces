import 'package:dio/dio.dart';
import "../models/category_model.dart";
import "../models/product_model.dart";
import "../models/analytics_model.dart";
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/auth_response.dart';

class ApiService {
  static const String connectionWarning =
      'Sem conexao com a internet. Verifique sua rede e tente novamente.';

  late Dio _dio;
  late String _baseUrl;

  ApiService() {
    _baseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000');

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ));

    // Add interceptor to include token in requests and log
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('[DIO] REQUEST: ${options.method} ${options.path}');
        print('[DIO] Headers: ${options.headers}');
        print('[DIO] Data: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print(
            '[DIO] RESPONSE ${response.statusCode}: ${response.requestOptions.path}');
        // print('[DIO] Response data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('[DIO] ERROR: ${error.requestOptions.path}');
        print('[DIO] Status: ${error.response?.statusCode}');
        print('[DIO] Response data error?: ${error.response?.data}');
        print('[DIO] Error message: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  static bool isConnectionError(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.response == null;
    }

    final message = error.toString().toLowerCase();
    return message.contains('failed host lookup') ||
        message.contains('xmlhttprequest') ||
        message.contains('connection') ||
        message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout');
  }

  static String friendlyErrorMessage(
    Object error, {
    String fallback = 'Nao foi possivel concluir a acao. Tente novamente.',
  }) {
    if (isConnectionError(error)) {
      return connectionWarning;
    }

    final rawMessage = error.toString().replaceFirst('Exception: ', '').trim();
    return rawMessage.isEmpty ? fallback : rawMessage;
  }

  // Auth endpoints
  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      print('[API] Enviando signUp para $_baseUrl/auth/signup');
      print(
          '[API] Dados: name=$name, email=$email, password.length=${password.length}');

      final response = await _dio.post(
        '/auth/signup',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );

      print('[API] Resposta recebida: ${response.statusCode}');
      print('[API] Dados da resposta: ${response.data}');

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage = isConnectionError(e)
          ? connectionWarning
          : e.response?.data['message'] ?? e.message ?? 'Erro desconhecido';
      final errorData = e.response?.data;

      print('[API] DioException ao fazer signup');
      print('[API] StatusCode: ${e.response?.statusCode}');
      print('[API] ErrorData: $errorData');
      print('[API] Message: $errorMessage');
      print('[API] Exception: ${e.error}');

      return AuthResponse(
        success: false,
        error: errorMessage ?? 'Erro ao registrar',
      );
    } catch (e) {
      print('[API] Erro geral ao fazer signup: $e');
      print('[API] Stack: ${StackTrace.current}');

      return AuthResponse(
        success: false,
        error: friendlyErrorMessage(e, fallback: 'Erro ao registrar'),
      );
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signin',
        data: {
          'email': email,
          'password': password,
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        error: isConnectionError(e)
            ? connectionWarning
            : e.response?.data['message'] ?? 'Erro ao fazer login',
      );
    }
  }

  Future<AuthResponse> googleAuth({required String idToken}) async {
    try {
      print('[API.GoogleAuth] Iniciando Google Auth');
      print('[API.GoogleAuth] Base URL: $_baseUrl');
      print('[API.GoogleAuth] ID Token length: ${idToken.length}');
      print(
          '[API.GoogleAuth] ID Token preview: ${idToken.isNotEmpty ? idToken.substring(0, 50) : "VAZIO"}...');
      print('[API.GoogleAuth] ID Token isEmpty: ${idToken.isEmpty}');

      final requestData = {'idToken': idToken};
      print('[API.GoogleAuth] Request body: $requestData');

      print('[API.GoogleAuth] Enviando POST para $_baseUrl/auth/google');

      final response = await _dio.post(
        '/auth/google',
        data: requestData,
      );

      print('[API.GoogleAuth] Resposta recebida: ${response.statusCode}');
      print('[API.GoogleAuth] Dados: ${response.data}');

      final authResponse = AuthResponse.fromJson(response.data);
      print(
          '[API.GoogleAuth] AuthResponse parseado: success=${authResponse.success}');

      return authResponse;
    } on DioException catch (e) {
      final errorMessage = isConnectionError(e)
          ? connectionWarning
          : e.response?.data['message'] ??
              e.response?.data['error'] ??
              e.message ??
              'Erro desconhecido';
      final errorData = e.response?.data;

      print('[API.GoogleAuth] DioException ao fazer Google Auth');
      print('[API.GoogleAuth] StatusCode: ${e.response?.statusCode}');
      print('[API.GoogleAuth] ErrorData: $errorData');
      print('[API.GoogleAuth] Message: $errorMessage');

      return AuthResponse(
        success: false,
        error: errorMessage ?? 'Erro ao autenticar com Google',
      );
    } catch (e) {
      print('[API.GoogleAuth] Erro geral ao fazer Google Auth: $e');
      print('[API.GoogleAuth] Stack: ${StackTrace.current}');

      return AuthResponse(
        success: false,
        error: friendlyErrorMessage(
          e,
          fallback: 'Erro ao autenticar com Google',
        ),
      );
    }
  }

  Future<AuthResponse> getProfile() async {
    try {
      final response = await _dio.get('/auth/profile');
      return AuthResponse.fromJson({
        'success': true,
        'user': response.data,
      });
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        error: e.response?.data['message'] ?? 'Erro ao obter perfil',
      );
    }
  }

  Future<AuthResponse> resendConfirmationEmail({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/resend-confirmation',
        data: {'email': email},
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        error: e.response?.data['message'] ?? 'Erro ao reenviar email de confirmação',
      );
    }
  }

  Future<AuthResponse> resetPassword({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'email': email},
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        error: e.response?.data['message'] ?? 'Erro ao enviar email de reset de senha',
      );
    }
  }

  Future<AuthResponse> updatePassword({required String newPassword}) async {
    try {
      final response = await _dio.post(
        '/auth/update-password',
        data: {'password': newPassword},
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        error: e.response?.data['message'] ?? 'Erro ao atualizar senha',
      );
    }
  }

  Future<dynamic> updateProfile({
    required String name,
    String? picture,
    String? phone,
    String? password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/profile/update',
        data: {
          'name': name,
          if (picture != null) 'picture': picture,
          if (phone != null) 'phone': phone,
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Erro ao atualizar perfil');
    }
  }

  Future<void> logout() async {
    removeAuthToken();
  }

  // ==============================
  // PRODUTOS E CATEGORIAS (ADMIN)
  // ==============================

  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      return (response.data as List).map((json) {
          return Category(
            id: json["id"]?.toString() ?? "",
            name: json["name"]?.toString() ?? "",
            description: json["description"]?.toString() ?? "",
            imageUrl: json["image_url"]?.toString(),
            orderIndex: json["order_index"] ?? 0,
            subcategories: (json["subcategories"] as List? ?? []).map<SubCategory>((sub) {
              return SubCategory(
                id: sub["id"]?.toString() ?? "",
                categoryId: sub["category_id"]?.toString() ?? "",
                name: sub["name"]?.toString() ?? "",
                description: sub["description"]?.toString() ?? "",
                imageUrl: sub["image_url"]?.toString(),
                orderIndex: sub["order_index"] ?? 0,
              );
            }).toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
        );
      }).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    } catch (e) {
      print('Erro em getCategories: $e');
      throw Exception('Não foi possível carregar categorias');
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('/products');
      return (response.data as List).map((json) {
        return Product.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      print('Erro em getProducts: $e');
      throw Exception('Não foi possível carregar produtos');
    }
  }

  Future<List<Product>> getTopOrderedProducts() async {
    try {
      final response = await _dio.get('/products/top-ordered');
      return (response.data as List).map((json) {
        return Product.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      print('Erro em getTopOrderedProducts: $e');
      throw Exception('Nao foi possivel carregar produtos mais pedidos');
    }
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _dio.get('/products/category/$categoryId');
      return (response.data as List).map((json) {
        return Product.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      print('Erro em getProductsByCategory: $e');
      throw Exception('Não foi possível carregar produtos da categoria');
    }
  }

  Future<void> createCategory(Category category) async {
    await _dio.post('/categories', data: {
      'name': category.name,
      'description': category.description,
      'image_url': category.imageUrl,
    });
  }

  Future<void> updateCategory(String id, Category category) async {
    await _dio.put('/categories/$id', data: {
      'name': category.name,
      'description': category.description,
      'image_url': category.imageUrl,
    });
  }

  Future<void> updateCategoriesOrder(List<Map<String, dynamic>> orders) async {
    await _dio.put('/categories/order', data: {
      'orders': orders,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete('/categories/$id');
  }

  Future<void> createSubcategory(SubCategory sub) async {
    await _dio.post('/categories/subcategories', data: {
      'category_id': sub.categoryId,
      'name': sub.name,
      'description': sub.description,
      'image_url': sub.imageUrl,
    });
  }

  Future<void> updateSubcategoriesOrder(
      List<Map<String, dynamic>> orders) async {
    await _dio.put('/categories/subcategories/order', data: {
      'orders': orders,
    });
  }

  Future<void> updateSubcategory(String id, SubCategory sub) async {
    await _dio.put('/categories/subcategories/$id', data: {
      'name': sub.name,
      'description': sub.description,
      'image_url': sub.imageUrl,
    });
  }

  Future<void> deleteSubcategory(String id) async {
    await _dio.delete('/categories/subcategories/$id');
  }

  Future<void> createProduct(Product product) async {
    await _dio.post('/products', data: {
      'name': product.name,
      'description': product.description,
      'ingredients': product.ingredients,
      'price': product.price,
      'cost_price': product.costPrice,
      'images': product.images,
      'category_id': product.categoryId,
      'subcategory_id': product.subcategoryId,
      'available_days': {
        for (final entry in product.availableDays.entries)
          entry.key.toString(): entry.value
      },
      'stock_quantity': product.stockQuantity,
    });
  }

  Future<void> updateProduct(String id, Product product) async {
    await _dio.put('/products/$id', data: {
      'name': product.name,
      'description': product.description,
      'ingredients': product.ingredients,
      'price': product.price,
      'cost_price': product.costPrice,
      'images': product.images,
      'category_id': product.categoryId,
      'subcategory_id': product.subcategoryId,
      'available_days': {
        for (final entry in product.availableDays.entries)
          entry.key.toString(): entry.value
      },
      'stock_quantity': product.stockQuantity,
    });
  }

  Future<void> deleteProduct(String id) async {
    await _dio.delete('/products/$id');
  }

  Future<List<String>> getFavorites(String token) async {
    try {
      final res = await _dio.get('/favorites',
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      final List data = res.data ?? [];
      return data.map((item) => item['product_id'].toString()).toList();
    } catch (e) {
      print('apiService.getFavorites err: $e');
      throw Exception('Erro ao buscar favoritos');
    }
  }

  Future<void> addFavorite(String token, String productId) async {
    try {
      await _dio.post('/favorites/$productId',
          options: Options(headers: {'Authorization': 'Bearer $token'}));
    } catch (e) {
      if (e is DioException &&
          e.response?.statusCode == 400 &&
          (e.response?.data.toString().contains('duplicate key') == true)) {
        // Já está favoritado, apenas ignora
        return;
      }
      print('apiService.addFavorite err: $e');
      throw Exception('Erro ao adicionar favorito: $e');
    }
  }

  Future<void> removeFavorite(String token, String productId) async {
    try {
      await _dio.delete('/favorites/$productId',
          options: Options(headers: {'Authorization': 'Bearer $token'}));
    } catch (e) {
      print('apiService.removeFavorite err: $e');
      throw Exception('Erro ao remover favorito');
    }
  }

  // -- BANNERS METHODS --
  Future<List<dynamic>> getBanners() async {
    try {
      final response = await _dio.get('/banners');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Erro getBanners(): $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createBanner(String token, String imageUrl, bool active) async {
    try {
      final oldAuth = _dio.options.headers['Authorization'];
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.post('/banners', data: {'image_url': imageUrl, 'active': active});
      if (oldAuth != null) _dio.options.headers['Authorization'] = oldAuth;
      else _dio.options.headers.remove('Authorization');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Erro createBanner(): $e');
      rethrow;
    }
  }

  Future<void> deleteBanner(String token, String id) async {
    try {
      final oldAuth = _dio.options.headers['Authorization'];
      _dio.options.headers['Authorization'] = 'Bearer $token';
      await _dio.delete('/banners/$id');
      if (oldAuth != null) _dio.options.headers['Authorization'] = oldAuth;
      else _dio.options.headers.remove('Authorization');
    } catch (e) {
      print('Erro deleteBanner(): $e');
      rethrow;
    }
  }

  // Generic HTTP methods for flexible endpoint access
  Future<dynamic> get(String path, {String? token}) async {
    try {
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      final response = await _dio.get(path, options: options);
      return response.data;
    } catch (e) {
      print('ApiService.get error on $path: $e');
      throw Exception(friendlyErrorMessage(e));
    }
  }

  Future<dynamic> post(String path, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    try {
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      final response = await _dio.post(path, data: data, options: options);
      return response.data;
    } catch (e) {
      print('ApiService.post error on $path: $e');
      throw Exception(friendlyErrorMessage(e));
    }
  }

  Future<dynamic> put(String path, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    try {
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      final response = await _dio.put(path, data: data, options: options);
      return response.data;
    } catch (e) {
      print('ApiService.put error on $path: $e');
      throw Exception(friendlyErrorMessage(e));
    }
  }

  Future<void> delete(String path, {String? token}) async {
    try {
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      await _dio.delete(path, options: options);
    } catch (e) {
      print('ApiService.delete error on $path: $e');
      throw Exception(friendlyErrorMessage(e));
    }
  }

  Future<OperationalSummary> getOperationalSummary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};

      if (startDate != null) {
        params['startDate'] = startDate;
      }

      if (endDate != null) {
        params['endDate'] = endDate;
      }

      final response = await _dio.get(
        '/analytics/operational-summary',
        queryParameters: params,
      );

      return OperationalSummary.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      print('ApiService.getOperationalSummary Dio error: ${e.response?.data}');

      throw Exception(
        isConnectionError(e)
            ? connectionWarning
            : e.response?.data?['message'] ??
                e.response?.data?['error'] ??
                'Erro ao gerar resumo operacional',
      );
    } catch (e) {
      print('ApiService.getOperationalSummary error: $e');
      throw Exception(friendlyErrorMessage(e));
    }
  }

  Future<ProductAnalytics> getProductAnalytics({
    String? token,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};

      if (startDate != null) {
        params['startDate'] = startDate;
      }

      if (endDate != null) {
        params['endDate'] = endDate;
      }

      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      final response = await _dio.get(
        '/analytics/products',
        queryParameters: params,
        options: options,
      );

      final payload = response.data;
      final data = payload is Map<String, dynamic>
          ? Map<String, dynamic>.from(payload['data'] ?? payload)
          : <String, dynamic>{};

      return ProductAnalytics.fromJson(data);
    } on DioException catch (e) {
      print('ApiService.getProductAnalytics Dio error: ${e.response?.data}');
      throw Exception(
        isConnectionError(e)
            ? connectionWarning
            : e.response?.data?['message'] ??
                e.response?.data?['error'] ??
                'Erro ao obter produtos mais vendidos',
      );
    } catch (e) {
      print('ApiService.getProductAnalytics error: $e');
      throw Exception(friendlyErrorMessage(e));
    }
  }
}
