import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../utils/regla_negocio_exception.dart';
import 'oferta_enviada_screen.dart';

// P11: Formulario para definir las condiciones de una oferta.
class DefinirOfertaScreen extends StatefulWidget {
  const DefinirOfertaScreen({super.key, required this.necesidad});

  final Necesidad necesidad;

  @override
  State<DefinirOfertaScreen> createState() => _DefinirOfertaScreenState();
}

class _DefinirOfertaScreenState extends State<DefinirOfertaScreen> {
  /// Punto central de la organización de la necesidad (solo lectura).
  String get _puntoCentral =>
      Servicios.i.sesion.organizacion(widget.necesidad.organizacionId)?.puntoCentral ??
      '';

  final _precioCtrl = TextEditingController();
  Modalidad _modalidad = Modalidad.gratis;
  UnidadCobro _unidad = UnidadCobro.dia;
  DateTime _entrega = DateTime.now().add(const Duration(days: 1));
  bool _cargando = false;
  String? _error;

  /// Convierte lo escrito a número. En Colombia el punto separa miles
  /// ("10.000") y la coma los decimales.
  double? get _precio => double.tryParse(
      _precioCtrl.text.trim().replaceAll('.', '').replaceAll(',', '.'));

  double get _total {
    // El servicio centraliza la regla: gratis es cero y alquiler depende
    // del precio y de los días u horas de la necesidad.
    return Servicios.i.necesidades.calcularTotal(
      necesidad: widget.necesidad,
      modalidad: _modalidad,
      precio: _precio,
      unidad: _unidad,
    );
  }

  /// Texto del cálculo, por ejemplo "$10.000 x 3 días = $30.000".
  String get _detalleTotal {
    final precio = _precio;
    if (_modalidad == Modalidad.gratis || precio == null || precio <= 0) {
      return '';
    }
    final dias = widget.necesidad.dias;
    final cantidad = _unidad == UnidadCobro.dia ? dias : dias * 24;
    final unidad = _unidad == UnidadCobro.dia
        ? (cantidad == 1 ? 'día' : 'días')
        : (cantidad == 1 ? 'hora' : 'horas');
    return '${Formato.dinero(precio)} x $cantidad $unidad = ${Formato.dinero(_total)}';
  }

  String _fechaHora(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
      '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

  Future<void> _seleccionarEntrega() async {
    // Primero se elige el día y después la hora de entrega. El último día
    // permitido es el de fin de la necesidad (hasta el final de ese día).
    final ahora = DateTime.now();
    final fin = widget.necesidad.fechaFin;
    final ultimo = DateTime(fin.year, fin.month, fin.day, 23, 59);
    final primero = DateTime(ahora.year, ahora.month, ahora.day);
    if (ultimo.isBefore(primero)) {
      setState(() => _error = 'Esta necesidad ya terminó.');
      return;
    }
    var inicial = _entrega;
    if (inicial.isAfter(ultimo)) inicial = ultimo;
    if (inicial.isBefore(primero)) inicial = primero;
    final fecha = await showDatePicker(
      context: context,
      firstDate: primero,
      lastDate: ultimo,
      initialDate: inicial,
      helpText: 'Selecciona el día de entrega',
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_entrega),
    );
    if (hora == null || !mounted) return;
    setState(() {
      _error = null;
      _entrega = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _publicar() async {
    final usuario = Servicios.i.sesion.usuario;
    if (usuario == null) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    // La oferta queda pendiente hasta que el solicitante la acepte.
    try {
      final oferta = await Servicios.i.necesidades.crearOferta(
        prestadorId: usuario.id,
        necesidadId: widget.necesidad.id,
        modalidad: _modalidad,
        precio: _precio,
        unidad: _unidad,
        fechaEntrega: _entrega,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OfertaEnviadaScreen(
              necesidad: widget.necesidad, oferta: oferta),
        ),
      );
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
  void dispose() {
    _precioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Definir oferta')),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.necesidad.objeto,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Elige las condiciones para ayudar a esta persona.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SegmentedButton<Modalidad>(
                segments: const [
                  ButtonSegment(
                    value: Modalidad.gratis,
                    label: Text('Préstamo gratuito'),
                  ),
                  ButtonSegment(
                    value: Modalidad.alquiler,
                    label: Text('Alquilar'),
                  ),
                ],
                selected: {_modalidad},
                onSelectionChanged: (value) =>
                    setState(() => _modalidad = value.first),
              ),
              if (_modalidad == Modalidad.alquiler) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _precioCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                          hintText: 'Ej. 5000',
                          prefixText: '\$ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<UnidadCobro>(
                        initialValue: _unidad,
                        decoration: const InputDecoration(labelText: 'Cobro'),
                        items: const [
                          DropdownMenuItem(
                            value: UnidadCobro.hora,
                            child: Text('Por hora'),
                          ),
                          DropdownMenuItem(
                            value: UnidadCobro.dia,
                            child: Text('Por día'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _unidad = value!),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                readOnly: true,
                onTap: _seleccionarEntrega,
                decoration: InputDecoration(
                  labelText: 'Fecha y hora de entrega',
                  hintText: _fechaHora(_entrega),
                  suffixIcon: const Icon(Icons.calendar_month),
                ),
              ),
              const SizedBox(height: 20),
              // Punto de entrega: solo lectura (SRS, P11).
              TextFormField(
                key: ValueKey(_puntoCentral),
                initialValue: _puntoCentral,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Punto de entrega',
                  helperText: 'Lo define la organización; no se puede cambiar.',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: BColors.laguna50,
                  borderRadius: BorderRadius.circular(BRadios.tarjeta),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total calculado'),
                        Text(
                          Formato.dinero(_total),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: BColors.laguna700,
                          ),
                        ),
                      ],
                    ),
                    if (_detalleTotal.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(_detalleTotal,
                          style: const TextStyle(color: BColors.tinta2, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: BColors.error)),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _publicar,
                  child: Text(
                    _cargando ? 'Publicando...' : 'Publicar mis condiciones',
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
