import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// P16: Panel de administración
class PanelAdministracionScreen extends StatelessWidget {
  const PanelAdministracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
      ),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Cuadrícula de estadísticas
              Row(
                children: [
                  _buildStatCard('48', 'Miembros', Icons.people),
                  const SizedBox(width: 16),
                  _buildStatCard('12', 'Préstamos', Icons.handshake),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard('6', 'Necesidades', Icons.search),
                  const SizedBox(width: 16),
                  _buildStatCard('3', 'Reportes', Icons.warning, isAlert: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, {bool isAlert = false}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(icon, color: isAlert ? BColors.error : BColors.laguna700, size: 32),
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Bricolage',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isAlert ? BColors.error : BColors.tinta,
                ),
              ),
              Text(label, style: const TextStyle(color: BColors.tinta2)),
            ],
          ),
        ),
      ),
    );
  }
}
