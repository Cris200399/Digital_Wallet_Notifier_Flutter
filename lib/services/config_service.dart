import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

/// Configuración operativa cargada del almacenamiento.
class AppConfig {
  final String? botToken;
  final List<String> chatIds;
  final String? comercioNombre;
  final String? comercioId;

  AppConfig({
    this.botToken,
    this.chatIds = const [],
    this.comercioNombre,
    this.comercioId,
  });

  bool get isReady =>
      botToken != null && botToken!.isNotEmpty && chatIds.isNotEmpty;
}

/// Horario de escucha. Si [activo] es false, escucha 24/7.
class Horario {
  final bool activo;
  final int inicio; // hora 0-23
  final int fin; // hora 0-23

  Horario({required this.activo, required this.inicio, required this.fin});
}

/// Lee y escribe la configuración en SharedPreferences.
///
/// Todos los métodos son estáticos para poder usarse tanto desde la UI como
/// desde el isolate de background. Se llama a reload() antes de leer para
/// evitar leer una copia cacheada desde el background.
class ConfigService {
  static Future<AppConfig> load() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return AppConfig(
      botToken: p.getString(Constants.kBotToken),
      chatIds: p.getStringList(Constants.kChatIds) ?? const [],
      comercioNombre: p.getString(Constants.kComercioNombre),
      comercioId: p.getString(Constants.kComercioId),
    );
  }

  static Future<void> saveComercio({
    required String id,
    required String nombre,
    required String botToken,
    required List<String> chatIds,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(Constants.kComercioId, id);
    await p.setString(Constants.kComercioNombre, nombre);
    await p.setString(Constants.kBotToken, botToken);
    await p.setStringList(Constants.kChatIds, chatIds);
  }

  static Future<Horario> getHorario() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return Horario(
      activo: p.getBool(Constants.kHorarioActivo) ?? false,
      inicio: p.getInt(Constants.kHoraInicio) ?? 8,
      fin: p.getInt(Constants.kHoraFin) ?? 22,
    );
  }

  static Future<void> setHorario(Horario h) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(Constants.kHorarioActivo, h.activo);
    await p.setInt(Constants.kHoraInicio, h.inicio);
    await p.setInt(Constants.kHoraFin, h.fin);
  }

  /// Indica si [now] cae dentro del horario configurado.
  /// Soporta rangos que cruzan medianoche (ej. 22 a 6).
  static Future<bool> dentroDeHorario(DateTime now) async {
    final h = await getHorario();
    if (!h.activo) return true;
    final hora = now.hour;
    if (h.inicio <= h.fin) {
      return hora >= h.inicio && hora < h.fin;
    }
    return hora >= h.inicio || hora < h.fin;
  }
}