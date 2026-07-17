import 'package:flutter/material.dart';
import '../services/history_service.dart';
import 'ui_kit.dart';

/// Tarjeta de un pago en el historial, con profundidad y jerarquía visual.
/// Monto grande a la izquierda, nombre y hora a la derecha, con un avatar
/// de inicial y un acento de color.
class PagoCard extends StatelessWidget {
  final PagoRegistro pago;

  const PagoCard({super.key, required this.pago});

  Widget _badgeOrigen(String origen) {
    // Color según la billetera
    Color color;
    switch (origen) {
      case "Yape":
        color = const Color(0xFF6E3FA3); // morado Yape
        break;
      case "Plin":
        color = const Color(0xFF00B2A9); // turquesa Plin
        break;
      default:
        color = AppColors.navy;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        origen,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = pago.fecha;
    String dos(int n) => n.toString().padLeft(2, '0');

    // Hora 12h
    final h24 = f.hour;
    final ampm = h24 < 12 ? "AM" : "PM";
    int h12 = h24 % 12;
    if (h12 == 0) h12 = 12;
    final fechaTexto =
        "${dos(f.day)}/${dos(f.month)} · ${dos(h12)}:${dos(f.minute)} $ampm";

    final inicial = pago.nombre.trim().isNotEmpty
        ? pago.nombre.trim()[0].toUpperCase()
        : "?";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DepthCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Avatar con inicial
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.teal, AppColors.navy],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                inicial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Nombre + hora
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pago.nombre.isNotEmpty ? pago.nombre : "Pago recibido",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _badgeOrigen(pago.origen),
                  const SizedBox(height: 3),
                  Text(
                    fechaTexto,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Monto destacado
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pago.monto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}