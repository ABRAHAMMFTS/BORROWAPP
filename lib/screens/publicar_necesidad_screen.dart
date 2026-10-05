import 'package:flutter/material.dart';

import '../services/servicios.dart';
import '../theme/app_theme.dart';

// P09: Formulario para publicar una necesidad.
class PublicarNecesidadScreen extends StatefulWidget {
  const PublicarNecesidadScreen({super.key});

  @override
  State<PublicarNecesidadScreen> createState() =>
      _PublicarNecesidadScreenState();
}

class _PublicarNecesidadScreenState extends State<PublicarNecesidadScreen> {
  final _objeto = TextEditingController();
  final _descripcion = TextEditingController();
  DateTime _inicio = DateTime.now().add(const Duration(days: 1));
  DateTime _fin = DateTime.now().add(const Duration(days: 3));
  bool _cargando = false;
  String? _error;

  String _fecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  Future<void> _seleccionarFecha({required bool inicio}) async {
    // El calendario evita fechas escritas con formatos inválidos.
    final actual = inicio ? _inicio : _fin;
    final fecha = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: actual.isBefore(DateTime.now()) ? DateTime.now() : actual,
      helpText: inicio
          ? 'Selecciona la fecha de inicio'
          : 'Selecciona la fecha de fin',
    );
    if (fecha == null || !mounted) return;
    setState(() {
      if (inicio) {
        _inicio = fecha;
        if (_fin.isBefore(fecha)) _fin = fecha;
      } else {
        _fin = fecha;
      }
    });
  }

  @override
  void dispose() {
    _objeto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    final usuario = Servicios.i.sesion.usuario;
    final organizacion = Servicios.i.sesion.organizacionActiva;
    if (usuario == null || organizacion == null) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    // La publicación se guarda mediante el servicio, no solo en la pantalla.
    try {
      await Servicios.i.necesidades.publicar(
        solicitanteId: usuario.id,
        organizacionId: organizacion.id,
        objeto: _objeto.text,
        descripcion: _descripcion.text,
        fechaInicio: _inicio,
        fechaFin: _fin,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Necesidad'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Text(_error!, style: const TextStyle(color: BColors.error)),
              TextField(
                controller: _objeto,
                decoration: InputDecoration(
                  labelText: 'Objeto',
                  hintText: 'Ej. Calculadora científica',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descripcion,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Para qué lo necesitas...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      onTap: () => _seleccionarFecha(inicio: true),
                      decoration: InputDecoration(
                        labelText: 'Fecha inicio',
                        hintText: _fecha(_inicio),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      onTap: () => _seleccionarFecha(inicio: false),
                      decoration: InputDecoration(
                        labelText: 'Fecha fin',
                        hintText: _fecha(_fin),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _publicar,
                  child: const Text('Publicar necesidad'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
