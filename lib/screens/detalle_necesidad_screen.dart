import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../models/usuario.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/acciones.dart';
import '../widgets/banner_estado_membresia.dart';
import '../widgets/componentes.dart';
import 'definir_oferta_screen.dart';
import 'ofertas_recibidas_screen.dart';

// P10: Detalle de una necesidad. Si es de otro miembro muestra "Tengo este
// objeto"; si es mía muestra las condiciones propuestas y permite cancelarla.
class DetalleNecesidadScreen extends StatefulWidget {
  const DetalleNecesidadScreen({super.key, required this.necesidad});

  final Necesidad necesidad;

  @override
  State<DetalleNecesidadScreen> createState() => _DetalleNecesidadScreenState();
}

class _Vista {
  const _Vista({
    required this.necesidad,
    required this.solicitante,
    required this.ofertas,
    required this.miOfertaPendiente,
  });
  final Necesidad necesidad;
  final Usuario? solicitante;
  final List<Oferta> ofertas; // solo se llena si la necesidad es mía
  final Oferta? miOfertaPendiente; // solo si es de otro miembro
}

class _DetalleNecesidadScreenState extends State<DetalleNecesidadScreen> {
  late Future<_Vista> _futuro;

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

  Future<_Vista> _cargar() async {
    final servicios = Servicios.i;
    final yo = servicios.sesion.usuario!.id;
    // Se vuelve a leer para ver el estado actual (puede haber cambiado).
    final n = await servicios.necesidades.detalle(widget.necesidad.id) ??
        widget.necesidad;
    final solicitante = await servicios.organizaciones.usuario(n.solicitanteId);
    final esMia = n.solicitanteId == yo;
    return _Vista(
      necesidad: n,
      solicitante: solicitante,
      ofertas: esMia ? await servicios.necesidades.ofertasDe(n.id) : const [],
      miOfertaPendiente:
          esMia ? null : await servicios.necesidades.ofertaPendienteDe(n.id, yo),
    );
  }

  Future<void> _ofrecer(Necesidad n) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DefinirOfertaScreen(necesidad: n)),
    );
    _recargar();
  }

  Future<void> _verOfertas(Necesidad n) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OfertasRecibidasScreen(necesidad: n)),
    );
    _recargar();
  }

  /// RF-020: cancela la necesidad tras pedir confirmación.
  Future<void> _cancelar(Necesidad n) async {
    final ok = await confirmarDialogo(
      context,
      titulo: '¿Cancelar esta necesidad?',
      texto: 'Las ofertas pendientes se cerrarán y la necesidad quedará cerrada.',
      confirmar: 'Sí, cancelar',
      peligro: true,
    );
    if (!ok || !mounted) return;
    final usuario = Servicios.i.sesion.usuario!;
    final hecho = await ejecutar(
      context,
      () => Servicios.i.necesidades
          .cancelar(usuarioId: usuario.id, necesidadId: n.id),
    );
    if (!hecho || !mounted) return;
    mostrarMensaje(context, 'Cancelaste la necesidad.');
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    return FutureBuilder<_Vista>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle de necesidad')),
            body: const Center(
                child: CircularProgressIndicator(color: BColors.laguna700)),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle de necesidad')),
            body: const EstadoVacio(
              titulo: 'No pudimos cargar la necesidad',
              texto: 'Vuelve atrás e inténtalo de nuevo.',
            ),
          );
        }
        final v = snap.data!;
        final n = v.necesidad;
        final esMia = n.solicitanteId == sesion.usuario!.id;
        final abierta = n.estado == EstadoNecesidad.buscandoPrestador;
        final bloqueado = sesion.bloqueadoEnActiva;
        final pendientes =
            v.ofertas.where((o) => o.estado == EstadoOferta.pendiente).toList();

        // Botón fijo inferior: solo en los casos que lo permiten.
        Widget? barra;
        if (!esMia && abierta && !bloqueado) {
          barra = BarraAccion(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (v.miOfertaPendiente != null)
                const Text('Ya enviaste una oferta. Espera la respuesta del solicitante.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: BColors.laguna700, fontWeight: FontWeight.w600))
              else ...[
                BotonPrimario('Tengo este objeto', onPressed: () => _ofrecer(n)),
                const SizedBox(height: 8),
                const Text('Tú defines si lo prestas gratis o lo alquilas',
                    style: TextStyle(color: BColors.tinta2, fontSize: 13)),
              ],
            ]),
          );
        } else if (esMia && abierta) {
          barra = BarraAccion(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: BColors.error,
                side: const BorderSide(color: BColors.error, width: 1.5),
              ),
              onPressed: () => _cancelar(n),
              icon: const Icon(Icons.close),
              label: const Text('Cancelar necesidad'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Detalle de necesidad')),
          backgroundColor: BColors.sal,
          bottomNavigationBar: barra,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BannerEstadoMembresia(),
                  if (sesion.membresiaActiva?.estado != EstadoMembresia.activo)
                    const SizedBox(height: 16),
                  // Quién la publicó.
                  Row(children: [
                    AvatarIniciales(v.solicitante?.iniciales ?? '?', tam: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(esMia ? 'Publicada por ti' : (v.solicitante?.nombre ?? 'Miembro'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const Text('Solicitante',
                            style: TextStyle(color: BColors.tinta2, fontSize: 13)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  // Objeto, estado y fechas.
                  Row(children: [
                    IconoCategoria(n.objeto, tam: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.objeto,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ChipEstado.necesidad(n.estado),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  TarjetaBlanca(
                    child: Column(children: [
                      FilaDato('Desde', Formato.fecha(n.fechaInicio), icono: Icons.event_outlined),
                      FilaDato('Hasta', Formato.fecha(n.fechaFin), icono: Icons.event_available_outlined),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(n.descripcion),

                  // CASO B: es mía. Condiciones propuestas.
                  if (esMia) ...[
                    const SizedBox(height: 28),
                    TituloSeccion('Condiciones propuestas (${pendientes.length})'),
                    if (pendientes.isEmpty)
                      Text(
                        abierta
                            ? 'Aún no hay ofertas pendientes. Te avisaremos aquí cuando alguien tenga lo que necesitas.'
                            : 'Esta necesidad ya no tiene ofertas pendientes.',
                        style: const TextStyle(color: BColors.tinta2),
                      )
                    else ...[
                      for (final o in pendientes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ResumenOferta(oferta: o, necesidad: n),
                        ),
                      const SizedBox(height: 8),
                      BotonPrimario('Revisar condiciones',
                          icono: Icons.fact_check_outlined,
                          onPressed: () => _verOfertas(n)),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Línea compacta de una oferta: prestador, modalidad y total.
class _ResumenOferta extends StatelessWidget {
  const _ResumenOferta({required this.oferta, required this.necesidad});
  final Oferta oferta;
  final Necesidad necesidad;

  @override
  Widget build(BuildContext context) {
    final total = Servicios.i.necesidades.calcularTotal(
      necesidad: necesidad,
      modalidad: oferta.modalidad,
      precio: oferta.precio,
      unidad: oferta.unidadCobro,
    );
    return TarjetaBlanca(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        FutureBuilder<Usuario?>(
          future: Servicios.i.organizaciones.usuario(oferta.prestadorId),
          builder: (_, s) => Expanded(
            child: Text(s.data?.nombre ?? '...',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 8),
        ChipEstado.modalidad(oferta.modalidad),
        const SizedBox(width: 8),
        Text(Formato.dinero(total, gratisSiCero: true),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
