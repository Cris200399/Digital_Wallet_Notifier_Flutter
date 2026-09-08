import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/config_service.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';
import '../widgets/pago_card.dart';
import 'technical_login_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  bool _permiso = false;
  bool _activo = false;
  bool _cargando = true;
  bool _bateriaExenta = false;
  Horario? _horario;
  List<PagoRegistro> _historial = const [];

  Timer? _techTimer;
  final Duration _techLongPressDuration = const Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    final permiso = await NotificationService.hasPermission();
    final activo = await NotificationService.isRunning();
    final horario = await ConfigService.getHorario();
    final historial = await HistoryService.load();
    final bateriaExenta = await Permission.ignoreBatteryOptimizations.isGranted;

    if (!mounted) return;
    setState(() {
      _permiso = permiso;
      _activo = activo;
      _horario = horario;
      _historial = historial;
      _bateriaExenta = bateriaExenta;
      _cargando = false;
    });
  }

  Future<void> _abrirAjustesBateria() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    if (status.isDenied) {
      await openAppSettings();
    }
    _cargarEstado();
  }

  Future<void> _abrirAutoInicio() async {
    if (!Platform.isAndroid) return;
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final manufacturer = androidInfo.manufacturer.toLowerCase();

    // Intentar abrir pantallas específicas por fabricante
    bool lanzado = false;
    if (manufacturer.contains("xiaomi") || manufacturer.contains("redmi") || manufacturer.contains("poco")) {
      lanzado = await launchUrl(
        Uri.parse("intent://#Intent;action=miui.intent.action.OP_AUTO_START;end"),
      ).catchError((_) => false);
    } else if (manufacturer.contains("huawei") || manufacturer.contains("honor")) {
      lanzado = await launchUrl(
        Uri.parse("intent://#Intent;action=com.huawei.systemmanager.action.OP_AUTO_START;end"),
      ).catchError((_) => false);
    } else if (manufacturer.contains("oppo") || manufacturer.contains("realme")) {
      lanzado = await launchUrl(
        Uri.parse("intent://#Intent;action=com.coloros.safecenter;end"),
      ).catchError((_) => false);
    } else if (manufacturer.contains("vivo")) {
      lanzado = await launchUrl(
        Uri.parse("intent://#Intent;action=com.iqoo.secure;end"),
      ).catchError((_) => false);
    }

    // Fallback si no es de esas marcas o falla la intención
    if (!lanzado) {
      await openAppSettings();
    }
  }

  void _mostrarAjustesSegundoPlano() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Ajustes de Ejecución 24/7",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Configura estos permisos para asegurar que la app no sea cerrada por el sistema:",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Icon(
                      _permiso ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: _permiso ? Colors.green : Colors.orange,
                    ),
                    title: const Text("Acceso a Notificaciones"),
                    subtitle: const Text("Requerido para detectar los avisos de pago"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await NotificationService.openSettings;
                      await _cargarEstado();
                      setModalState(() {});
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      _bateriaExenta ? Icons.check_circle : Icons.battery_alert,
                      color: _bateriaExenta ? Colors.green : Colors.orange,
                    ),
                    title: const Text("Sin Optimización de Batería"),
                    subtitle: const Text("Evita que Android suspenda la app"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await _abrirAjustesBateria();
                      setModalState(() {});
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.autorenew, color: Colors.blue),
                    title: const Text("Permiso de Autoinicio"),
                    subtitle: const Text("Permite reiniciar el servicio al encender el móvil"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await _abrirAutoInicio();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startTechLongPress() {
    _techTimer?.cancel();
    _techTimer = Timer(_techLongPressDuration, _abrirTecnico);
  }

  void _cancelTechLongPress([_]) {
    _techTimer?.cancel();
    _techTimer = null;
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
    _cargarEstado();
  }

  Future<void> _borrarItem(int index) async {
    final eliminado = _historial[index];
    setState(() => _historial.removeAt(index));
    await HistoryService.removeAt(index);
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEDF1F6), Color(0xFFDDE4EC)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF17171A),
          title: GestureDetector(
            onTapDown: (_) => _startTechLongPress(),
            onTapUp: (_) => _cancelTechLongPress(),
            onTapCancel: _cancelTechLongPress,
            child: const Text('Digital Wallet Notifier'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: "Configuración de Ejecución",
              onPressed: _mostrarAjustesSegundoPlano,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _cargarEstado,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (!_bateriaExenta || !_permiso) _permissionBanner(),
              const SizedBox(height: 20),
              _tarjetaEstado(scheme),
              const SizedBox(height: 20),
              _botonPrincipal(),
              const SizedBox(height: 32),
              _seccionHistorial(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permissionBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Configuración recomendada",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "Para garantizar la recepción ininterrumpida de pagos, verifica los permisos en segundo plano.",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _mostrarAjustesSegundoPlano,
              icon: const Icon(Icons.settings_suggest),
              label: const Text("Configurar Segundo Plano"),
            ),
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
                      color: Colors.black.withOpacity(0.55),
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
    String format(int hour, int minute) {
      final ampm = hour < 12 ? "AM" : "PM";
      int h12 = hour % 12;
      if (h12 == 0) h12 = 12;
      return "${dos(h12)}:${dos(minute)} $ampm";
    }

    return "Activo de ${format(h.horaInicio, h.minInicio)} a ${format(h.horaFin, h.minFin)}";
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
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
        if (_historial.isEmpty)
          _historialVacio()
        else
          Card(
            clipBehavior: Clip.antiAlias,
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
                    child: PagoCard(pago: _historial[i]),
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
            style: TextStyle(color: Colors.black.withOpacity(0.4)),
          ),
        ),
      ),
    );
  }
}