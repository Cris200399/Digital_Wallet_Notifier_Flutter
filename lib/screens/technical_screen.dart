import 'package:flutter/material.dart';
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
  Horario _horario = Horario(activo: false, inicio: 8, fin: 22);
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

  Future<void> _cargarComercio() async {
    final id = _comercioIdCtrl.text.trim();
    if (id.isEmpty) {
      _snack("Ingresa el ID del comercio.");
      return;
    }
    setState(() => _cargandoComercio = true);
    try {
      final c = await BackendService.getComercio(jwt: widget.jwt, comercioId: id);
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
    const textoFalso =
        "Cristopher Ron* te envió un pago por S/ 0.1. El cód. de seguridad es: 200";
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
                  inicio: _horario.inicio,
                  fin: _horario.fin,
                ),
              ),
            ),
            if (_horario.activo) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _dropdownHora("Desde", _horario.inicio, (v) {
                    setState(() => _horario = Horario(
                        activo: true, inicio: v, fin: _horario.fin));
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _dropdownHora("Hasta", _horario.fin, (v) {
                    setState(() => _horario = Horario(
                        activo: true, inicio: _horario.inicio, fin: v));
                  })),
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

  Widget _dropdownHora(String label, int valor, ValueChanged<int> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: valor,
          isExpanded: true,
          items: [
            for (int h = 0; h < 24; h++)
              DropdownMenuItem(
                value: h,
                child: Text("${h.toString().padLeft(2, '0')}:00"),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}