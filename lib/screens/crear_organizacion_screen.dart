import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import 'organizacion_creada_screen.dart';

// P06: Formulario para crear una organización.
class CrearOrganizacionScreen extends StatefulWidget {
  const CrearOrganizacionScreen({super.key});

  @override
  State<CrearOrganizacionScreen> createState() =>
      _CrearOrganizacionScreenState();
}

class _CrearOrganizacionScreenState extends State<CrearOrganizacionScreen> {
  final _nombreCtrl = TextEditingController();
  final _identificadorCtrl = TextEditingController();
  final _puntoCentralCtrl = TextEditingController();
  String _tipo = 'Universidad';
  final String _identificador = 'Tu código estudiantil/empleado/apto';

  bool _cargando = false;
  String? _error;

  Future<void> _crear() async {
    final usuario = Servicios.i.sesion.usuario;
    if (usuario == null) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    // El servicio genera el código y registra al creador como administrador.
    try {
      final tipo = switch (_tipo) {
        'Empresa' => TipoOrganizacion.empresa,
        'Conjunto Residencial' => TipoOrganizacion.conjuntoResidencial,
        _ => TipoOrganizacion.universidad,
      };
      final organizacion = await Servicios.i.organizaciones.crear(
        usuarioId: usuario.id,
        nombre: _nombreCtrl.text,
        tipo: tipo,
        puntoCentral: _puntoCentralCtrl.text,
        identificadorInterno: _identificadorCtrl.text,
      );
      await Servicios.i.sesion.recargar(activarOrganizacionId: organizacion.id);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrganizacionCreadaScreen(organizacion: organizacion),
        ),
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
    _nombreCtrl.dispose();
    _identificadorCtrl.dispose();
    _puntoCentralCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Organización'),
        backgroundColor: BColors.sal,
      ),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: InputDecoration(
                  labelText: 'Tipo',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['Universidad', 'Empresa', 'Conjunto Residencial'].map((
                  t,
                ) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _tipo = val!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _identificadorCtrl,
                decoration: InputDecoration(
                  labelText: 'Identificador interno',
                  hintText: _identificador,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: BColors.error)),
              TextField(
                controller: _puntoCentralCtrl,
                decoration: InputDecoration(
                  labelText: 'Punto común de entrega y devolución',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _crear,
                  child: const Text('Crear organización'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
