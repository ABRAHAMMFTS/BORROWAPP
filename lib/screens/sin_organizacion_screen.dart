import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'unirme_paso_1_screen.dart';
import 'crear_organizacion_screen.dart';

// P03: Sin organización
// Muestra dos tarjetas grandes para unirse o crear una organización.
class SinOrganizacionScreen extends StatelessWidget {
  const SinOrganizacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Ilustración temporal del concepto "El Encuentro".
              Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: BColors.bruma,
                ),
                child: const Icon(Icons.groups, size: 80, color: BColors.laguna500),
              ),
              const SizedBox(height: 32),
              const Text(
                'Aún no perteneces a\nninguna organización',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: BColors.tinta,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'BorrowApp funciona a través de comunidades cerradas como tu universidad, empresa o condominio.',
                textAlign: TextAlign.center,
                style: TextStyle(color: BColors.tinta2),
              ),
              const SizedBox(height: 40),
              // Tarjeta 1: Unirse con código
              _buildActionCard(
                context,
                title: 'Unirme con un código',
                subtitle: 'Código de 5 caracteres provisto por tu administrador',
                icon: Icons.login,
                iconBgColor: BColors.laguna100,
                iconColor: BColors.laguna700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UnirmePaso1Screen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Tarjeta 2: Crear organización
              _buildActionCard(
                context,
                title: 'Crear mi organización',
                subtitle: 'Tú la administras y recibes el código para los demás',
                icon: Icons.add_business,
                iconBgColor: BColors.sol100,
                iconColor: BColors.solTexto,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CrearOrganizacionScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BColors.linea),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: BColors.tinta2, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: BColors.tinta3),
          ],
        ),
      ),
    );
  }
}
