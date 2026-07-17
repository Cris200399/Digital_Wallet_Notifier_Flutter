import 'package:flutter/material.dart';
import 'package:yape_notifier/screens/stats_screen.dart';
import '../constants.dart';
import '../background_handler.dart';
import '../services/backend_service.dart';
import '../services/config_service.dart';
import '../services/log_service.dart';

/// Panel técnico (solo tú, tras validar contraseña).
/// Permite cargar la config del comercio desde el backend, definir el
/// horario, probar el envío y revisar los logs.
class TechnicalScreen extends StatefulWidget {
  final String jwt;

  const TechnicalScreen({super.key, required this.jwt});

  @override
  State<TechnicalScreen> createState() => _TechnicalScreenState();
}

class _TechnicalScreenState extends State<TechnicalScreen> {
  final _comercioIdCtrl = TextEditingController();

  AppConfig? _config;
  Horario _horario = Horario(
    activo: false,
    horaInicio: 8,
    minInicio: 0,
    horaFin: 22,
    minFin: 0,
  );
  bool _cargandoComercio = false;

  @override
  void initState() {
    super.initState();
    _cargarActual();
  }

  @override
  void dispose() {
    _comercioIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarActual() async {
    final cfg = await ConfigService.load();
    final h = await ConfigService.getHorario();
    if (!mounted) return;
    setState(() {
      _config = cfg;
      _horario = h;
      if (cfg.comercioId != null) _comercioIdCtrl.text = cfg.comercioId!;
    });
  }

  Future<void> _elegirHora({required bool esInicio}) async {
    final inicial = esInicio
        ? TimeOfDay(hour: _horario.horaInicio, minute: _horario.minInicio)
        : TimeOfDay(hour: _horario.horaFin, minute: _horario.minFin);

    final elegida = await showTimePicker(
      context: context,
      initialTime: inicial,
    );
    if (elegida == null) return;

    setState(() {
      if (esInicio) {
        _horario = Horario(
          activo: true,
          horaInicio: elegida.hour,
          minInicio: elegida.minute,
          horaFin: _horario.horaFin,
          minFin: _horario.minFin,
        );
      } else {
        _horario = Horario(
          activo: true,
          horaInicio: _horario.horaInicio,
          minInicio: _horario.minInicio,
          horaFin: elegida.hour,
          minFin: elegida.minute,
        );
      }
    });
  }

  Widget _selectorHora(String label, bool esInicio) {
    String dos(int n) => n.toString().padLeft(2, '0');
    final h = esInicio ? _horario.horaInicio : _horario.horaFin;
    final m = esInicio ? _horario.minInicio : _horario.minFin;

    return InkWell(
      onTap: () => _elegirHora(esInicio: esInicio),
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          "${dos(h)}:${dos(m)}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Future<void> _cargarComercio() async {
    final id = _comercioIdCtrl.text.trim();
    if (id.isEmpty) {
      _snack("Ingresa el ID del comercio.");
      return;
    }
    setState(() => _cargandoComercio = true);
    try {
      final c = await BackendService.getComercio(
        jwt: widget.jwt,
        comercioId: id,
      );
      await ConfigService.saveComercio(
        id: c.id,
        nombre: c.nombre,
        botToken: c.botToken,
        chatIds: c.chatIds,
      );
      await _cargarActual();
      _snack("Configuración de \"${c.nombre}\" cargada.");
    } on BackendException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _cargandoComercio = false);
    }
  }

  Future<void> _guardarHorario() async {
    await ConfigService.setHorario(_horario);
    _snack("Horario guardado.");
  }

  Future<void> _probarEnvio() async {
    const textoFalso = "Monto yapeado de prueba. S/xx";
    await procesarPago(
      pkg: Constants.monitoredPackages.first,
      cuerpo: textoFalso,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _snack("Prueba ejecutada. Revisa los logs y el historial.");
  }

  Future<void> _verLogs() async {
    final contenido = await LogService.read();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logs"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              contenido,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await LogService.clear();
              if (ctx.mounted) Navigator.pop(ctx);
              _snack("Logs limpiados.");
            },
            child: const Text("Limpiar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel técnico')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _seccion("Comercio", [
            TextField(
              controller: _comercioIdCtrl,
              decoration: const InputDecoration(labelText: 'ID del comercio'),
            ),
            const SizedBox(height: 12),
            _cargandoComercio
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : FilledButton(
                    onPressed: _cargarComercio,
                    child: const Text('Cargar configuración'),
                  ),
            const SizedBox(height: 8),
            _resumenConfig(),
          ]),
          const SizedBox(height: 20),
          _seccion("Horario", [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activar horario'),
              subtitle: const Text('Si está apagado, escucha las 24 horas'),
              value: _horario.activo,
              onChanged: (v) => setState(
                () => _horario = Horario(
                  activo: v,
                  horaInicio: _horario.horaInicio,
                  minInicio: _horario.minInicio,
                  horaFin: _horario.horaFin,
                  minFin: _horario.minFin,
                ),
              ),
            ),
            if (_horario.activo) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _selectorHora("Desde", true)),
                  const SizedBox(width: 12),
                  Expanded(child: _selectorHora("Hasta", false)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _guardarHorario,
              child: const Text('Guardar horario'),
            ),
          ]),
          const SizedBox(height: 20),
          _seccion("Diagnóstico", [
            OutlinedButton.icon(
              onPressed: _probarEnvio,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Probar envío'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _verLogs,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Ver logs'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              ),
              icon: const Icon(Icons.bar_chart_outlined),
              label: const Text('Ver estadísticas'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _seccion(String titulo, List<Widget> hijos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: hijos,
            ),
          ),
        ),
      ],
    );
  }

  Widget _resumenConfig() {
    final cfg = _config;
    if (cfg == null || !cfg.isReady) {
      return Text(
        "Sin configuración cargada.",
        style: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
      );
    }
    final tokenEnmasc = cfg.botToken!.length > 8
        ? "${cfg.botToken!.substring(0, 8)}••••••"
        : "••••••";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lineaInfo("Nombre", cfg.comercioNombre ?? "—"),
        _lineaInfo("Token", tokenEnmasc),
        _lineaInfo("Chats", "${cfg.chatIds.length} configurado(s)"),
      ],
    );
  }

  Widget _lineaInfo(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              k,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
            ),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

}
