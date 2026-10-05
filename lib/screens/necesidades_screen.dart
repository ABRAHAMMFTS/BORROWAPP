import 'package:flutter/material.dart';
import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import 'detalle_necesidad_screen.dart';
import 'publicar_necesidad_screen.dart';

/// P15 · Necesidades de la organización activa.
class NecesidadesScreen extends StatefulWidget {
  const NecesidadesScreen({super.key});

  @override
  State<NecesidadesScreen> createState() => _NecesidadesScreenState();
}

class _NecesidadesScreenState extends State<NecesidadesScreen> {
  Future<List<Necesidad>> _cargar() async {
    final organizacion = Servicios.i.sesion.organizacionActiva;
    if (organizacion == null) return [];
    return Servicios.i.necesidades.listar(organizacion.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Necesidades')),
      body: FutureBuilder<List<Necesidad>>(
        future: _cargar(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final necesidades = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PublicarNecesidadScreen(),
                  ),
                ).then((_) => setState(() {})),
                icon: const Icon(Icons.add),
                label: const Text('Publicar una necesidad'),
              ),
              const SizedBox(height: 16),
              if (necesidades.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Todavía no hay necesidades en esta comunidad.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ...necesidades.map(
                (necesidad) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: BColors.sol100,
                      child: Icon(Icons.handyman, color: BColors.solTexto),
                    ),
                    title: Text(necesidad.objeto),
                    subtitle: Text(necesidad.descripcion),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DetalleNecesidadScreen(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
