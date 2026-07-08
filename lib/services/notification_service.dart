import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import '../background_handler.dart';

/// Envuelve las llamadas al plugin de listener de notificaciones.
class NotificationService {
  static Future<bool> hasPermission() async {
    return (await NotificationsListener.hasPermission) ?? false;
  }

  /// Registra el callback de background. Llamar una vez al inicio.
  static void initialize() {
    NotificationsListener.initialize(callbackHandle: backgroundCallback);
  }

  static Future<bool> isRunning() async {
    return (await NotificationsListener.isRunning) ?? false;
  }

  /// Enciende el servicio. Devuelve true si quedó activo.
  static Future<bool> start() async {
    return (await NotificationsListener.startService()) ?? false;
  }

  /// Apaga el servicio. Devuelve true si quedó detenido.
  static Future<bool> stop() async {
    return (await NotificationsListener.stopService()) ?? false;
  }

  static void openSettings() {
    NotificationsListener.openPermissionSettings();
  }
}