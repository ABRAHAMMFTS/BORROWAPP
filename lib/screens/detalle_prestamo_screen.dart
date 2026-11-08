import 'package:flutter/material.dart';

import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../widgets/componentes.dart';
import 'prestamo_activo_screen.dart';

/// Envoltorio que busca el préstamo por su `prestamoId` y delega en [PrestamoActivoScreen].
class DetallePrestamoScreen extends StatelessWidget {
  const DetallePrestamoScreen({super.key, required this.prestamoId});

  final int prestamoId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Prestamo?>(
      future: Servicios.i.prestamos.detalle(prestamoId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle del préstamo')),
            backgroundColor: BColors.sal,
            body: const Center(
              child: CircularProgressIndicator(color: BColors.laguna700),
            ),
          );
        }
        final p = snap.data;
        if (p == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle del préstamo')),
            backgroundColor: BColors.sal,
            body: const EstadoVacio(
              titulo: 'No encontramos este préstamo',
              texto: 'Puede que ya no exista.',
            ),
          );
        }
        return PrestamoActivoScreen(prestamo: p);
      },
    );
  }
}
