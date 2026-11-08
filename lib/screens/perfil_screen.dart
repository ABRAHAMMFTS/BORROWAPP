import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/enums.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_estado_membresia.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/codigo_organizacion.dart';
import '../widgets/componentes.dart';
import '../widgets/selector_organizacion.dart';
import 'bienvenida_screen.dart';
import 'mis_organizaciones_screen.dart';
import 'panel_administracion_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Future<int> _contarReportesPendientes(int adminId, int orgId) async {
    final lista = await Servicios.i.prestamos.reportesDe(adminId, orgId);
    return lista.where((r) => r.estado == EstadoReporte.pendiente).length;
  }

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    // Se redibuja al cambiar la organización activa o el estado de membresía.
    return ListenableBuilder(
      listenable: sesion,
      builder: (context, _) {
        final usuario = sesion.usuario;
        final organizacion = sesion.organizacionActiva;
        final membresia = sesion.membresiaActiva;
        final esAdmin = sesion.esAdminActivo;
        final totalOrgs = sesion.membresias.length;

        return Scaffold(
          appBar: AppBar(title: const Text('Mi perfil')),
          backgroundColor: BColors.sal,
          bottomNavigationBar: const BarraInferior(indiceActual: 4),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const PildoraOrganizacion(),
              const SizedBox(height: 12),
              const BannerEstadoMembresia(),
              if (membresia != null && membresia.estado != EstadoMembresia.activo)
                const SizedBox(height: 12),
              const SizedBox(height: 8),
              Center(
                child: AvatarIniciales(usuario?.iniciales ?? '?', tam: 84),
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 24),

              // Tarjeta de la organización activa
              if (organizacion != null && membresia != null)
                TarjetaBlanca(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AvatarOrganizacion(organizacion, tam: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  organizacion.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  organizacion.tipo.etiqueta,
                                  style: const TextStyle(
                                    color: BColors.tinta2,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ChipRol(membresia.rol),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilaDato(
                        organizacion.tipo.etiquetaIdentificador,
                        membresia.identificadorInterno,
                        icono: Icons.badge_outlined,
                      ),
                      FilaDato(
                        'Punto central',
                        organizacion.puntoCentral,
                        icono: Icons.place_outlined,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 18,
                              color: BColors.tinta3,
                            ),
                            const SizedBox(width: 10),
                            const SizedBox(
                              width: 120,
                              child: Text(
                                'Estado',
                                style: TextStyle(
                                  color: BColors.tinta2,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            ChipEstado.membresia(membresia.estado),
                          ],
                        ),
                      ),
                      // El código solo lo ve el administrador (SRS 11, Bloque D).
                      if (esAdmin) ...[
                        const Divider(height: 28),
                        const Text(
                          'Código de la organización',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        CodigoOrganizacion(codigo: organizacion.codigo),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copiar'),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: organizacion.codigo),
                              );
                              if (!context.mounted) return;
                              mostrarMensaje(
                                context,
                                'Código ${organizacion.codigo} copiado.',
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Tarjeta Panel de administración (solo si es administrador en la organización activa).
              if (esAdmin && usuario != null && organizacion != null) ...[
                const SizedBox(height: 14),
                FutureBuilder<int>(
                  future: _contarReportesPendientes(usuario.id, organizacion.id),
                  builder: (context, snap) {
                    final pendientes = snap.data ?? 0;
                    return TarjetaBlanca(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PanelAdministracionScreen(),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: BColors.sol100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_outlined,
                              color: BColors.solTexto,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Panel de administración',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Miembros, publicaciones, préstamos y reportes',
                                  style: TextStyle(
                                    color: BColors.tinta2,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (pendientes > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: BColors.error,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$pendientes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          const Icon(
                            Icons.chevron_right,
                            color: BColors.tinta3,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              // Fila Mis organizaciones (N)
              const SizedBox(height: 14),
              TarjetaBlanca(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MisOrganizacionesScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BColors.laguna100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.groups_outlined,
                        color: BColors.laguna800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mis organizaciones ($totalOrgs)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: BColors.tinta3),
                  ],
                ),
              ),

              const SizedBox(height: 24),
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
      },
    );
  }
}
