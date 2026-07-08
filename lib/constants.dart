/// Configuración global y claves de almacenamiento.
class Constants {
  // ==========================================================
  // URL base de tu backend (sin slash final).
  // - Producción: https://tu-backend.onrender.com
  // - Emulador Android en local: http://10.0.2.2:3000
  // ==========================================================
  static const String backendBaseUrl = "https://digital-wallet-notifier-backend.onrender.com";

  // Paquetes de apps de billetera a monitorear.
  static const List<String> monitoredPackages = [
    "com.bcp.innovacxion.yapeapp", // Yape
    // Agrega aquí otras billeteras si las necesitas.
  ];

  // Texto que debe contener la notificación para considerarla un pago.
  static const String monedaMarcador = "S/";

  // ---- Claves de SharedPreferences ----
  static const String kBotToken = "cfg_bot_token";
  static const String kChatIds = "cfg_chat_ids";
  static const String kComercioNombre = "cfg_comercio_nombre";
  static const String kComercioId = "cfg_comercio_id";
  static const String kHorarioActivo = "cfg_horario_activo";
  static const String kHoraInicio = "cfg_hora_inicio";
  static const String kHoraFin = "cfg_hora_fin";
  static const String kHistory = "cfg_history";
}