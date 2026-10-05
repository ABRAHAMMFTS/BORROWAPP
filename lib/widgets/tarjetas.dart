import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import 'componentes.dart';

/// Muestra el nombre de un usuario a partir de su id (lo busca en el servicio).
class NombreUsuario extends StatelessWidget {
  const NombreUsuario(this.id, {super.key, this.estilo, this.prefijo = ''});
  final int id;
  final TextStyle? estilo;
  final String prefijo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Servicios.i.necesidades.usuario(id),
      builder: (_, s) => Text('$prefijo${s.data?.nombre ?? '...'}',
          overflow: TextOverflow.ellipsis, style: estilo),
    );
  }
}

/// Avatar de un usuario a partir de su id.
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario(this.id, {super.key, this.tam = 36});
  final int id;
  final double tam;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Servicios.i.necesidades.usuario(id),
      builder: (_, s) => AvatarIniciales(s.data?.iniciales ?? '?', tam: tam),
    );
  }
}

/// Fila de una necesidad en las listas: ícono de categoría, objeto, solicitante,
/// fechas y estado.
class FilaNecesidad extends StatelessWidget {
  const FilaNecesidad(this.n, {super.key, required this.onTap, this.extra});
  final Necesidad n;
  final VoidCallback onTap;

  /// Texto opcional debajo (por ejemplo "Tu oferta está pendiente").
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final esMia = n.solicitanteId == Servicios.i.sesion.usuario?.id;
    return TarjetaBlanca(
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconoCategoria(n.objeto),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n.objeto,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: BColors.tinta)),
            const SizedBox(height: 2),
            esMia
                ? const Text('Publicada por ti', style: TextStyle(color: BColors.tinta2, fontSize: 13))
                : NombreUsuario(n.solicitanteId,
                    prefijo: 'Pide ', estilo: const TextStyle(color: BColors.tinta2, fontSize: 13)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.event_outlined, size: 14, color: BColors.tinta3),
              const SizedBox(width: 4),
              Text(Formato.rango(n.fechaInicio, n.fechaFin),
                  style: const TextStyle(color: BColors.tinta2, fontSize: 13)),
            ]),
            if (extra != null) ...[
              const SizedBox(height: 4),
              Text(extra!, style: const TextStyle(color: BColors.laguna700, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 8),
            ChipEstado.necesidad(n.estado),
          ]),
        ),
        const Icon(Icons.chevron_right, color: BColors.tinta3),
      ]),
    );
  }
}

/// Tarjeta de un préstamo con franja amarilla "Te toca…" si le toca confirmar.
class TarjetaPrestamo extends StatelessWidget {
  const TarjetaPrestamo(this.p, {super.key, required this.onTap});
  final Prestamo p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final yo = Servicios.i.sesion.usuario!.id;
    final soySolicitante = p.solicitanteId == yo;
    final accion = Servicios.i.prestamos.accionPendiente(p, yo);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(BRadios.tarjeta),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BRadios.tarjeta),
            border: Border.all(color: BColors.linea),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                IconoCategoria(p.objeto),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.objeto,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    NombreUsuario(
                      soySolicitante ? p.prestadorId : p.solicitanteId,
                      prefijo: soySolicitante ? 'Te lo presta ' : 'Se lo prestas a ',
                      estilo: const TextStyle(color: BColors.tinta2, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                        '${Formato.rango(p.fechaInicio, p.fechaFin)} · ${Formato.dinero(p.precioTotal, gratisSiCero: true)}',
                        style: const TextStyle(color: BColors.tinta2, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      ChipEstado.prestamo(p.estado, enConflicto: p.enConflicto),
                      if (p.vencido)
                        const ChipEstado('Vencido', Icons.event_busy, BColors.errorFondo, BColors.error),
                    ]),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: BColors.tinta3),
              ]),
            ),
            if (accion != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: BColors.sol100,
                child: Row(children: [
                  const Icon(Icons.touch_app_outlined, size: 20, color: BColors.solTexto),
                  const SizedBox(width: 8),
                  Text(accion,
                      style: const TextStyle(
                          color: BColors.solTexto, fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Stepper horizontal del préstamo: Confirmado → Entrega → Activo → Devolución → Finalizado.
class StepperPrestamo extends StatelessWidget {
  const StepperPrestamo({super.key, required this.estado});
  final EstadoPrestamo estado;

  static const _pasos = ['Confirmado', 'Entrega', 'Activo', 'Devolución', 'Finalizado'];

  @override
  Widget build(BuildContext context) {
    final actual = estado.index;
    return Row(
      children: [
        for (var i = 0; i < _pasos.length; i++) ...[
          Expanded(
            child: Column(children: [
              _Nodo(hecho: i < actual || estado == EstadoPrestamo.finalizado, actual: i == actual && estado != EstadoPrestamo.finalizado),
              const SizedBox(height: 6),
              Text(_pasos[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: i == actual ? FontWeight.w700 : FontWeight.w500,
                      color: i <= actual ? BColors.tinta : BColors.tinta3)),
            ]),
          ),
        ],
      ],
    );
  }
}

class _Nodo extends StatelessWidget {
  const _Nodo({required this.hecho, required this.actual});
  final bool hecho;
  final bool actual;

  @override
  Widget build(BuildContext context) {
    final color = hecho ? BColors.laguna700 : (actual ? BColors.sol400 : BColors.bruma);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: const Cubic(.2, .8, .2, 1),
      width: actual ? 30 : 26,
      height: actual ? 30 : 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: actual
            ? [BoxShadow(color: BColors.sol400.withValues(alpha: 0.45), blurRadius: 10, spreadRadius: 2)]
            : null,
      ),
      child: hecho
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : (actual ? const Icon(Icons.more_horiz, size: 18, color: BColors.tinta) : null),
    );
  }
}
