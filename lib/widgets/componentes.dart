import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';

// Componentes visuales reutilizables de BorrowApp (DESIGN.md sección 6).
// Se guardan aquí para que las pantallas no repitan estilos.

/// Muestra un aviso breve abajo. Los errores van con ícono de alerta.
void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: error ? BColors.error : BColors.tinta,
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(texto)),
      ]),
    ));
}

/// Cuadro de confirmación centrado con radio 28. Devuelve true si acepta.
Future<bool> confirmarDialogo(
  BuildContext context, {
  required String titulo,
  required String texto,
  String confirmar = 'Confirmar',
  bool peligro = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
      content: Text(texto, style: const TextStyle(color: BColors.tinta2)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: peligro ? BColors.error : BColors.laguna700),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmar),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Botón principal (laguna-700). Muestra un círculo girando si está cargando.
class BotonPrimario extends StatelessWidget {
  const BotonPrimario(this.texto,
      {super.key, this.onPressed, this.cargando = false, this.icono});
  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: cargando ? null : onPressed,
      child: cargando
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: BColors.laguna700))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icono != null) ...[Icon(icono, size: 20), const SizedBox(width: 8)],
              Text(texto),
            ]),
    );
  }
}

/// Botón Sol: SOLO uno por pantalla y solo sobre fondo Marea (DESIGN.md 10).
class BotonSol extends StatelessWidget {
  const BotonSol(this.texto, {super.key, this.onPressed, this.icono});
  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: BColors.sol400, foregroundColor: BColors.tinta),
      onPressed: onPressed,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icono != null) ...[Icon(icono, size: 20), const SizedBox(width: 8)],
        Text(texto),
      ]),
    );
  }
}

/// Botón de contorno blanco para fondos oscuros (Marea).
class BotonVidrio extends StatelessWidget {
  const BotonVidrio(this.texto, {super.key, this.onPressed, this.icono});
  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54, width: 1.5),
        backgroundColor: Colors.white.withValues(alpha: 0.14),
      ),
      onPressed: onPressed,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icono != null) ...[Icon(icono, size: 20), const SizedBox(width: 8)],
        Text(texto),
      ]),
    );
  }
}

/// Barra fija inferior para el botón de acción de las pantallas de formulario.
class BarraAccion extends StatelessWidget {
  const BarraAccion({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: BColors.linea)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

/// Tarjeta blanca estándar (radio 20, borde suave).
class TarjetaBlanca extends StatelessWidget {
  const TarjetaBlanca(
      {super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(BRadios.tarjeta),
      child: InkWell(
        borderRadius: BorderRadius.circular(BRadios.tarjeta),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BRadios.tarjeta),
            border: Border.all(color: BColors.linea),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Título de sección dentro de una pantalla.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.accion});
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(texto,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: BColors.tinta))),
        ?accion,
      ]),
    );
  }
}

/// Fila "etiqueta ... valor" para detalles.
class FilaDato extends StatelessWidget {
  const FilaDato(this.etiqueta, this.valor, {super.key, this.icono});
  final String etiqueta;
  final String valor;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icono != null) ...[
          Icon(icono, size: 18, color: BColors.tinta3),
          const SizedBox(width: 10),
        ],
        SizedBox(
            width: 120,
            child: Text(etiqueta, style: const TextStyle(color: BColors.tinta2, fontSize: 13))),
        Expanded(
            child: Text(valor,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: BColors.tinta, fontSize: 14))),
      ]),
    );
  }
}

/// Avatar circular con las iniciales del usuario.
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales(this.iniciales,
      {super.key, this.tam = 40, this.fondo = BColors.laguna100, this.color = BColors.laguna800});
  final String iniciales;
  final double tam;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
      child: Text(iniciales,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: tam * 0.38)),
    );
  }
}

/// Cuadrado con ícono de categoría. El SRS no usa fotos: cada objeto se
/// representa con un ícono según su nombre (SRS 1.2).
class IconoCategoria extends StatelessWidget {
  const IconoCategoria(this.objeto, {super.key, this.tam = 48});
  final String objeto;
  final double tam;

