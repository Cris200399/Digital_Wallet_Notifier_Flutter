import 'package:flutter/material.dart';
import '../services/battery_service.dart';

/// Widget que muestra un aviso sobre optimización de batería
/// y permite al usuario configurarla fácilmente.
class BatteryWarningWidget extends StatefulWidget {
  const BatteryWarningWidget({super.key});

  @override
  State<BatteryWarningWidget> createState() => _BatteryWarningWidgetState();
}

class _BatteryWarningWidgetState extends State<BatteryWarningWidget> {
  bool _estaBateriaOptimizada = true;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _verificarBateria();
  }

  Future<void> _verificarBateria() async {
    final noOptimizada = await BatteryService.estaBateriaOptimizada();
    setState(() {
      _estaBateriaOptimizada = noOptimizada;
      _cargando = false;
    });
  }

  Future<void> _abrirConfiguracion() async {
    await BatteryService.abrirConfiguracionBateria();
    // Reverifica después de un delay (el usuario pudo cambiar la configuración)
    await Future.delayed(const Duration(seconds: 2));
    await _verificarBateria();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const SizedBox.shrink();
    }

    // Si la batería ya está optimizada (exenta), no muestra nada
    if (_estaBateriaOptimizada) {
      return const SizedBox.shrink();
    }

    // Muestra aviso si aún NO está exenta
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.battery_alert, color: Colors.amber[700], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Optimización de batería",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[900],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Para recibir pagos sin demoras, desactiva la optimización de batería para esta app.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _abrirConfiguracion,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text("Configurar ahora"),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}