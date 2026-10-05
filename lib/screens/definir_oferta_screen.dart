import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import 'ofertas_recibidas_screen.dart';

// P11: Formulario para definir las condiciones de una oferta.
class DefinirOfertaScreen extends StatefulWidget {
  const DefinirOfertaScreen({super.key, required this.necesidad});

  final Necesidad necesidad;

  @override
  State<DefinirOfertaScreen> createState() => _DefinirOfertaScreenState();
}

class _DefinirOfertaScreenState extends State<DefinirOfertaScreen> {
  final _precioCtrl = TextEditingController();
  Modalidad _modalidad = Modalidad.gratis;
  UnidadCobro _unidad = UnidadCobro.dia;
  DateTime _entrega = DateTime.now().add(const Duration(days: 1));
  bool _cargando = false;
  String? _error;

  double get _total {
    // El servicio centraliza la regla: gratis es cero y alquiler depende
    // del precio y de los días u horas de la necesidad.
    final precio = double.tryParse(_precioCtrl.text.replaceAll(',', '.'));
    return Servicios.i.necesidades.calcularTotal(
      necesidad: widget.necesidad,
      modalidad: _modalidad,
      precio: precio,
      unidad: _unidad,
    );
  }

  String _fechaHora(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
      '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

  Future<void> _seleccionarEntrega() async {
    // Primero se elige el día y después la hora de entrega.
    final fecha = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: widget.necesidad.fechaFin,
      initialDate: _entrega.isAfter(widget.necesidad.fechaFin)
          ? widget.necesidad.fechaFin
          : _entrega,
      helpText: 'Selecciona el día de entrega',
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_entrega),
    );
    if (hora == null || !mounted) return;
    setState(() {
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
      await Servicios.i.necesidades.crearOferta(
        prestadorId: usuario.id,
        necesidadId: widget.necesidad.id,
        modalidad: _modalidad,
        precio: double.tryParse(_precioCtrl.text.replaceAll(',', '.')),
        unidad: _unidad,
        fechaEntrega: _entrega,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OfertasRecibidasScreen()),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: BColors.laguna50,
                  borderRadius: BorderRadius.circular(BRadios.tarjeta),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL CALCULADO'),
                    Text(
                      '\$${_total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: BColors.laguna700,
                      ),
                    ),
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