  static IconData iconoPara(String objeto) {
    final o = objeto.toLowerCase();
    bool tiene(List<String> p) => p.any(o.contains);
    if (tiene(['taladro', 'martillo', 'herramienta', 'destornillador', 'llave'])) return Icons.handyman_outlined;
    if (tiene(['calculadora'])) return Icons.calculate_outlined;
    if (tiene(['cargador', 'cable', 'bater'])) return Icons.battery_charging_full_outlined;
    if (tiene(['proyector', 'pantalla', 'tv'])) return Icons.videocam_outlined;
    if (tiene(['bici', 'patineta', 'moto'])) return Icons.pedal_bike_outlined;
    if (tiene(['libro', 'cuaderno'])) return Icons.menu_book_outlined;
    if (tiene(['portátil', 'portatil', 'laptop', 'computador', 'tablet'])) return Icons.laptop_outlined;
    if (tiene(['cámara', 'camara'])) return Icons.photo_camera_outlined;
    if (tiene(['escalera'])) return Icons.stairs_outlined;
    return Icons.inventory_2_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tam,
      height: tam,
      decoration: BoxDecoration(
        color: BColors.laguna100,
        borderRadius: BorderRadius.circular(tam * 0.3),
      ),
      child: Icon(iconoPara(objeto), color: BColors.laguna800, size: tam * 0.5),
    );
  }
}

/// Chip de estado: SIEMPRE ícono + color juntos (DESIGN.md regla de oro).
class ChipEstado extends StatelessWidget {
  const ChipEstado(this.texto, this.icono, this.fondo, this.color, {super.key});
  final String texto;
  final IconData icono;
  final Color fondo;
  final Color color;

  factory ChipEstado.prestamo(EstadoPrestamo e, {bool enConflicto = false}) {
    if (enConflicto) {
      return const ChipEstado('En conflicto', Icons.report_problem_outlined,
          BColors.errorFondo, BColors.error);
    }
    return switch (e) {
      EstadoPrestamo.confirmado => const ChipEstado('Confirmado', Icons.handshake_outlined, BColors.infoFondo, BColors.info),
      EstadoPrestamo.entregaPendiente => const ChipEstado('Entrega pendiente', Icons.schedule, BColors.sol100, BColors.solTexto),
      EstadoPrestamo.activo => const ChipEstado('Activo', Icons.play_circle_outline, BColors.laguna100, BColors.laguna800),
      EstadoPrestamo.devolucionPendiente => const ChipEstado('Devolución pendiente', Icons.assignment_return_outlined, BColors.sol100, BColors.solTexto),
      EstadoPrestamo.finalizado => const ChipEstado('Finalizado', Icons.check_circle_outline, BColors.exitoFondo, BColors.exito),
    };
  }

  factory ChipEstado.necesidad(EstadoNecesidad e) => switch (e) {
        EstadoNecesidad.buscandoPrestador => const ChipEstado('Buscando prestador', Icons.search, BColors.laguna100, BColors.laguna800),
        EstadoNecesidad.conPrestamoConfirmado => const ChipEstado('Con préstamo', Icons.handshake_outlined, BColors.infoFondo, BColors.info),
        EstadoNecesidad.cerrada => const ChipEstado('Cerrada', Icons.lock_outline, BColors.bruma, BColors.tinta2),
      };

  factory ChipEstado.oferta(EstadoOferta e) => switch (e) {
        EstadoOferta.pendiente => const ChipEstado('Pendiente', Icons.schedule, BColors.sol100, BColors.solTexto),
        EstadoOferta.aceptada => const ChipEstado('Aceptada', Icons.check_circle_outline, BColors.exitoFondo, BColors.exito),
        EstadoOferta.rechazada => const ChipEstado('Rechazada', Icons.cancel_outlined, BColors.errorFondo, BColors.error),
        EstadoOferta.cerrada => const ChipEstado('Cerrada', Icons.lock_outline, BColors.bruma, BColors.tinta2),
      };

