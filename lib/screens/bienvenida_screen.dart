import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'registro_screen.dart';

/// P01 · Bienvenida.
/// Pantalla de entrada: fondo Marea, marca, lema y los dos caminos
/// (crear cuenta o iniciar sesión). Único botón Sol de la pantalla.
class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          children: [
              const SizedBox(height: 48),
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'images/stitch_borrowapp_ui_system_design/image.png_1/screen.png',
                  width: 230,
                  height: 176,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 22),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    color: BColors.tinta,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    TextSpan(text: 'Borrow'),
                    TextSpan(text: 'App', style: TextStyle(color: BColors.laguna700)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: BColors.laguna200),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '• Comunidad colaborativa',
                  style: TextStyle(color: BColors.laguna700, fontSize: 12),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Comparte lo que tienes, encuentra lo\nque necesitas',
                textAlign: TextAlign.center,
                style: TextStyle(color: BColors.tinta2, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 90),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistroScreen()),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Crear cuenta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BColors.sol500,
                    foregroundColor: BColors.tinta,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Iniciar sesión'),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Hecho para comunidades universitarias y locales',
                style: TextStyle(color: BColors.tinta3, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
