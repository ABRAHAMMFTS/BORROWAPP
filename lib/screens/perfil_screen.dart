import 'package:flutter/material.dart';

import '../services/servicios.dart';
import '../theme/app_theme.dart';
import 'bienvenida_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    final usuario = sesion.usuario;
    final organizacion = sesion.organizacionActiva;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      backgroundColor: BColors.sal,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: BColors.laguna100,
            child: Text(
              usuario?.nombre.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(fontSize: 30, color: BColors.laguna700),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              usuario?.nombre ?? 'Usuario',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              usuario?.correo ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 28),
          Card(
            child: ListTile(
              leading: const Icon(Icons.business, color: BColors.laguna700),
              title: const Text('Organización activa'),
              subtitle: Text(organizacion?.nombre ?? 'Sin organización'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.badge_outlined,
                color: BColors.laguna700,
              ),
              title: const Text('Identificador interno'),
              subtitle: Text(
                sesion.membresiaActiva?.identificadorInterno ?? 'No registrado',
              ),
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () {
              sesion.cerrarSesion();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const BienvenidaScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
