import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/banner_estado_membresia.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/componentes.dart';
import '../widgets/selector_organizacion.dart';
import 'detalle_necesidad_screen.dart';
import 'prestamo_activo_screen.dart';

/// RF-015 · Historial de necesidades, ofertas y préstamos del usuario en la
/// organización activa, con 4 estadísticas básicas y diferenciación de papel.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key, this.tabInicial = 0});

  /// 0 = Necesidades, 1 = Ofertas, 2 = Préstamos.
  final int tabInicial;

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _DatosHistorial {
  const _DatosHistorial({
    required this.misNecesidades,
    required this.misOfertas,
    required this.misPrestamos,
    required this.comoPrestador,
    required this.comoSolicitante,
    required this.finalizados,
    required this.enCurso,
  });

  final List<Necesidad> misNecesidades;
  final List<({Necesidad necesidad, Oferta oferta})> misOfertas;
  final List<Prestamo> misPrestamos;
  final int comoPrestador;
  final int comoSolicitante;
  final int finalizados;
  final int enCurso;
}

class _HistorialScreenState extends State<HistorialScreen> {
  late Future<_DatosHistorial> _futuro;

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

  Future<_DatosHistorial> _cargar() async {
    final sesion = Servicios.i.sesion;
    final usuario = sesion.usuario;
    final org = sesion.organizacionActiva;
    if (usuario == null || org == null) {
      return const _DatosHistorial(
        misNecesidades: [],
        misOfertas: [],
        misPrestamos: [],
        comoPrestador: 0,
        comoSolicitante: 0,
        finalizados: 0,
        enCurso: 0,
      );
    }
    final uid = usuario.id;
    final oid = org.id;

    final todasNecesidades = await Servicios.i.necesidades.listar(oid);
    final misNecesidades = todasNecesidades
        .where((n) => n.solicitanteId == uid)
        .toList();
    final misOfertas = await Servicios.i.necesidades.misOfertas(uid, oid);
    final misPrestamos = await Servicios.i.prestamos.deUsuario(uid, oid);

    final comoPrestador = misPrestamos
        .where((p) => p.prestadorId == uid)
        .length;
    final comoSolicitante = misPrestamos
        .where((p) => p.solicitanteId == uid)
        .length;
    final finalizados = misPrestamos
        .where((p) => p.estado == EstadoPrestamo.finalizado)
        .length;
    final enCurso = misPrestamos
        .where((p) => p.estado != EstadoPrestamo.finalizado)
        .length;

    return _DatosHistorial(
      misNecesidades: misNecesidades,
      misOfertas: misOfertas,
      misPrestamos: misPrestamos,
      comoPrestador: comoPrestador,
      comoSolicitante: comoSolicitante,
      finalizados: finalizados,
      enCurso: enCurso,
    );
  }

