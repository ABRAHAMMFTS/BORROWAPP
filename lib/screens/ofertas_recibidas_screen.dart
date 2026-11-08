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
import '../widgets/tarjetas.dart';
import 'confirmar_aceptacion_screen.dart';

// P12: Condiciones propuestas para una necesidad mía.
class OfertasRecibidasScreen extends StatefulWidget {
  const OfertasRecibidasScreen({super.key, required this.necesidad});

  final Necesidad necesidad;

  @override
  State<OfertasRecibidasScreen> createState() => _OfertasRecibidasScreenState();
}

class _Datos {
  const _Datos(this.necesidad, this.ofertas);
  final Necesidad necesidad;
  final List<Oferta> ofertas;
}

class _OfertasRecibidasScreenState extends State<OfertasRecibidasScreen> {
  late Future<_Datos> _futuro;

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

  Future<_Datos> _cargar() async {
    final servicio = Servicios.i.necesidades;
    final n = await servicio.detalle(widget.necesidad.id) ?? widget.necesidad;
    return _Datos(n, await servicio.ofertasDe(n.id));
  }

  Future<void> _aceptar(Oferta o, Necesidad n) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmarAceptacionScreen(oferta: o, necesidad: n),
      ),
    );
    _recargar();
  }

  Future<void> _rechazar(Oferta o) async {
    final usuario = Servicios.i.sesion.usuario!;
    final ok = await ejecutar(
      context,
      () => Servicios.i.necesidades
          .rechazarOferta(solicitanteId: usuario.id, ofertaId: o.id),
    );
    if (!ok || !mounted) return;
    mostrarMensaje(context, 'Rechazaste la oferta.');
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    return Scaffold(
      appBar: AppBar(title: const Text('Ofertas recibidas')),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: FutureBuilder<_Datos>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                  child: CircularProgressIndicator(color: BColors.laguna700));
            }
            if (snap.hasError) {
              return const EstadoVacio(
                titulo: 'No pudimos cargar las ofertas',
                texto: 'Vuelve atrás e inténtalo de nuevo.',
              );
            }
            final n = snap.data!.necesidad;
            final ofertas = snap.data!.ofertas;
            final abierta = n.estado == EstadoNecesidad.buscandoPrestador;
            final puedeDecidir = abierta && !sesion.bloqueadoEnActiva;
            final pendientes =
                ofertas.where((o) => o.estado == EstadoOferta.pendiente).length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const BannerEstadoMembresia(),
                if (sesion.membresiaActiva?.estado != EstadoMembresia.activo)
                  const SizedBox(height: 12),
                Row(children: [
                  IconoCategoria(n.objeto, tam: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Ofertas para tu ${n.objeto}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ]),
                const SizedBox(height: 16),
                TituloSeccion('Condiciones propuestas ($pendientes)'),
                if (ofertas.isEmpty)
                  const SizedBox(
                    height: 280,
                    child: EstadoVacio(
                      titulo: 'Aún no hay ofertas',
                      texto: 'Cuando alguien ofrezca lo que necesitas, lo verás aquí.',
                    ),
                  ),
                for (final o in ofertas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TarjetaOferta(
                      oferta: o,
                      necesidad: n,
                      puedeDecidir: puedeDecidir,
                      onAceptar: () => _aceptar(o, n),
                      onRechazar: () => _rechazar(o),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TarjetaOferta extends StatelessWidget {
  const _TarjetaOferta({
    required this.oferta,
    required this.necesidad,
    required this.puedeDecidir,
    required this.onAceptar,
    required this.onRechazar,
  });

  final Oferta oferta;
  final Necesidad necesidad;
  final bool puedeDecidir;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    final total = Servicios.i.necesidades.calcularTotal(
      necesidad: necesidad,
      modalidad: oferta.modalidad,
      precio: oferta.precio,
      unidad: oferta.unidadCobro,
    );
    final alquiler = oferta.modalidad == Modalidad.alquiler;
    final precioUnitario = alquiler
        ? '${Formato.dinero(oferta.precio ?? 0)} / '
            '${oferta.unidadCobro == UnidadCobro.hora ? 'hora' : 'día'}'
        : 'Sin costo';
    return TarjetaBlanca(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AvatarUsuario(oferta.prestadorId, tam: 40),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder<Usuario?>(
              future: Servicios.i.organizaciones.usuario(oferta.prestadorId),
              builder: (_, s) => Text(s.data?.nombre ?? '...',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          ChipEstado.oferta(oferta.estado),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [ChipEstado.modalidad(oferta.modalidad)]),
        const SizedBox(height: 6),
        FilaDato('Precio', precioUnitario),
        FilaDato('Total', Formato.dinero(total, gratisSiCero: true)),
        FilaDato('Entrega', Formato.fechaHora(oferta.fechaEntrega)),
        if (oferta.estado == EstadoOferta.pendiente && puedeDecidir) ...[
          const SizedBox(height: 12),
          BotonPrimario('Aceptar condiciones', onPressed: onAceptar),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRechazar, child: const Text('Rechazar')),
        ],
      ]),
    );
  }
}
