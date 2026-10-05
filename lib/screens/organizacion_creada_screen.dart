import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../theme/app_theme.dart';
import 'inicio_screen.dart';

// P07: Organización creada
class OrganizacionCreadaScreen extends StatelessWidget {
  const OrganizacionCreadaScreen({super.key, required this.organizacion});

  final Organizacion organizacion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: marea),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(Icons.check_circle, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  '¡Organización creada!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text('Código generado:', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14), // Vidrio
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    organizacion.codigo.split('').join(' '),
                    style: TextStyle(fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar'),
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Código ${organizacion.codigo} copiado.')),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir'),
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código listo para compartir.')),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: BColors.sol400, foregroundColor: BColors.solTexto),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const InicioScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('Ir al inicio'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
