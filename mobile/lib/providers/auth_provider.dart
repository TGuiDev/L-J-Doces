import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  AuthProvider({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  // Getters
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Token expiry info
  int get tokenExpiryDaysRemaining => _storageService.getTokenExpiryDaysRemaining();

  String get expiryMessage {
    final days = tokenExpiryDaysRemaining;
    if (days == 0) return 'Expira em menos de 1 dia';
    if (days == 1) return 'Expira em 1 dia';
    return 'Expira em $days dias';
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.init();
      final token = _storageService.getToken();

      if (token != null) {
        _token = token;
        _apiService.setAuthToken(token);

        // Carrega perfil do usuário
        await _loadUserProfile();
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      _isAuthenticated = false;
      _error = 'Erro ao carregar sessão: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    print('[AuthProvider] Iniciando signUp');
    print('[AuthProvider] Dados: name=$name, email=$email');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('[AuthProvider] Chamando apiService.signUp...');
      final response = await _apiService.signUp(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      print('[AuthProvider] Resposta recebida: success=${response.success}');
      print('[AuthProvider] Response object: $response');

      if (response.success) {
        print('[AuthProvider] Signup bem-sucedido!');
        _token = response.token;
        _user = response.user;
        await _storageService.saveToken(response.token!);
        if (_user != null) {
          await _storageService.saveUser(jsonEncode(_user!.toJson()));
        }
        _apiService.setAuthToken(_token!);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('[AuthProvider] Signup falhou: ${response.error}');
        _error = response.error ?? 'Erro ao registrar';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('[AuthProvider] Exceção ao fazer signup: $e');
      print('[AuthProvider] Stack: ${StackTrace.current}');
      _error = ApiService.friendlyErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.signIn(
        email: email,
        password: password,
      );

      if (response.success) {
        _token = response.token;
        _user = response.user;
        await _storageService.saveToken(response.token!);
        if (_user != null) {
          await _storageService.saveUser(jsonEncode(_user!.toJson()));
        }
        _apiService.setAuthToken(_token!);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Verificar se é erro de email não confirmado
        if (response.error?.contains('EMAIL_NOT_CONFIRMED') == true) {
          _error = 'Por favor, confirme seu email antes de fazer login. Verifique sua caixa de entrada e clique no link de confirmação.';
        } else {
          _error = response.error ?? 'Erro ao fazer login';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = ApiService.friendlyErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> googleAuth({required String idToken}) async {
    print('[AuthProvider] Iniciando googleAuth');
    print('[AuthProvider] idToken type: ${idToken.runtimeType}');
    print('[AuthProvider] idToken length: ${idToken.length}');
    print('[AuthProvider] idToken isEmpty: ${idToken.isEmpty}');
    print('[AuthProvider] idToken preview: ${idToken.isNotEmpty ? idToken.substring(0, 50) : "VAZIO"}...');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('[AuthProvider] Chamando apiService.googleAuth...');
      final response = await _apiService.googleAuth(idToken: idToken);

      print('[AuthProvider] Resposta Google Auth: success=${response.success}');
      print('[AuthProvider] Token: ${response.token}');
      print('[AuthProvider] User: ${response.user}');
      print('[AuthProvider] Error: ${response.error}');

      if (response.success) {
        print('[AuthProvider] Google Auth bem-sucedido!');
        _token = response.token;
        _user = response.user;
        await _storageService.saveToken(response.token!);
        if (_user != null) {
          await _storageService.saveUser(jsonEncode(_user!.toJson()));
        }
        _apiService.setAuthToken(_token!);
        _isAuthenticated = true;
        _isLoading = false;
        print('[AuthProvider] _isAuthenticated = true');
        notifyListeners();
        return true;
      } else {
        print('[AuthProvider] Google Auth falhou: ${response.error}');
        _error = response.error ?? 'Erro ao autenticar';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('[AuthProvider] Exceção ao fazer Google Auth: $e');
      print('[AuthProvider] Stack: ${StackTrace.current}');
      _error = ApiService.friendlyErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final userJson = _storageService.getUser();
      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
      }

      // Tenta atualizar dados do servidor
      final response = await _apiService.getProfile();
      if (response.success && response.user != null) {
        _user = response.user;
        // Atualiza no storage
        if (_user != null) {
          await _storageService.saveUser(jsonEncode(_user!.toJson()));
        }
      }

      _isAuthenticated = _user != null;
    } catch (e) {
      // Se falhar ao carregar do servidor, usa o local
      final userJson = _storageService.getUser();
      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? picture,
    String? phone,
    String? password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateProfile(name: name, picture: picture, phone: phone, password: password);
      _user = _user?.copyWith(name: name, picture: picture, phone: phone);
      if (_user != null) {
        await _storageService.saveUser(jsonEncode(_user!.toJson()));
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.friendlyErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendConfirmationEmail({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.resendConfirmationEmail(email: email);

      if (response.success) {
        _error = 'Email de confirmação reenviado. Verifique sua caixa de entrada.';
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Erro ao reenviar email de confirmação';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = ApiService.friendlyErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.resetPassword(email: email);

      if (response.success) {
        _error = 'Email de redefinição de senha enviado. Verifique sua caixa de entrada.';
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Erro ao enviar email de redefinição de senha';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = ApiService.friendlyErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword({required String newPassword}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updatePassword(newPassword: newPassword);

      if (response.success) {
        _error = 'Senha atualizada com sucesso!';
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Erro ao atualizar senha';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = ApiService.friendlyErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmResetPassword({
    required String newPassword,
    String? code,
    String? accessToken,
    String? refreshToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.confirmResetPassword(
        newPassword: newPassword,
        code: code,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      if (response.success) {
        _error = 'Senha atualizada com sucesso!';
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Erro ao atualizar senha';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = ApiService.friendlyErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _storageService.clearAll();
    _user = null;
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
