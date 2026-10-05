import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'inicio_screen.dart';

// P14: Préstamo activo (Stepper)
class PrestamoActivoScreen extends StatelessWidget {
  const PrestamoActivoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préstamo (Activo)'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const InicioScreen()),
              (route) => false,
            );
          },
        ),
      ),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: Column(
          children: [
            // Stepper simplificado
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.check_circle, color: BColors.laguna700),
                  Expanded(
                    child: Divider(color: BColors.laguna700, thickness: 2),
                  ),
                  Icon(
                    Icons.directions_walk,
                    color: BColors.laguna700,
                  ), // En curso
                  Expanded(child: Divider(color: BColors.linea, thickness: 2)),
                  Icon(Icons.check_circle_outline, color: BColors.lineaFuerte),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Detalles del préstamo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.handyman, color: BColors.laguna700),
                        title: Text('Taladro percutor'),
                        subtitle: Text('Préstamo activo'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Botón de confirmación (Ej: Marcar devuelto)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La devolución se confirma en el Punto Central.',
                                ),
                              ),
                            ),
                        child: const Text('Marcar como devuelto'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
