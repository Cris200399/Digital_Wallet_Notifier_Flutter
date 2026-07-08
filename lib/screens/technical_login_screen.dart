import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import 'technical_screen.dart';

/// Puerta de acceso a la parte técnica. La contraseña se valida contra el
/// backend; si es correcta, se recibe un JWT y se entra al panel técnico.
class TechnicalLoginScreen extends StatefulWidget {
  const TechnicalLoginScreen({super.key});

  @override
  State<TechnicalLoginScreen> createState() => _TechnicalLoginScreenState();
}

class _TechnicalLoginScreenState extends State<TechnicalLoginScreen> {
  final _nombreCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;
  String _estado = "";
  bool _verPass = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _error = null;
      _estado = "Conectando con el servidor...";
    });
    try {
      await BackendService.wakeUp();
      if (!mounted) return;
      setState(() => _estado = "Verificando credenciales...");
      final jwt = await BackendService.login(
        nombre: _nombreCtrl.text,
        password: _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TechnicalScreen(jwt: jwt)),
      );
    } on BackendException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _cargando = false;
        _estado = "";
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Error inesperado.";
        _cargando = false;
        _estado = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso técnico')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nombreCtrl,
                    enabled: !_cargando,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Usuario'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passCtrl,
                    enabled: !_cargando,
                    obscureText: !_verPass,
                    onSubmitted: (_) => _cargando ? null : _ingresar(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _verPass ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _verPass = !_verPass),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_cargando)
            Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  _estado,
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
                ),
              ],
            )
          else
            FilledButton(
              onPressed: _ingresar,
              child: const Text('Ingresar'),
            ),
          const SizedBox(height: 12),
          Text(
            "La primera conexión puede tardar unos segundos mientras el "
                "servidor se activa.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}