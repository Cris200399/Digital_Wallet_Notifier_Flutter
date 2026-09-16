import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import '../background_handler.dart';

/// Envuelve las llamadas al plugin de listener de notificaciones.
class NotificationService {
  /// Flag para pausar/reanudar la escucha sin detener el servicio
  static bool _pausado = false;

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
    _pausado = false;
    return (await NotificationsListener.startService()) ?? false;
  }

  /// PAUSA la escucha sin detener el servicio.
  /// El listener sigue corriendo pero ignora los pagos.
  static Future<bool> pause() async {
    _pausado = true;
    return true;
  }

  /// Reanuda la escucha.
  static Future<bool> resume() async {
    _pausado = false;
    return true;
  }

  /// Verifica si está pausado.
  static bool estaPausado() => _pausado;

  /// NUNCA llamar a stopService() - eso rompe todo
  /// En su lugar usa pause()
  static Future<bool> stop() async {
    return pause();
  }

  static void openSettings() {
    NotificationsListener.openPermissionSettings();
  }
}