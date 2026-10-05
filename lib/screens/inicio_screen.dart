import 'package:flutter/material.dart';

import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import 'bienvenida_screen.dart';
import 'detalle_necesidad_screen.dart';
import 'necesidades_screen.dart';
import 'panel_administracion_screen.dart';
import 'prestamo_activo_screen.dart';
import 'publicar_necesidad_screen.dart';
import 'perfil_screen.dart';

// P08: Pantalla principal de la organización activa.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  @override
  void initState() {
    super.initState();
    Servicios.i.sesion.addListener(_onSesionChange);
  }

  @override
  void dispose() {
    Servicios.i.sesion.removeListener(_onSesionChange);
    super.dispose();
  }

  void _onSesionChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    final org = sesion.organizacionActiva;
    final user = sesion.usuario;

    if (org == null || user == null) {
      return Scaffold(
        body: Center(
          child: FilledButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BienvenidaScreen()),
            ),
            icon: const Icon(Icons.login),
            label: const Text('Continuar'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Muestra la organización activa y sus accesos rápidos.
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: BColors.laguna100,
                      child: Icon(
                        Icons.school,
                        size: 16,
                        color: BColors.laguna700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        org.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'admin' && sesion.esAdminActivo) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PanelAdministracionScreen(),
                            ),
                          );
                        } else if (value == 'necesidades') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NecesidadesScreen(),
                            ),
                          );
                        } else if (value == 'prestamos') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrestamoActivoScreen(),
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'necesidades',
                          child: Text('Ver necesidades'),
                        ),
                        const PopupMenuItem(
                          value: 'prestamos',
                          child: Text('Mis préstamos'),
                        ),
                        if (sesion.esAdminActivo)
                          const PopupMenuItem(
                            value: 'admin',
                            child: Text('Panel de administración'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tarjeta principal con el saludo y la acción más importante.
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: marea,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${user.nombre.split(' ')[0]}!',
                      style: const TextStyle(
                        fontFamily: 'Bricolage',
                        fontSize: 26,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '¿Qué necesitas hoy?',
                      style: TextStyle(color: BColors.laguna100),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BColors.sol400,
                          foregroundColor: BColors.solTexto,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PublicarNecesidadScreen(),
                            ),
                          );
                        },
                        child: const Text('+ Publicar una necesidad'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Necesidades recientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // Carga y muestra las necesidades recientes de esta organización.
              FutureBuilder<List<Necesidad>>(
                future: Servicios.i.necesidades.listar(org.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final necesidades = snapshot.data ?? [];
                  if (necesidades.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No hay necesidades publicadas aún.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: BColors.tinta3),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: necesidades.length > 5
                        ? 5
                        : necesidades
                              .length, // En el inicio solo mostramos cinco.
                    itemBuilder: (context, index) {
                      final n = necesidades[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetalleNecesidadScreen(necesidad: n),
                            ),
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: BColors.bruma,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.handyman,
                              color: BColors.tinta2,
                            ),
                          ),
                          title: Text(
                            n.objeto,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(n.estado.name),
                          trailing: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetalleNecesidadScreen(necesidad: n),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                            child: const Text('Tengo este objeto'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: BColors.laguna700,
        unselectedItemColor: BColors.tinta3,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NecesidadesScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrestamoActivoScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Necesidades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake),
            label: 'Préstamos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