  factory ChipEstado.membresia(EstadoMembresia e) => switch (e) {
        EstadoMembresia.activo => const ChipEstado('Activo', Icons.check_circle_outline, BColors.exitoFondo, BColors.exito),
        EstadoMembresia.advertido => const ChipEstado('Advertido', Icons.warning_amber_rounded, BColors.sol100, BColors.solTexto),
        EstadoMembresia.suspendido => const ChipEstado('Suspendido', Icons.pause_circle_outline, BColors.errorFondo, BColors.error),
        EstadoMembresia.baneado => const ChipEstado('Baneado', Icons.block, BColors.errorFondo, BColors.error),
      };

  factory ChipEstado.modalidad(Modalidad m) => m == Modalidad.gratis
      ? const ChipEstado('Gratis', Icons.volunteer_activism_outlined, BColors.laguna100, BColors.laguna800)
      : const ChipEstado('Alquiler', Icons.payments_outlined, BColors.sol100, BColors.solTexto);

  /// Chip del papel en una operación (historial).
  factory ChipEstado.papel(bool solicitante) => solicitante
      ? const ChipEstado('Solicitante', Icons.back_hand_outlined, BColors.laguna100, BColors.laguna800)
      : const ChipEstado('Prestador', Icons.inventory_2_outlined, BColors.sol100, BColors.solTexto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(BRadios.chip)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 14, color: color),
        const SizedBox(width: 5),
        Text(texto, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Banner de sanción: barra izquierda de color, ícono, título y detalle.
class BannerSancion extends StatelessWidget {
  const BannerSancion({super.key, required this.estado, required this.detalle});
  final EstadoMembresia estado;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final (titulo, icono, fondo, color) = switch (estado) {
      EstadoMembresia.advertido => ('Tienes una advertencia', Icons.warning_amber_rounded, BColors.sol100, BColors.solTexto),
      EstadoMembresia.suspendido => ('Estás suspendido en esta organización', Icons.pause_circle_outline, BColors.errorFondo, BColors.error),
      _ => ('Fuiste baneado de esta organización', Icons.block, BColors.errorFondo, BColors.error),
    };
    return Container(
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(16)),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icono, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: BColors.tinta)),
                    const SizedBox(height: 2),
                    Text(detalle, style: const TextStyle(fontSize: 13, color: BColors.tinta2)),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Estado vacío: ilustración "El Encuentro", título, texto y acción opcional.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio(
      {super.key, required this.titulo, required this.texto, this.accion, this.onAccion});
  final String titulo;
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
              width: 160, height: 110, child: CustomPaint(painter: _EncuentroPainter())),
          const SizedBox(height: 16),
          Text(titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: BColors.tinta)),
          const SizedBox(height: 8),
          Text(texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: BColors.tinta2, height: 1.4)),
          if (accion != null) ...[
            const SizedBox(height: 18),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                  backgroundColor: BColors.laguna100, foregroundColor: BColors.laguna800),
              onPressed: onAccion,
              child: Text(accion!),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Dibuja "El Encuentro": dos círculos que se cruzan (Sol y Laguna).
class _EncuentroPainter extends CustomPainter {
  const _EncuentroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.height * 0.36;
    canvas.drawCircle(c.translate(-r * 0.6, 0), r, Paint()..color = BColors.sol400.withValues(alpha: 0.85));
    canvas.drawCircle(c.translate(r * 0.6, 0), r, Paint()..color = BColors.laguna500.withValues(alpha: 0.85));
    final ola = Paint()
      ..color = BColors.laguna200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 2; i++) {
      final y = size.height * (0.88 + i * 0.1) - 4;
      final p = Path()..moveTo(size.width * 0.1, y);
      for (var x = 0.1; x < 0.9; x += 0.2) {
        p.quadraticBezierTo(size.width * (x + 0.05), y - 6, size.width * (x + 0.1), y);
        p.quadraticBezierTo(size.width * (x + 0.15), y + 6, size.width * (x + 0.2), y);
      }
      canvas.drawPath(p, ola);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
