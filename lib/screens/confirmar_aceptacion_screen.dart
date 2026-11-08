import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../utils/regla_negocio_exception.dart';
import '../widgets/componentes.dart';
import '../widgets/tarjetas.dart';
import 'prestamo_activo_screen.dart';

// P13: Confirmar aceptación de una oferta. Al aceptar se crea el préstamo.
class ConfirmarAceptacionScreen extends StatefulWidget {
  const ConfirmarAceptacionScreen(
      {super.key, required this.oferta, required this.necesidad});

  final Oferta oferta;
  final Necesidad necesidad;

  @override
  State<ConfirmarAceptacionScreen> createState() =>
      _ConfirmarAceptacionScreenState();
}

class _ConfirmarAceptacionScreenState extends State<ConfirmarAceptacionScreen> {
  bool _cargando = false;
  String? _error;

  Future<void> _aceptar() async {
    final usuario = Servicios.i.sesion.usuario;
    if (usuario == null) return;
    final navegador = Navigator.of(context);
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      // En una sola operación: oferta aceptada, demás ofertas cerradas,
      // necesidad con préstamo confirmado y préstamo CONFIRMADO.
      final prestamo = await Servicios.i.necesidades.aceptarOferta(
        solicitanteId: usuario.id,
        ofertaId: widget.oferta.id,
      );
      // Vuelve al inicio y abre el detalle del préstamo recién creado.
      navegador.popUntil((r) => r.isFirst);
      navegador.push(MaterialPageRoute(
        builder: (_) => PrestamoActivoScreen(prestamo: prestamo),
      ));
    } on ReglaNegocioException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Algo salió mal. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.oferta;
    final n = widget.necesidad;
    final total = Servicios.i.necesidades.calcularTotal(
      necesidad: n,
      modalidad: o.modalidad,
      precio: o.precio,
      unidad: o.unidadCobro,
    );
    final punto =
        Servicios.i.sesion.organizacion(n.organizacionId)?.puntoCentral ?? '';
    final alquiler = o.modalidad == Modalidad.alquiler;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cargando ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    const Icon(Icons.info_outline, size: 72, color: BColors.sol400),
                    const SizedBox(height: 16),
                    const Text(
                      '¿Aceptar estas condiciones?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TarjetaBlanca(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          IconoCategoria(n.objeto),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(n.objeto,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                          ),
                          ChipEstado.modalidad(o.modalidad),
                        ]),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(children: [
                            const SizedBox(
                                width: 120,
                                child: Text('Prestador',
                                    style: TextStyle(color: BColors.tinta2, fontSize: 13))),
                            Expanded(
                              child: NombreUsuario(o.prestadorId,
                                  estilo: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                          ]),
                        ),
                        if (alquiler)
                          FilaDato(
                              'Precio',
                              '${Formato.dinero(o.precio ?? 0)} / '
                                  '${o.unidadCobro == UnidadCobro.hora ? 'hora' : 'día'}'),
                        FilaDato('Total', Formato.dinero(total, gratisSiCero: true)),
                        FilaDato('Entrega', Formato.fechaHora(o.fechaEntrega)),
                        FilaDato('Punto central', punto),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Las demás ofertas de esta necesidad se cerrarán automáticamente',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: BColors.tinta2),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: BColors.error)),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              BotonPrimario('Sí, aceptar', cargando: _cargando, onPressed: _aceptar),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _cargando ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
