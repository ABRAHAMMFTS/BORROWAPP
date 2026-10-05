import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'prestamo_activo_screen.dart';

// P13: Confirmar aceptación
class ConfirmarAceptacionScreen extends StatelessWidget {
  const ConfirmarAceptacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 80, color: BColors.sol400),
            const SizedBox(height: 24),
            const Text(
              '¿Aceptar estas condiciones?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Al aceptar, las demás ofertas pendientes para esta necesidad serán cerradas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: BColors.tinta2),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const PrestamoActivoScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Sí, aceptar'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
