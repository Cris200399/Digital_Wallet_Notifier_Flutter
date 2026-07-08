import 'dart:async';

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/config_service.dart';
import '../services/history_service.dart';
import 'technical_login_screen.dart';

/// Pantalla principal, visible para el dueño del comercio.
/// Minimalista: estado del servicio, un botón para encender/apagar,
/// y el historial de los últimos pagos capturados.
///
/// Acceso oculto a la parte técnica: mantener presionado el título.
class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  bool _permiso = false;
  bool _activo = false;
  bool _cargando = true;
  Horario? _horario;
  List<PagoRegistro> _historial = const [];

  Timer? _techTimer;
  final Duration _techLongPressDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
    _cargarEstado();
  }

  void _startTechLongPress() {
    _techTimer?.cancel();
    _techTimer = Timer(_techLongPressDuration, _abrirTecnico);
  }

  void _cancelTechLongPress([_]) {
    _techTimer?.cancel();
    _techTimer = null;
  }


  Future<void> _cargarEstado() async {
    final permiso = await NotificationService.hasPermission();
    final activo = await NotificationService.isRunning();
    final horario = await ConfigService.getHorario();
    final historial = await HistoryService.load();
    if (!mounted) return;
    setState(() {
      _permiso = permiso;
      _activo = activo;
      _horario = horario;
      _historial = historial;
      _cargando = false;
    });
  }

  Future<void> _toggle() async {
    if (!_permiso) {
      NotificationService.openSettings();
      return;
    }
    setState(() => _cargando = true);
    final nuevoEstado = _activo
        ? !(await NotificationService.stop())
        : await NotificationService.start();
    if (!mounted) return;
    setState(() {
      _activo = nuevoEstado;
      _cargando = false;
    });
  }

  Future<void> _abrirTecnico() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TechnicalLoginScreen()),
    );
    // Al volver, recargamos por si cambió la config/horario.
    _cargarEstado();
  }

  Future<void> _borrarItem(int index) async {
    final eliminado = _historial[index];
    // Actualiza la UI de inmediato
    setState(() => _historial.removeAt(index));
    // Persiste el cambio
    await HistoryService.removeAt(index);
    // Ofrece deshacer
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Pago de ${eliminado.monto} eliminado"),
        action: SnackBarAction(
          label: "Deshacer",
          onPressed: () async {
            await HistoryService.add(eliminado);
            _cargarEstado();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _techTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTapDown: (_) => _startTechLongPress(),
          onTapUp: (_) => _cancelTechLongPress(),
          onTapCancel: _cancelTechLongPress,
          child: const Text('Digital Wallet Notifier'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarEstado,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _tarjetaEstado(scheme),
            const SizedBox(height: 20),
            _botonPrincipal(),
            const SizedBox(height: 32),
            _seccionHistorial(),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaEstado(ColorScheme scheme) {
    final Color color = !_permiso
        ? Colors.orange
        : (_activo ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF));
    final String titulo = !_permiso
        ? "Permiso pendiente"
        : (_activo ? "Escuchando" : "Detenido");
    final String subtitulo = !_permiso
        ? "Falta el acceso a notificaciones"
        : (_activo ? _textoHorario() : "El servicio está apagado");

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _textoHorario() {
    final h = _horario;
    if (h == null || !h.activo) return "Activo las 24 horas";
    String dos(int n) => n.toString().padLeft(2, '0');
    return "Activo de ${dos(h.inicio)}:00 a ${dos(h.fin)}:00";
  }

  Widget _botonPrincipal() {
    if (_cargando) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final String texto = !_permiso
        ? "Otorgar permiso"
        : (_activo ? "Detener servicio" : "Iniciar servicio");
    return FilledButton(onPressed: _toggle, child: Text(texto));
  }

  Widget _seccionHistorial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Últimos pagos",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ),
        if (_historial.isEmpty)
          _historialVacio()
        else
          Card(
            clipBehavior: Clip.antiAlias,
            // para que el fondo rojo respete las esquinas
            child: Column(
              children: [
                for (int i = 0; i < _historial.length; i++) ...[
                  Dismissible(
                    key: ValueKey("${_historial[i].timestamp}_$i"),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: const Color(0xFFDC2626),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (_) => _borrarItem(i),
                    child: _filaPago(_historial[i]),
                  ),
                  if (i < _historial.length - 1)
                    const Divider(indent: 20, endIndent: 20),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _historialVacio() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Text(
            "Aún no se han capturado pagos",
            style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }

  Widget _filaPago(PagoRegistro p) {
    final f = p.fecha;
    String dos(int n) => n.toString().padLeft(2, '0');
    final fechaTexto =
        "${dos(f.day)}/${dos(f.month)} · ${dos(f.hour)}:${dos(f.minute)}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.monto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fechaTexto,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