  Future<void> _abrirNecesidad(Necesidad n) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleNecesidadScreen(necesidad: n)),
    );
    _recargar();
  }

  Future<void> _abrirPrestamo(Prestamo p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PrestamoActivoScreen(prestamo: p)),
    );
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    final yo = sesion.usuario?.id ?? -1;

    return DefaultTabController(
      length: 3,
      initialIndex: widget.tabInicial.clamp(0, 2),
      child: Scaffold(
        appBar: AppBar(title: const Text('Historial')),
        backgroundColor: BColors.sal,
        bottomNavigationBar: const BarraInferior(indiceActual: 3),
        body: SafeArea(
          child: FutureBuilder<_DatosHistorial>(
            future: _futuro,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: BColors.laguna700),
                );
              }
              if (snap.hasError) {
                return const EstadoVacio(
                  titulo: 'No pudimos cargar tu historial',
                  texto: 'Inténtalo de nuevo en unos segundos.',
                );
              }
              final d = snap.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: PildoraOrganizacion(),
                  ),
                  if (sesion.membresiaActiva?.estado != EstadoMembresia.activo)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: BannerEstadoMembresia(),
                    ),
                  // 4 tarjetas de estadísticas básicas
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _TarjetaEstadistica(
                                valor: '${d.comoPrestador}',
                                etiqueta: 'Como prestador',
                                icono: Icons.inventory_2_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TarjetaEstadistica(
                                valor: '${d.comoSolicitante}',
                                etiqueta: 'Como solicitante',
                                icono: Icons.back_hand_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _TarjetaEstadistica(
                                valor: '${d.finalizados}',
                                etiqueta: 'Finalizados',
                                icono: Icons.check_circle_outline,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TarjetaEstadistica(
                                valor: '${d.enCurso}',
                                etiqueta: 'En curso',
                                icono: Icons.timelapse_outlined,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 3 pestañas: Necesidades | Ofertas | Préstamos
                  Container(
                    color: Colors.white,
                    child: const TabBar(
                      labelColor: BColors.laguna800,
                      indicatorColor: BColors.laguna700,
                      tabs: [
                        Tab(text: 'Necesidades'),
                        Tab(text: 'Ofertas'),
                        Tab(text: 'Préstamos'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Pestaña 1: Necesidades
                        d.misNecesidades.isEmpty
                            ? const EstadoVacio(
                                titulo: 'Sin necesidades registradas',
                                texto:
                                    'Aquí verás las necesidades que hayas publicado en esta organización.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: d.misNecesidades.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  final n = d.misNecesidades[i];
                                  return _ItemHistorial(
                                    objeto: n.objeto,
                                    fecha: Formato.rango(
                                      n.fechaInicio,
                                      n.fechaFin,
                                    ),
                                    detalle: n.descripcion,
                                    chips: [
                                      ChipEstado.papel(true),
                                      ChipEstado.necesidad(n.estado),
                                    ],
                                    onTap: () => _abrirNecesidad(n),
                                  );
                                },
                              ),
                        // Pestaña 2: Ofertas
                        d.misOfertas.isEmpty
                            ? const EstadoVacio(
                                titulo: 'Sin ofertas registradas',
                                texto:
                                    'Aquí verás las ofertas que hayas enviado en esta organización.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: d.misOfertas.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  final item = d.misOfertas[i];
                                  final total = Servicios.i.necesidades
                                      .calcularTotal(
                                        necesidad: item.necesidad,
                                        modalidad: item.oferta.modalidad,
                                        precio: item.oferta.precio,
                                        unidad: item.oferta.unidadCobro,
                                      );
                                  return _ItemHistorial(
                                    objeto: item.necesidad.objeto,
                                    fecha:
                                        'Entrega: ${Formato.fechaHora(item.oferta.fechaEntrega)}',
                                    detalle:
                                        'Total: ${Formato.dinero(total, gratisSiCero: true)}',
                                    chips: [
                                      ChipEstado.papel(false),
                                      ChipEstado.modalidad(
                                        item.oferta.modalidad,
                                      ),
                                      ChipEstado.oferta(item.oferta.estado),
                                    ],
                                    onTap: () =>
                                        _abrirNecesidad(item.necesidad),
                                  );
                                },
                              ),
                        // Pestaña 3: Préstamos
                        d.misPrestamos.isEmpty
                            ? const EstadoVacio(
                                titulo: 'Sin préstamos registrados',
                                texto:
                                    'Aquí verás los préstamos donde participes como solicitante o prestador.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: d.misPrestamos.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  final p = d.misPrestamos[i];
                                  final soySolicitante = p.solicitanteId == yo;
                                  return _ItemHistorial(
                                    objeto: p.objeto,
                                    fecha: Formato.rango(
                                      p.fechaInicio,
                                      p.fechaFin,
                                    ),
                                    detalle:
                                        'Total: ${Formato.dinero(p.precioTotal, gratisSiCero: true)}',
                                    chips: [
                                      ChipEstado.papel(soySolicitante),
                                      ChipEstado.modalidad(p.modalidad),
                                      ChipEstado.prestamo(p.estado),
                                      if (p.enConflicto)
                                        ChipEstado.prestamo(
                                          p.estado,
                                          enConflicto: true,
                                        ),
                                    ],
                                    onTap: () => _abrirPrestamo(p),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TarjetaEstadistica extends StatelessWidget {
  const _TarjetaEstadistica({
    required this.valor,
    required this.etiqueta,
    required this.icono,
  });

  final String valor;
  final String etiqueta;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return TarjetaBlanca(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BColors.laguna100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 20, color: BColors.laguna800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BColors.tinta,
                  ),
                ),
                Text(
                  etiqueta,
                  style: const TextStyle(fontSize: 12, color: BColors.tinta2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemHistorial extends StatelessWidget {
  const _ItemHistorial({
    required this.objeto,
    required this.fecha,
    required this.detalle,
    required this.chips,
    required this.onTap,
  });

  final String objeto;
  final String fecha;
  final String detalle;
  final List<Widget> chips;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TarjetaBlanca(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconoCategoria(objeto),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  objeto,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: BColors.tinta,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: BColors.tinta3,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        fecha,
                        style: const TextStyle(
                          color: BColors.tinta2,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: BColors.tinta2, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: chips),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: BColors.tinta3),
        ],
      ),
    );
  }
}

