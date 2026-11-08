import 'package:flutter/material.dart';

import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../widgets/componentes.dart';
import '../widgets/selector_organizacion.dart';
import 'crear_organizacion_screen.dart';
import 'unirme_paso_1_screen.dart';

/// Bloque D · Mis organizaciones: lista cada membresía del usuario con su tipo,
/// rol, identificador, estado y botón para cambiar la organización activa.
class MisOrganizacionesScreen extends StatelessWidget {
  const MisOrganizacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    return ListenableBuilder(
      listenable: sesion,
      builder: (context, _) {
        final membresias = sesion.membresias;
        final activaId = sesion.organizacionActiva?.id;

        return Scaffold(
          appBar: AppBar(title: const Text('Mis organizaciones')),
          backgroundColor: BColors.sal,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BColors.laguna50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BColors.laguna200),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: BColors.laguna800,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tu estado y tu rol son independientes en cada organización',
                          style: TextStyle(
                            color: BColors.laguna800,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final m in membresias)
                  if (sesion.organizacion(m.organizacionId) != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Builder(
                        builder: (context) {
                          final org = sesion.organizacion(m.organizacionId)!;
                          final esActiva = org.id == activaId;
                          return TarjetaBlanca(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AvatarOrganizacion(org, tam: 44),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            org.nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: BColors.tinta,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            org.tipo.etiqueta,
                                            style: const TextStyle(
                                              color: BColors.tinta2,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (esActiva)
                                      const ChipEstado(
                                        'Activa',
                                        Icons.check_circle,
                                        BColors.laguna100,
                                        BColors.laguna800,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    ChipRol(m.rol),
                                    ChipEstado.membresia(m.estado),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                FilaDato(
                                  org.tipo.etiquetaIdentificador,
                                  m.identificadorInterno,
                                  icono: Icons.badge_outlined,
                                ),
                                FilaDato(
                                  'Punto central',
                                  org.puntoCentral,
                                  icono: Icons.place_outlined,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: esActiva
                                        ? null
                                        : () {
                                            sesion.cambiarOrganizacion(org.id);
                                            mostrarMensaje(
                                              context,
                                              'Cambiaste a ${org.nombre}.',
                                            );
                                          },
                                    child: const Text(
                                      'Cambiar a esta organización',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                const SizedBox(height: 8),
                BotonPrimario(
                  'Unirme con un código',
                  icono: Icons.vpn_key_outlined,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UnirmePaso1Screen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CrearOrganizacionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Crear otra organización'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

