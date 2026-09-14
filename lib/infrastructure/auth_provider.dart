import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/user.dart';
import '../utils/token_storage.dart';
import 'auth_service.dart' as svc;
import 'fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> tryRestoreSession() async {
    if (await TokenStorage.hasSession()) {
      final info = await TokenStorage.getUserInfo();
      final id = await TokenStorage.getUserId();
      _user = User(
        id: id ?? 0,
        username: info['username'] ?? '',
        firstName: info['firstName'] ?? '',
        lastName: info['lastName'] ?? '',
        email: info['email'] ?? '',
        role: info['role'] ?? 'ADMIN',
      );
      if (_user!.id != 0) {
        FcmService.initializeAndSendToken(_user!.id);
      }
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await svc.login(username, password);
      if (_user != null) {
        FcmService.initializeAndSendToken(_user!.id);
      }
      return true;
    } catch (e) {
      _error = _parseError(e, fallback: 'Usuario o contraseña incorrectos');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
    String? farmToken,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await svc.register(
        username: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        role: role,
        farmToken: farmToken,
      );
      return true;
    } catch (e) {
      _error = _parseError(e, fallback: 'Error al registrar usuario');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _parseError(Object e, {required String fallback}) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Tiempo de espera agotado. Verifica tu conexión.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Sin conexión al servidor. Verifica tu internet.';
      }
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'] ?? data['error'] ?? data['detail'];
        if (msg != null) return msg.toString();
      }
      if (data is String && data.isNotEmpty && !data.trimLeft().startsWith('<')) return data;
      final status = e.response?.statusCode;
      if (status == 409) return 'El usuario o email ya está registrado';
      if (status == 400) return 'Datos inválidos, revisa los campos';
      if (status == 403) return 'Acceso denegado por el servidor';
      if (status == 401) return 'No autorizado';
      if (status != null && status >= 500) return 'Error en el servidor ($status). Intenta más tarde.';
      if (status != null) return 'Error del servidor ($status)';
    }
    return fallback;
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
