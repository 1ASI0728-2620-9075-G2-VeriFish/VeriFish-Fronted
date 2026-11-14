import 'package:dio/dio.dart';

String apiErrorMessage(Object error, {required String fallback}) {
  if (error is! DioException) return fallback;
  switch (error.response?.statusCode) {
    case 401:
      return 'Tu sesión venció. Cierra sesión y vuelve a ingresar.';
    case 403:
      return 'No tienes acceso a este recurso. Verifica tu granja y vuelve a ingresar si acabas de crearla.';
    case 409:
      return 'Ya existe un registro con ese código. Revisa los datos e intenta de nuevo.';
  }
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return 'El servidor tardó en responder. Intenta nuevamente.';
  }
  if (error.type == DioExceptionType.connectionError) {
    return 'No se pudo conectar con el servidor. Revisa tu conexión e intenta nuevamente.';
  }
  return fallback;
}
