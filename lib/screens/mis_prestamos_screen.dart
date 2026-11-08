import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_estado_membresia.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/componentes.dart';
import '../widgets/selector_organizacion.dart';
import '../widgets/tarjetas.dart';
import 'prestamo_activo_screen.dart';

/// Listado de "Mis préstamos" en la organización activa, con las pestañas
/// "En curso" y "Finalizados" (SRS Sección 11, Bloque C).
class MisPrestamosScreen extends StatefulWidget {
  const MisPrestamosScreen({super.key, this.tabInicial = 0});

  /// 0 = En curso, 1 = Finalizados.
  final int tabInicial;

  @override
  State<MisPrestamosScreen> createState() => _MisPrestamosScreenState();
}

class _MisPrestamosScreenState extends State<MisPrestamosScreen> {
  late Future<List<Prestamo>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
    Servicios.i.sesion.addListener(_recargar);
  }

  @override
  void dispose() {
    Servicios.i.sesion.removeListener(_recargar);
    super.dispose();
  }

  void _recargar() {
    if (mounted) setState(() => _futuro = _cargar());
  }

  Future<List<Prestamo>> _cargar() async {
    final sesion = Servicios.i.sesion;
    final usuario = sesion.usuario;
    final org = sesion.organizacionActiva;
    if (usuario == null || org == null) return [];
    return Servicios.i.prestamos.deUsuario(usuario.id, org.id);
  }

  Future<void> _abrirDetalle(Prestamo p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PrestamoActivoScreen(prestamo: p)),
    );
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    return DefaultTabController(
      length: 2,
      initialIndex: widget.tabInicial.clamp(0, 1),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis préstamos'),
          bottom: const TabBar(
            labelColor: BColors.laguna800,
            indicatorColor: BColors.laguna700,
            tabs: [
              Tab(text: 'En curso'),
              Tab(text: 'Finalizados'),
            ],
          ),
        ),
        backgroundColor: BColors.sal,
        bottomNavigationBar: const BarraInferior(indiceActual: 2),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PildoraOrganizacion(),
              ),
            ),
            if (sesion.membresiaActiva?.estado != EstadoMembresia.activo)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: BannerEstadoMembresia(),
              ),
            Expanded(
              child: FutureBuilder<List<Prestamo>>(
                future: _futuro,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: BColors.laguna700),
                    );
                  }
                  if (snap.hasError) {
                    return const EstadoVacio(
                      titulo: 'No pudimos cargar tus préstamos',
                      texto: 'Inténtalo de nuevo en unos segundos.',
                    );
                  }
                  final todos = snap.data ?? [];
                  final enCurso = todos
                      .where((p) => p.estado != EstadoPrestamo.finalizado)
                      .toList();
                  final finalizados = todos
                      .where((p) => p.estado == EstadoPrestamo.finalizado)
                      .toList();

                  return TabBarView(
                    children: [
                      _ListaPrestamos(
                        items: enCurso,
                        onTap: _abrirDetalle,
                        vacioTitulo: 'No tienes préstamos en curso',
                        vacioTexto:
                            'Cuando aceptes una oferta o acepten una tuya, el préstamo aparecerá aquí.',
                      ),
                      _ListaPrestamos(
                        items: finalizados,
                        onTap: _abrirDetalle,
                        vacioTitulo: 'Aún no tienes préstamos finalizados',
                        vacioTexto:
                            'Los préstamos completados en esta organización quedarán registrados aquí.',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaPrestamos extends StatelessWidget {
  const _ListaPrestamos({
    required this.items,
    required this.onTap,
    required this.vacioTitulo,
    required this.vacioTexto,
  });

  final List<Prestamo> items;
  final void Function(Prestamo) onTap;
  final String vacioTitulo;
  final String vacioTexto;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EstadoVacio(titulo: vacioTitulo, texto: vacioTexto);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => TarjetaPrestamo(
        items[i],
        onTap: () => onTap(items[i]),
      ),
    );
  }
}

