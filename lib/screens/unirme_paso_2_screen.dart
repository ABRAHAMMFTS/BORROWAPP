import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../widgets/componentes.dart';
import 'inicio_screen.dart';

// P05: Unirme paso 2
// Confirma la organización e ingresa el identificador
class UnirmePaso2Screen extends StatefulWidget {
  const UnirmePaso2Screen({super.key, required this.organizacion});

  final Organizacion organizacion;

  @override
  State<UnirmePaso2Screen> createState() => _UnirmePaso2ScreenState();
}

class _UnirmePaso2ScreenState extends State<UnirmePaso2Screen> {
  final _idCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;

  Future<void> _unirme() async {
    final usuario = Servicios.i.sesion.usuario;
    if (usuario == null) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await Servicios.i.organizaciones.unirse(
        usuarioId: usuario.id,
        organizacion: widget.organizacion,
        identificadorInterno: _idCtrl.text,
      );
      await Servicios.i.sesion.recargar(
        activarOrganizacionId: widget.organizacion.id,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const InicioScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unirme (Paso 2)'),
        backgroundColor: BColors.sal,
      ),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Vista previa: ícono según el tipo, nombre, tipo y punto central.
              TarjetaBlanca(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: BColors.laguna100,
                    child: Icon(
                      iconoDeTipoOrganizacion(widget.organizacion.tipo),
                      size: 36,
                      color: BColors.laguna700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.organizacion.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(widget.organizacion.tipo.etiqueta,
                      style: const TextStyle(color: BColors.tinta2)),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.place_outlined, size: 18, color: BColors.tinta3),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(widget.organizacion.puntoCentral,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: BColors.tinta2, fontSize: 13)),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _idCtrl,
                decoration: InputDecoration(
                  labelText: widget.organizacion.tipo.etiquetaIdentificador,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: BColors.error)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _unirme,
                  child: const Text('¡Unirme a la comunidad!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
