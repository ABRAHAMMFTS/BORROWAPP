import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Piezas visuales del degradado "Marea": fondo con ondas, logo y animación de éxito.

/// Fondo con el degradado Marea y círculos concéntricos tipo ondas.
class FondoMarea extends StatelessWidget {
  const FondoMarea({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: marea),
      child: CustomPaint(painter: const _OndasPainter(), child: child),
    );
  }
}

class _OndasPainter extends CustomPainter {
  const _OndasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.07);
    final centro = Offset(size.width * 0.85, size.height * 0.12);
    for (var i = 1; i <= 6; i++) {
      canvas.drawCircle(centro, 60.0 * i, p);
    }
    final centro2 = Offset(size.width * 0.05, size.height * 0.95);
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(centro2, 70.0 * i, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Logo "El Encuentro": dos círculos que se cruzan.
class LogoEncuentro extends StatelessWidget {
  const LogoEncuentro({super.key, this.tam = 44, this.conTexto = false, this.claro = true});
  final double tam;
  final bool conTexto;
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final texto = claro ? Colors.white : BColors.laguna800;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: tam * 1.5,
        height: tam,
        child: CustomPaint(painter: _LogoPainter(claro)),
      ),
      if (conTexto) ...[
        const SizedBox(width: 10),
        Text('BorrowApp',
            style: TextStyle(
                color: texto, fontSize: tam * 0.5, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      ],
    ]);
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.claro);
  final bool claro;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    canvas.drawCircle(Offset(r, r), r, Paint()..color = BColors.sol400);
    canvas.drawCircle(Offset(size.width - r, r), r,
        Paint()..color = claro ? Colors.white.withValues(alpha: 0.9) : BColors.laguna500);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.claro != claro;
}

/// Animación de éxito (DESIGN.md sección 8): 3 círculos que crecen y se
/// desvanecen una sola vez (900 ms) y un check que se dibuja (400 ms).
class AnimacionExito extends StatefulWidget {
  const AnimacionExito({super.key, this.tam = 160});
  final double tam;

  @override
  State<AnimacionExito> createState() => _AnimacionExitoState();
}

class _AnimacionExitoState extends State<AnimacionExito>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
        ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.tam,
      height: widget.tam,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(painter: _ExitoPainter(_c.value)),
      ),
    );
  }
}

class _ExitoPainter extends CustomPainter {
  _ExitoPainter(this.t);
  final double t; // 0..1 sobre 1300 ms

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.width / 2;
    // Ondas: 0 a 900 ms (t de 0 a 0.69), escalonadas.
    for (var i = 0; i < 3; i++) {
      final local = ((t / 0.69) - i * 0.2).clamp(0.0, 1.0);
      if (local <= 0) continue;
      canvas.drawCircle(
        c,
        maxR * (0.35 + 0.65 * local),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: (1 - local) * 0.6),
      );
    }
    // Círculo central.
    canvas.drawCircle(c, maxR * 0.38, Paint()..color = BColors.sol400);
    // Check dibujado entre 900 y 1300 ms.
    final k = ((t - 0.69) / 0.31).clamp(0.0, 1.0);
    if (k > 0) {
      final a = Offset(c.dx - maxR * 0.17, c.dy + maxR * 0.02);
      final b = Offset(c.dx - maxR * 0.04, c.dy + maxR * 0.15);
      final d = Offset(c.dx + maxR * 0.2, c.dy - maxR * 0.12);
      final path = Path()..moveTo(a.dx, a.dy);
      if (k < 0.45) {
        final f = k / 0.45;
        path.lineTo(a.dx + (b.dx - a.dx) * f, a.dy + (b.dy - a.dy) * f);
      } else {
        final f = (k - 0.45) / 0.55;
        path.lineTo(b.dx, b.dy);
        path.lineTo(b.dx + (d.dx - b.dx) * f, b.dy + (d.dy - b.dy) * f);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(4, maxR * 0.07)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = BColors.tinta,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExitoPainter old) => old.t != t;
}
