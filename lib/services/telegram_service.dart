import 'dart:async';
import 'package:http/http.dart' as http;
import 'log_service.dart';

/// Envía mensajes a Telegram vía la API de bots, con reintentos ante
/// fallos de red (ej. "Failed host lookup" cuando el equipo aún no tiene DNS).
class TelegramService {
  static Future<bool> enviar({
    required String botToken,
    required List<String> chatIds,
    required String mensaje,
  }) async {
    bool todoOk = true;
    for (final id in chatIds) {
      final ok = await _enviarA(botToken, id, mensaje);
      if (!ok) todoOk = false;
    }
    return todoOk;
  }

  static Future<bool> _enviarA(
      String botToken,
      String chatId,
      String mensaje,
      ) async {
    final url = Uri.parse("https://api.telegram.org/bot$botToken/sendMessage");

    for (int intento = 1; intento <= 3; intento++) {
      try {
        final resp = await http.post(
          url,
          body: {
            'chat_id': chatId,
            'text': mensaje,
            'parse_mode': 'HTML',
          },
        ).timeout(const Duration(seconds: 15));

        if (resp.statusCode == 200) {
          await LogService.log("Telegram $chatId -> 200 (intento $intento)");
          return true;
        }

        await LogService.log(
          "Telegram $chatId -> ${resp.statusCode}: ${resp.body}",
        );
        // Error del API (no de red). Solo reintentamos si es rate limit (429).
        if (resp.statusCode != 429) return false;
      } catch (e) {
        await LogService.log("Error de red $chatId (intento $intento): $e");
      }
      // Backoff antes de reintentar
      await Future.delayed(Duration(seconds: intento * 2));
    }
    return false;
  }
}