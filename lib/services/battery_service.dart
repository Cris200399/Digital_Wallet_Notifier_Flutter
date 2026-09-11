import 'package:flutter/services.dart';

/// Servicio para gestionar la exención de optimización de batería
/// y el foreground service de la app.
class BatteryService {
  static const _foregroundChannel =
  MethodChannel('com.example.yape_notifier/foreground');
  static const _batteryChannel =
  MethodChannel('com.example.yape_notifier/battery');

  /// Inicia el foreground service que mantiene la app viva.
  static Future<void> iniciarForegroundService() async {
    try {
      await _foregroundChannel.invokeMethod('startForegroundService');
      print("✓ Foreground service iniciado");
    } catch (e) {
      print("✗ Error al iniciar foreground service: $e");
    }
  }

  /// Verifica si la app está exenta de optimización de batería.
  static Future<bool> estaBateriaOptimizada() async {
    try {
      final result =
      await _batteryChannel.invokeMethod<bool>('isBatteryOptimizationDisabled');
      return result ?? false;
    } catch (e) {
      print("Error al verificar batería: $e");
      return false;
    }
  }

  /// Abre la pantalla de configuración de batería para que el usuario
  /// exente la app de la optimización.
  static Future<void> abrirConfiguracionBateria() async {
    try {
      await _batteryChannel.invokeMethod('openBatterySettings');
    } catch (e) {
      print("Error al abrir configuración de batería: $e");
    }
  }
}