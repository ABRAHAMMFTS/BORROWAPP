import 'package:flutter/material.dart';

import '../services/servicios.dart';
import '../theme/app_theme.dart';
import 'sin_organizacion_screen.dart';

// P02: Registro
// Pantalla con campos sobre fondo Sal, botón fijo abajo.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _cargando = false;
  String? _error;

  Future<void> _registrar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await Servicios.i.sesion.registrar(
        _nombreCtrl.text,
        _correoCtrl.text,
        _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SinOrganizacionScreen()),
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
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Encabezado sencillo con flecha
        leading: const BackButton(),
        backgroundColor: BColors.sal,
        elevation: 0,
      ),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registro',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: BColors.tinta,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea una cuenta para compartir y pedir prestado',
                style: TextStyle(color: BColors.tinta2),
              ),
              const SizedBox(height: 32),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: BColors.error),
                  ),
                ),
              TextField(
                controller: _nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'NOMBRE COMPLETO',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'CORREO ELECTRÓNICO',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'CONTRASEÑA',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: const Icon(
                    Icons.visibility_off,
                    color: BColors.tinta3,
                  ),
                ),
              ),
              const Spacer(),
              // Botón primario fijo abajo
              SizedBox(
                width: double.infinity,
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _registrar,
                        child: const Text('Crear cuenta'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
