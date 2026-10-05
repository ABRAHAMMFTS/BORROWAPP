import 'package:flutter/material.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import 'unirme_paso_2_screen.dart';

// P04: Unirme paso 1
// Casillas de código en el centro
class UnirmePaso1Screen extends StatefulWidget {
  const UnirmePaso1Screen({super.key});

  @override
  State<UnirmePaso1Screen> createState() => _UnirmePaso1ScreenState();
}

class _UnirmePaso1ScreenState extends State<UnirmePaso1Screen> {
  final _codigoCtrl = TextEditingController();
  String? _error;
  bool _cargando = false;

  Future<void> _siguiente() async {
    setState(() => _error = null);
    if (_codigoCtrl.text.trim().length != 5) {
      setState(() => _error = 'Escribe un código de 5 caracteres.');
      return;
    }
    setState(() => _cargando = true);
    try {
      final organizacion =
          await Servicios.i.organizaciones.buscarPorCodigo(_codigoCtrl.text);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UnirmePaso2Screen(organizacion: organizacion),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unirme (Paso 1)'),
        backgroundColor: BColors.sal,
      ),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Ingresa el código',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Un único campo mantiene el código accesible y se presenta como casillas.
              TextField(
                controller: _codigoCtrl,
                textAlign: TextAlign.center,
                maxLength: 5,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontSize: 32, letterSpacing: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  if (val.length == 5) _siguiente();
                },
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: BColors.error)),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('¿Qué es un código?'),
                    content: Text(
                      'Es el código de cinco caracteres que te entrega el administrador de tu comunidad.',
                    ),
                  ),
                ),
                child: const Text('¿Qué es un código?'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _siguiente,
                  child: const Text('Siguiente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
