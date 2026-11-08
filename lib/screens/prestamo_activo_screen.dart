import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/acciones.dart';
import '../widgets/banner_estado_membresia.dart';
import '../widgets/componentes.dart';
import '../widgets/tarjetas.dart';
import 'reportar_problema_screen.dart';

/// P14 · Detalle completo y dinámico de un préstamo.
class PrestamoActivoScreen extends StatefulWidget {
  const PrestamoActivoScreen({super.key, required this.prestamo});

  final Prestamo prestamo;

  @override
  State<PrestamoActivoScreen> createState() => _PrestamoActivoScreenState();
}

class _PrestamoActivoScreenState extends State<PrestamoActivoScreen> {
  late Future<Prestamo?> _futuro;
  bool _trabajando = false;

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

  Future<Prestamo?> _cargar() async =>
      await Servicios.i.prestamos.detalle(widget.prestamo.id) ??
      widget.prestamo;

  void _recargar() {
    if (mounted) {
      setState(() => _futuro = _cargar());
    }
  }

  Future<void> _ejecutarAccion(Future<Prestamo> Function() accion) async {
    setState(() => _trabajando = true);
    final ok = await ejecutar(context, () async {
      await accion();
    });
    if (!mounted) return;
    setState(() => _trabajando = false);
    if (ok) _recargar();
  }

