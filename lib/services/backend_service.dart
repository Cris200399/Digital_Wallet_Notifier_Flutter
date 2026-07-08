import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

/// Error controlado del backend con un mensaje legible para el usuario.
class BackendException implements Exception {
  final String message;
  BackendException(this.message);
  @override
  String toString() => message;
}

/// Config de un comercio devuelta por el backend.
class ComercioConfig {
  final String id;
  final String nombre;
  final String botToken;
  final List<String> chatIds;

  ComercioConfig({
    required this.id,
    required this.nombre,
    required this.botToken,
    required this.chatIds,
  });
}

class BackendService {
  /// Despierta el backend (capa gratuita en reposo) golpeando /health.
  /// Timeout largo porque el cold start puede tardar.
  static Future<void> wakeUp() async {
    try {
      await http
          .get(Uri.parse("${Constants.backendBaseUrl}/health"))
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      // Ignoramos: el login reintenta igual.
    }
  }

  /// Valida credenciales contra el backend y devuelve el JWT.
  static Future<String> login({
    required String nombre,
    required String password,
  }) async {
    final url = Uri.parse("${Constants.backendBaseUrl}/auth/login");

    for (int intento = 1; intento <= 3; intento++) {
      try {
        final resp = await http
            .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'nombre': nombre, 'password': password}),
        )
            .timeout(const Duration(seconds: 60));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          return data['token'] as String;
        } else if (resp.statusCode == 401) {
          throw BackendException("Credenciales inválidas.");
        } else if (resp.statusCode == 429) {
          throw BackendException("Demasiados intentos. Espera unos minutos.");
        } else {
          throw BackendException("Error del servidor (${resp.statusCode}).");
        }
      } on TimeoutException {
        if (intento == 3) {
          throw BackendException("El servidor no respondió. Intenta de nuevo.");
        }
        // cold start: reintenta
      } on BackendException {
        rethrow;
      } catch (e) {
        if (intento == 3) {
          throw BackendException("Error de conexión.");
        }
      }
      await Future.delayed(const Duration(seconds: 3));
    }
    throw BackendException("No se pudo conectar.");
  }

  /// Obtiene la config de un comercio por su ID usando el JWT.
  static Future<ComercioConfig> getComercio({
    required String jwt,
    required String comercioId,
  }) async {
    final url =
    Uri.parse("${Constants.backendBaseUrl}/comercios/$comercioId");
    try {
      final resp = await http.get(
        url,
        headers: {'Authorization': 'Bearer $jwt'},
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return ComercioConfig(
          id: data['id'].toString(),
          nombre: (data['nombre'] ?? '') as String,
          botToken: (data['botToken'] ?? '') as String,
          chatIds: (data['chatIds'] as List)
              .map((e) => e.toString())
              .toList(),
        );
      } else if (resp.statusCode == 401) {
        throw BackendException("Sesión expirada. Ingresa de nuevo.");
      } else if (resp.statusCode == 404) {
        throw BackendException("Comercio no encontrado.");
      } else {
        throw BackendException("Error del servidor (${resp.statusCode}).");
      }
    } on TimeoutException {
      throw BackendException("El servidor no respondió.");
    } on BackendException {
      rethrow;
    } catch (e) {
      throw BackendException("Error de conexión.");
    }
  }
}