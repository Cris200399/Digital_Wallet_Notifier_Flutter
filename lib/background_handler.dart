import 'package:flutter/widgets.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'constants.dart';
import 'services/config_service.dart';
import 'services/log_service.dart';
import 'services/history_service.dart';
import 'services/telegram_service.dart';

/// Callback que corre en el ISOLATE DE BACKGROUND (incluso con la app cerrada).
/// DEBE ser una función top-level y estar anotada con @pragma('vm:entry-point'),
/// o el compilador AOT la elimina y el servicio falla.
@pragma('vm:entry-point')
void backgroundCallback(NotificationEvent evt) async {
  // Asegura que los plugins estén disponibles en este isolate.
  WidgetsFlutterBinding.ensureInitialized();
  await procesarNotificacion(evt);
}

/// Extrae los datos de la notificación y delega en procesarPago.
Future<void> procesarNotificacion(NotificationEvent evt) async {
  final pkg = evt.packageName ?? "";
  final cuerpo = evt.text ?? "";
  // timestamp de la notificación (ms desde epoch). Fallback: ahora.
  final ts = evt.timestamp ?? DateTime.now().millisecondsSinceEpoch;
  await procesarPago(pkg: pkg, cuerpo: cuerpo, timestamp: ts);
}

/// Lógica central: filtra, respeta el horario, parsea, registra y envía.
/// Es top-level para poder reutilizarla en la prueba manual desde la UI.
Future<void> procesarPago({
  required String pkg,
  required String cuerpo,
  required int timestamp,
}) async {
  await LogService.log("Notif. pkg=$pkg | text='$cuerpo'");

  // 1. Filtro por app de origen
  if (!Constants.monitoredPackages.contains(pkg)) return;

  // 2. Descarta notificaciones de grupo/resumen (sin monto)
  if (cuerpo.isEmpty || !cuerpo.contains(Constants.monedaMarcador)) {
    await LogService.log(
      "Descartada (vacía o sin '${Constants.monedaMarcador}').",
    );
    return;
  }

  // 3. Filtro por horario
  final now = DateTime.fromMillisecondsSinceEpoch(timestamp);
  if (!await ConfigService.dentroDeHorario(now)) {
    await LogService.log("Fuera de horario, ignorado.");
    return;
  }

  // 4. Config (token + chats). Si no está lista, no podemos enviar.
  final cfg = await ConfigService.load();
  if (!cfg.isReady) {
    await LogService.log("Sin configuración cargada. Ignorado.");
    return;
  }

  // 5. Parsing del monto y el nombre
  final match = RegExp(r'S/\s*(\d+(?:\.\d+)?)').firstMatch(cuerpo);
  final monto = match != null ? "S/ ${match.group(1)}" : "—";
  final nombre = extraerNombre(cuerpo);
  final hora = _formatDate(now);

  // 6. Registrar en historial local (ahora con nombre)
  await HistoryService.add(
    PagoRegistro(
      monto: monto,
      nombre: nombre,
      detalle: cuerpo,
      timestamp: timestamp,
    ),
  );

  // 7. Construir y enviar el mensaje
  final detalle = _escapeHtml(cuerpo);
  final mensaje =
      "<b>Nuevo pago recibido</b>\n\n"
      "💰 <b>Monto:</b> $monto\n"
      "🕐 <b>Hora:</b> $hora\n"
      "📝 <b>Detalle:</b> $detalle";

  await TelegramService.send(
    botToken: cfg.botToken!,
    chatIds: cfg.chatIds,
    messages: mensaje,
  );
}

String _formatDate(DateTime dt) {
  String dos(int n) => n.toString().padLeft(2, '0');
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return "${dos(dt.day)}/${dos(dt.month)}/${dt.year} "
      "${dos(hour12)}:${dos(dt.minute)} $period";
}

String extraerNombre(String texto) {
  // Captura lo que va antes de "te envió"
  final m = RegExp(r'(?:Yape!\s*)?(.+?)\s+te envió').firstMatch(texto);
  if (m == null) return "Desconocido";
  return m.group(1)!.trim();
}

String _escapeHtml(String t) =>
    t.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
