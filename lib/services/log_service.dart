import 'dart:io';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';

/// Logging a archivo, usable desde el isolate de background.
class LogService {
  static const String _fileName = "dwn_log.txt";

  static Future<File?> _file() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$_fileName');
    } catch (e) {
      developer.log("No se pudo obtener el directorio de logs: $e");
      return null;
    }
  }

  static Future<void> log(String message) async {
    final ts = DateTime.now().toIso8601String();
    final line = "[$ts] $message";
    developer.log(line);
    final f = await _file();
    if (f == null) return;
    try {
      await f.writeAsString("$line\n", mode: FileMode.append);
    } catch (e) {
      developer.log("Error escribiendo log: $e");
    }
  }

  static Future<String> read() async {
    final f = await _file();
    if (f == null) return "No se pudo acceder al archivo de logs.";
    try {
      if (await f.exists()) return await f.readAsString();
      return "Sin registros todavía.";
    } catch (e) {
      return "Error leyendo logs: $e";
    }
  }

  static Future<void> clear() async {
    final f = await _file();
    if (f == null) return;
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}