import 'package:flutter/material.dart';
import '../services/stats_service.dart';
import '../widgets/ui_kit.dart';

/// Pantalla de estadísticas (dentro del panel técnico).
/// Lee y analiza los logs para mostrar tiempos de respuesta, envíos,
/// tasa de éxito y conteo de pagos.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Estadisticas _stats = Estadisticas.vacia;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final s = await StatsService.calcular();
    if (!mounted) return;
    setState(() {
      _stats = s;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargando ? null : _cargar,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _stats.sinDatos
          ? _vacio()
          : _contenido(),
    );
  }

  Widget _vacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          "Aún no hay datos suficientes.\nLos envíos se registran a medida que "
              "llegan pagos.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
        ),
      ),
    );
  }

  Widget _contenido() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        // --- Tasa de éxito destacada, con gradiente ---
        _tarjetaTasaExito(),
        const SizedBox(height: 20),

        _titulo("Tiempos de respuesta"),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                valor: "${_stats.promedioMs} ms",
                etiqueta: "Promedio",
                icono: Icons.speed_outlined,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                valor: "${_stats.minMs} ms",
                etiqueta: "Más rápido",
                icono: Icons.arrow_downward,
                color: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                valor: "${_stats.maxMs} ms",
                etiqueta: "Más lento",
                icono: Icons.arrow_upward,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                valor: "${_stats.muestrasTiempo}",
                etiqueta: "Muestras",
                icono: Icons.functions,
                color: AppColors.navy,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _titulo("Envíos"),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                valor: "${_stats.enviosOk}",
                etiqueta: "Exitosos",
                icono: Icons.check_circle_outline,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                valor: "${_stats.timeouts}",
                etiqueta: "Timeouts",
                icono: Icons.timer_off_outlined,
                color: AppColors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                valor: "${_stats.enviosError}",
                etiqueta: "Errores",
                icono: Icons.error_outline,
                color: AppColors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                valor: "${_stats.totalEnvios}",
                etiqueta: "Total",
                icono: Icons.send_outlined,
                color: AppColors.navy,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _titulo("Pagos"),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                valor: "${_stats.pagosCapturados}",
                etiqueta: "Capturados",
                icono: Icons.notifications_active_outlined,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                valor: "${_stats.pagosDescartados}",
                etiqueta: "Descartados",
                icono: Icons.filter_alt_outlined,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tarjetaTasaExito() {
    final tasa = _stats.tasaExito;
    return DepthCard(
      padding: const EdgeInsets.all(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy, Color(0xFF1E6E7E)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tasa de éxito de envíos",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${tasa.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_stats.enviosOk} de ${_stats.totalEnvios} envíos",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: tasa / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const Icon(Icons.send, color: Colors.white, size: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _titulo(String t) {
    return Text(
      t,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.black.withValues(alpha: 0.6),
      ),
    );
  }
}