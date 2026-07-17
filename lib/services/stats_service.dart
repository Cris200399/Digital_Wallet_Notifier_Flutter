import 'log_service.dart';

/// Resultado del análisis de los logs.
class Estadisticas {
  // Tiempos de respuesta (ms)
  final int muestrasTiempo;
  final int promedioMs;
  final int minMs;
  final int maxMs;

  // Envíos
  final int enviosOk;
  final int enviosError;
  final int timeouts;

  // Pagos capturados
  final int pagosCapturados;
  final int pagosDescartados;

  const Estadisticas({
    required this.muestrasTiempo,
    required this.promedioMs,
    required this.minMs,
    required this.maxMs,
    required this.enviosOk,
    required this.enviosError,
    required this.timeouts,
    required this.pagosCapturados,
    required this.pagosDescartados,
  });

  int get totalEnvios => enviosOk + enviosError + timeouts;

  double get tasaExito =>
      totalEnvios == 0 ? 0 : (enviosOk / totalEnvios) * 100;

  bool get sinDatos => muestrasTiempo == 0 && totalEnvios == 0;

  static const Estadisticas vacia = Estadisticas(
    muestrasTiempo: 0, promedioMs: 0, minMs: 0, maxMs: 0,
    enviosOk: 0, enviosError: 0, timeouts: 0,
    pagosCapturados: 0, pagosDescartados: 0,
  );
}

/// Analiza el contenido del log y calcula métricas.
///
/// Se apoya en el formato que escribe TelegramService y background_handler:
///   "... -> 200 en 847ms ..."
///   "Timeout ... tras 1203ms ..."
///   "Error de red ... tras 900ms ..."
///   "Notif. pkg=... | text='...'"
///   "Descartada (vacía o sin 'S/')."
class StatsService {
  static Future<Estadisticas> calcular() async {
    final contenido = await LogService.read();
    if (contenido.isEmpty || contenido.startsWith("Sin registros")) {
      return Estadisticas.vacia;
    }

    final tiempos = <int>[];
    int ok = 0, error = 0, timeouts = 0;
    int capturados = 0, descartados = 0;

    // Tiempos de respuesta exitosos: "-> 200 en 847ms"
    final reTiempoOk = RegExp(r'->\s*200 en (\d+)ms');
    // Timeouts: "Timeout ... tras 1203ms"
    final reTimeout = RegExp(r'Timeout .* tras (\d+)ms');
    // Errores de red: "Error de red ... tras 900ms"
    final reErrorRed = RegExp(r'Error de red .* tras (\d+)ms');
    // Códigos de estado distintos de 200: "-> 429 en", "-> 400 en"
    final reOtroStatus = RegExp(r'->\s*(\d{3}) en \d+ms');

    for (final linea in contenido.split('\n')) {
      final mOk = reTiempoOk.firstMatch(linea);
      if (mOk != null) {
        ok++;
        tiempos.add(int.parse(mOk.group(1)!));
        continue;
      }
      if (reTimeout.hasMatch(linea)) {
        timeouts++;
        continue;
      }
      if (reErrorRed.hasMatch(linea)) {
        error++;
        continue;
      }
      final mOtro = reOtroStatus.firstMatch(linea);
      if (mOtro != null && mOtro.group(1) != "200") {
        error++;
        continue;
      }
      if (linea.contains("Notif. pkg=")) {
        capturados++;
        continue;
      }
      if (linea.contains("Descartada")) {
        descartados++;
        continue;
      }
    }

    if (tiempos.isEmpty && ok + error + timeouts == 0) {
      return Estadisticas.vacia;
    }

    int prom = 0, mn = 0, mx = 0;
    if (tiempos.isNotEmpty) {
      final suma = tiempos.reduce((a, b) => a + b);
      prom = (suma / tiempos.length).round();
      mn = tiempos.reduce((a, b) => a < b ? a : b);
      mx = tiempos.reduce((a, b) => a > b ? a : b);
    }

    return Estadisticas(
      muestrasTiempo: tiempos.length,
      promedioMs: prom,
      minMs: mn,
      maxMs: mx,
      enviosOk: ok,
      enviosError: error,
      timeouts: timeouts,
      pagosCapturados: capturados,
      pagosDescartados: descartados,
    );
  }
}