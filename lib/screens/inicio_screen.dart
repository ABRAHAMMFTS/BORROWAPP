import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_estado_membresia.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/componentes.dart';
import '../widgets/selector_organizacion.dart';
import 'bienvenida_screen.dart';
import 'detalle_necesidad_screen.dart';
import 'historial_screen.dart';
import 'mis_prestamos_screen.dart';
import 'necesidades_screen.dart';
import 'panel_administracion_screen.dart';
import 'publicar_necesidad_screen.dart';

// P08: Pantalla principal de la organización activa.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

/// Cifras de las tarjetas de resumen (datos reales del usuario en la
/// organización activa).
class _Resumen {
  const _Resumen(this.prestamosActivos, this.accionesPendientes, this.ofertas);
  final int prestamosActivos;
  final int accionesPendientes;
  final int ofertas;
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

  Future<_Resumen> _cargarResumen(int usuarioId, int orgId) async {
    final servicios = Servicios.i;
    final prestamos = await servicios.prestamos.deUsuario(usuarioId, orgId);
    final enCurso =
        prestamos.where((p) => p.estado != EstadoPrestamo.finalizado).toList();
    final acciones = enCurso
        .where((p) => servicios.prestamos.accionPendiente(p, usuarioId) != null)
        .length;
    final ofertas =
        await servicios.necesidades.ofertasPendientesRecibidas(usuarioId, orgId);
    return _Resumen(enCurso.length, acciones, ofertas);
  }

  /// Abre el detalle y, al volver, redibuja por si algo cambió.
  void _abrirNecesidad(Necesidad n) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleNecesidadScreen(necesidad: n)),
    ).then((_) {
      if (mounted) setState(() {});
    });
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

    final bloqueado = sesion.bloqueadoEnActiva;

    return Scaffold(
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Píldora de la organización activa (abre "Tus organizaciones")
              // y menú de accesos rápidos.
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Expanded(child: PildoraOrganizacion()),
                    const SizedBox(width: 8),
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
                              builder: (_) => const MisPrestamosScreen(),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
                        } else if (value == 'historial') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistorialScreen(),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
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
                        const PopupMenuItem(
                          value: 'historial',
                          child: Text('Historial'),
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

              // Aviso de sanción (solo aparece si no está ACTIVO).
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: BannerEstadoMembresia(),
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
                      '¡Hola, ${user.primerNombre}!',
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
                        // RF-018: deshabilitado si está suspendido o baneado.
                        onPressed: bloqueado
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PublicarNecesidadScreen(),
                                  ),
                                ).then((_) {
                                  if (mounted) setState(() {});
                                });
                              },
                        child: const Text('+ Publicar una necesidad'),
                      ),
                    ),
                  ],
                ),
              ),

              // Tarjetas de resumen con datos reales.
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FutureBuilder<_Resumen>(
                  future: _cargarResumen(user.id, org.id),
                  builder: (context, snap) {
                    final r = snap.data;
                    String cifra(int? v) => v == null ? '–' : '$v';
                    return Row(children: [
                      Expanded(
                        child: _TarjetaResumen(
                          cifra: cifra(r?.prestamosActivos),
                          etiqueta: 'Préstamos activos',
                          icono: Icons.handshake_outlined,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MisPrestamosScreen(),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TarjetaResumen(
                          cifra: cifra(r?.accionesPendientes),
                          etiqueta: 'Acciones pendientes',
                          icono: Icons.touch_app_outlined,
                          // Sol: "requiere tu atención".
                          atencion: (r?.accionesPendientes ?? 0) > 0,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MisPrestamosScreen(),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TarjetaResumen(
                          cifra: cifra(r?.ofertas),
                          etiqueta: 'Ofertas recibidas',
                          icono: Icons.local_offer_outlined,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const NecesidadesScreen(tabInicial: 1),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          }),
                        ),
                      ),
                    ]);
                  },
                ),
              ),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Necesidades recientes de tu comunidad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // Carga y muestra las necesidades recientes de esta organización.
              FutureBuilder<List<Necesidad>>(
                future: Servicios.i.necesidades.listar(org.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
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
                      // "Tengo este objeto" solo en necesidades de otros,
                      // abiertas, y si el usuario puede actuar.
                      final puedeOfrecer = n.solicitanteId != user.id &&
                          n.estado == EstadoNecesidad.buscandoPrestador &&
                          !bloqueado;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          onTap: () => _abrirNecesidad(n),
                          leading: IconoCategoria(n.objeto),
                          title: Text(
                            n.objeto,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(n.estado.etiqueta),
                          trailing: puedeOfrecer
                              ? ElevatedButton(
                                  onPressed: () => _abrirNecesidad(n),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: const Text('Tengo este objeto'),
                                )
                              : const Icon(Icons.chevron_right,
                                  color: BColors.tinta3),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BarraInferior(indiceActual: 0),
    );
  }
}

/// Tarjeta pequeña con una cifra y su etiqueta.
class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({
    required this.cifra,
    required this.etiqueta,
    required this.icono,
    this.atencion = false,
    this.onTap,
  });

  final String cifra;
  final String etiqueta;
  final IconData icono;
  final bool atencion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TarjetaBlanca(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      color: atencion ? BColors.sol50 : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono,
            size: 20, color: atencion ? BColors.solTexto : BColors.laguna700),
        const SizedBox(height: 8),
        Text(cifra,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: atencion ? BColors.solTexto : BColors.tinta)),
        const SizedBox(height: 2),
        Text(etiqueta,
            style: const TextStyle(fontSize: 12, color: BColors.tinta2)),
      ]),
    );
  }
}
