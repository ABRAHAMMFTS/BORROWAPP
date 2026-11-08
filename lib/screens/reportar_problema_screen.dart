import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../utils/regla_negocio_exception.dart';
import '../widgets/componentes.dart';
import '../widgets/tarjetas.dart';

/// RF-014 · Pantalla para reportar un problema sobre un préstamo en curso.
class ReportarProblemaScreen extends StatefulWidget {
  const ReportarProblemaScreen({super.key, required this.prestamo});

  final Prestamo prestamo;

  @override
  State<ReportarProblemaScreen> createState() => _ReportarProblemaScreenState();
}

class _ReportarProblemaScreenState extends State<ReportarProblemaScreen> {
  TipoReporte _tipo = TipoReporte.noDevuelto;
  final _descripcionCtrl = TextEditingController();
  bool _enviando = false;
  String? _error;

  static const _opciones = <({TipoReporte tipo, String etiqueta})>[
    (tipo: TipoReporte.noDevuelto, etiqueta: 'El objeto no fue devuelto'),
    (tipo: TipoReporte.danado, etiqueta: 'El objeto está dañado'),
    (tipo: TipoReporte.inasistencia, etiqueta: 'La otra persona no asistió'),
  ];

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final usuario = Servicios.i.sesion.usuario;
    if (usuario == null) return;
    final texto = _descripcionCtrl.text.trim();
    if (texto.length < 10) {
      setState(
        () => _error = 'La descripción debe tener al menos 10 caracteres.',
      );
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await Servicios.i.prestamos.reportar(
        prestamoId: widget.prestamo.id,
        reportanteId: usuario.id,
        tipo: _tipo,
        descripcion: texto,
      );
      if (!mounted) return;
      mostrarMensaje(
        context,
        'Reporte enviado al administrador de tu organización.',
      );
      Navigator.pop(context, true);
    } on ReglaNegocioException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Algo salió mal. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prestamo;
    final yo = Servicios.i.sesion.usuario?.id;
    final soySolicitante = p.solicitanteId == yo;
    final contraparteId = soySolicitante ? p.prestadorId : p.solicitanteId;

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar un problema')),
      backgroundColor: BColors.sal,
      bottomNavigationBar: BarraAccion(
        child: BotonPrimario(
          'Enviar reporte',
          icono: Icons.flag_outlined,
          cargando: _enviando,
          onPressed: _enviar,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Préstamo asociado
              TarjetaBlanca(
                child: Row(
                  children: [
                    IconoCategoria(p.objeto),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.objeto,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          NombreUsuario(
                            contraparteId,
                            prefijo: 'Contraparte: ',
                            estilo: const TextStyle(
                              color: BColors.tinta2,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formato.rango(p.fechaInicio, p.fechaFin),
                            style: const TextStyle(
                              color: BColors.tinta2,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const TituloSeccion('¿Qué ocurrió?'),
              for (final op in _opciones)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OpcionTipoReporte(
                    etiqueta: op.etiqueta,
                    seleccionada: _tipo == op.tipo,
                    onTap: () => setState(() => _tipo = op.tipo),
                  ),
                ),
              const SizedBox(height: 12),
              const TituloSeccion('Descripción del problema'),
              TextField(
                controller: _descripcionCtrl,
                maxLines: 4,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: const InputDecoration(
                  hintText:
                      'Explica qué pasó con el objeto o la entrega (mínimo 10 caracteres)...',
                  helperText: 'Mínimo 10 caracteres',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: BColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BColors.sol100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: BColors.solTexto,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tu reporte será enviado al administrador de tu organización',
                        style: TextStyle(
                          color: BColors.solTexto,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionTipoReporte extends StatelessWidget {
  const _OpcionTipoReporte({
    required this.etiqueta,
    required this.seleccionada,
    required this.onTap,
  });

  final String etiqueta;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: seleccionada ? BColors.laguna50 : Colors.white,
      borderRadius: BorderRadius.circular(BRadios.campo),
      child: InkWell(
        borderRadius: BorderRadius.circular(BRadios.campo),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BRadios.campo),
            border: Border.all(
              color: seleccionada ? BColors.laguna700 : BColors.linea,
              width: seleccionada ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                seleccionada
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: seleccionada ? BColors.laguna700 : BColors.tinta3,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  etiqueta,
                  style: TextStyle(
                    fontWeight:
                        seleccionada ? FontWeight.w700 : FontWeight.w500,
                    color: BColors.tinta,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

