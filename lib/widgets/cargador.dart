import 'package:flutter/material.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';

/// Carga datos de forma asíncrona y los vuelve a pedir cuando cambia la sesión
/// (por ejemplo al cambiar de organización activa). Así las pantallas siempre
/// muestran información al día sin tener que manejar `setState` a mano.
///
/// Uso:
/// ```dart
/// Cargador<List<Necesidad>>(
///   cargar: () => servicios.necesidades.listar(orgId),
///   builder: (context, datos) => ...,
/// )
/// ```
class Cargador<T> extends StatefulWidget {
  const Cargador({super.key, required this.cargar, required this.builder});

  final Future<T> Function() cargar;
  final Widget Function(BuildContext context, T datos) builder;

  @override
  State<Cargador<T>> createState() => _CargadorState<T>();
}

class _CargadorState<T> extends State<Cargador<T>> {
  late Future<T> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = widget.cargar();
    // Cada vez que la sesión avisa un cambio, se recarga la información.
    Servicios.i.sesion.addListener(_recargar);
  }

  @override
  void dispose() {
    Servicios.i.sesion.removeListener(_recargar);
    super.dispose();
  }

  void _recargar() {
    if (mounted) setState(() => _futuro = widget.cargar());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: BColors.laguna700));
        }
        if (snap.hasError) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No pudimos cargar la información.\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: BColors.tinta2)),
          ));
        }
        return widget.builder(context, snap.data as T);
      },
    );
  }
}
