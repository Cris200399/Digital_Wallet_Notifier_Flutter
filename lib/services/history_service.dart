import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

/// Un pago capturado, guardado localmente en el dispositivo.
class PagoRegistro {
  final String monto;
  final String detalle;
  final int timestamp; // milisegundos desde epoch

  PagoRegistro({
    required this.monto,
    required this.detalle,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'monto': monto,
    'detalle': detalle,
    'ts': timestamp,
  };

  factory PagoRegistro.fromJson(Map<String, dynamic> j) => PagoRegistro(
    monto: (j['monto'] ?? '') as String,
    detalle: (j['detalle'] ?? '') as String,
    timestamp: (j['ts'] ?? 0) as int,
  );

  DateTime get fecha => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

/// Historial local de pagos. Vive solo en el dispositivo del comercio;
/// nunca se envía al backend (minimización de datos).
class HistoryService {
  static const int _maxItems = 50;

  static Future<List<PagoRegistro>> load() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    final raw = p.getStringList(Constants.kHistory) ?? const [];
    final result = <PagoRegistro>[];
    for (final s in raw) {
      try {
        result.add(PagoRegistro.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // ignoramos entradas corruptas
      }
    }
    return result;
  }

  static Future<void> removeAt(int index) async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    final raw = p.getStringList(Constants.kHistory) ?? <String>[];
    if (index >= 0 && index < raw.length) {
      raw.removeAt(index);
      await p.setStringList(Constants.kHistory, raw);
    }
  }

  static Future<void> add(PagoRegistro pago) async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    final raw = p.getStringList(Constants.kHistory) ?? <String>[];
    raw.insert(0, jsonEncode(pago.toJson()));
    if (raw.length > _maxItems) {
      raw.removeRange(_maxItems, raw.length);
    }
    await p.setStringList(Constants.kHistory, raw);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(Constants.kHistory, <String>[]);
  }
}