  Future<void> _abrirReporte(Prestamo p) async {
    final enviado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReportarProblemaScreen(prestamo: p)),
    );
    if (enviado == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del préstamo')),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: FutureBuilder<Prestamo?>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: BColors.laguna700),
              );
            }
            final p = snap.data;
            if (p == null) {
              return const EstadoVacio(
                titulo: 'No encontramos este préstamo',
                texto: 'Puede que ya no exista.',
              );
            }
            return _construirDetalle(p);
          },
        ),
      ),
    );
  }

  Widget _construirDetalle(Prestamo p) {
    final usuario = Servicios.i.sesion.usuario;
    final yo = usuario?.id ?? -1;
    final soyPrestador = p.prestadorId == yo;
    final soySolicitante = p.solicitanteId == yo;
    final esParte = soyPrestador || soySolicitante;

    // Botón primario dinámico según la tabla de la Sección 11 del SRS.
    String? textoBoton;
    Future<Prestamo> Function()? accionPrimaria;

    if (p.estado == EstadoPrestamo.confirmado && soyPrestador) {
      textoBoton = 'Marcar como entregado';
      accionPrimaria = () =>
          Servicios.i.prestamos.marcarEntregado(p.id, prestadorId: yo);
    } else if (p.estado == EstadoPrestamo.entregaPendiente && soySolicitante) {
      textoBoton = 'Confirmar recepción';
      accionPrimaria = () =>
          Servicios.i.prestamos.confirmarRecibido(p.id, solicitanteId: yo);
    } else if (p.estado == EstadoPrestamo.activo && soySolicitante) {
      textoBoton = 'Marcar como devuelto';
      accionPrimaria = () =>
          Servicios.i.prestamos.marcarDevuelto(p.id, solicitanteId: yo);
    } else if (p.estado == EstadoPrestamo.devolucionPendiente && soyPrestador) {
      textoBoton = 'Confirmar devolución';
      accionPrimaria = () =>
          Servicios.i.prestamos.confirmarDevolucion(p.id, prestadorId: yo);
    }

    final espera =
        p.estado != EstadoPrestamo.finalizado && accionPrimaria == null;
    final puedeReportar =
        esParte && p.estado != EstadoPrestamo.finalizado && !p.enConflicto;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const BannerEstadoMembresia(),
        if (Servicios.i.sesion.membresiaActiva?.estado !=
            EstadoMembresia.activo)
          const SizedBox(height: 12),

        // Encabezado con objeto y chips de estado.
        Row(
          children: [
            IconoCategoria(p.objeto, tam: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.objeto,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: BColors.tinta,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ChipEstado.prestamo(p.estado),
                      if (p.enConflicto)
                        ChipEstado.prestamo(p.estado, enConflicto: true),
                      ChipEstado.modalidad(p.modalidad),
                      if (esParte) ChipEstado.papel(soySolicitante),
                      if (p.vencido)
                        const ChipEstado(
                          'Vencido',
                          Icons.event_busy,
                          BColors.errorFondo,
                          BColors.error,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Banner fijo cuando hay un reporte pendiente ("En conflicto").
        if (p.enConflicto) ...[
          const SizedBox(height: 14),
          const _BannerConflicto(),
        ],

        // Stepper visual de 5 pasos.
        const SizedBox(height: 16),
        TarjetaBlanca(child: StepperPrestamo(estado: p.estado)),

        if (p.estado == EstadoPrestamo.confirmado) ...[
          const SizedBox(height: 12),
          const Text(
            'Coordinen la entrega en el punto central.',
            style: TextStyle(color: BColors.tinta2),
          ),
        ],

        // Fecha de devolución destacada cuando el préstamo está activo.
        if (p.estado == EstadoPrestamo.activo) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: p.vencido ? BColors.errorFondo : BColors.sol100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  color: p.vencido ? BColors.error : BColors.solTexto,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Fecha de devolución: ${Formato.fecha(p.fechaFin)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: p.vencido ? BColors.error : BColors.solTexto,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Tarjeta de resumen.
        const SizedBox(height: 12),
        TarjetaBlanca(
          child: Column(
            children: [
              _FilaPersona('Solicitante', p.solicitanteId),
              _FilaPersona('Prestador', p.prestadorId),
              FilaDato('Fecha de inicio', Formato.fecha(p.fechaInicio)),
              FilaDato('Fecha de fin', Formato.fecha(p.fechaFin)),
              FilaDato('Modalidad', p.modalidad.etiqueta),
              FilaDato(
                'Precio total',
                Formato.dinero(p.precioTotal, gratisSiCero: true),
              ),
            ],
          ),
        ),

        // Tarjeta Punto central (copiado al crearse el préstamo).
        const SizedBox(height: 12),
        TarjetaBlanca(
          child: Row(
            children: [
              const Icon(Icons.place_outlined, color: BColors.laguna700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Punto central',
                      style: TextStyle(color: BColors.tinta2, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.puntoCentral,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: BColors.tinta,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tarjeta Confirmaciones de ambas partes.
        const SizedBox(height: 12),
        TarjetaBlanca(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirmaciones',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 2),
              const Text(
                'Se requieren las confirmaciones de ambas partes para avanzar.',
                style: TextStyle(color: BColors.tinta2, fontSize: 13),
              ),
              const SizedBox(height: 10),
              _FilaConfirmacion(
                'Entrega del prestador',
                p.entregaPrestadorEn,
              ),
              _FilaConfirmacion(
                'Recepción del solicitante',
                p.entregaSolicitanteEn,
              ),
              _FilaConfirmacion(
                'Devolución del solicitante',
                p.devolucionSolicitanteEn,
              ),
              _FilaConfirmacion(
                'Confirmación final del prestador',
                p.devolucionPrestadorEn,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Botón primario de acción.
        if (textoBoton != null)
          BotonPrimario(
            textoBoton,
            cargando: _trabajando,
            onPressed: () => _ejecutarAccion(accionPrimaria!),
          ),

        if (espera)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Esperando la confirmación de la otra parte.',
                style: TextStyle(color: BColors.tinta2),
              ),
            ),
          ),

        if (p.estado == EstadoPrestamo.finalizado)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BColors.exitoFondo,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: BColors.exito),
                SizedBox(width: 8),
                Text(
                  'Préstamo completado',
                  style: TextStyle(
                    color: BColors.exito,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

        // Enlace secundario "Reportar un problema".
        if (puedeReportar) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: BColors.error),
              onPressed: () => _abrirReporte(p),
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text('Reportar un problema'),
            ),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }
}

class _BannerConflicto extends StatelessWidget {
  const _BannerConflicto();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BColors.errorFondo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.report_problem_outlined, color: BColors.error),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Se reportó un problema. El administrador lo está revisando',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: BColors.tinta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaPersona extends StatelessWidget {
  const _FilaPersona(this.etiqueta, this.usuarioId);
  final String etiqueta;
  final int usuarioId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              etiqueta,
              style: const TextStyle(color: BColors.tinta2, fontSize: 13),
            ),
          ),
          Expanded(
            child: NombreUsuario(
              usuarioId,
              estilo: const TextStyle(
                fontWeight: FontWeight.w600,
                color: BColors.tinta,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaConfirmacion extends StatelessWidget {
  const _FilaConfirmacion(this.texto, this.cuando);
  final String texto;
  final DateTime? cuando;

  @override
  Widget build(BuildContext context) {
    final hecho = cuando != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            hecho ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: hecho ? BColors.exito : BColors.tinta3,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 14))),
          Text(
            hecho ? 'Confirmado · ${Formato.fechaHora(cuando!)}' : 'Pendiente',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hecho ? BColors.exito : BColors.solTexto,
            ),
          ),
        ],
      ),
    );
  }
}
