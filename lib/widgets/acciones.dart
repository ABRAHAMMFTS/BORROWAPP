import 'package:flutter/material.dart';
import '../utils/regla_negocio_exception.dart';
import 'componentes.dart';

/// Ejecuta una acción de un servicio y muestra el error al usuario si se
/// rompe una regla del negocio. Devuelve `true` si todo salió bien.
///
/// Así cada pantalla no repite el mismo `try/catch`:
/// ```dart
/// final ok = await ejecutar(context, () => servicio.publicar(...));
/// if (ok) Navigator.pop(context);
/// ```
Future<bool> ejecutar(BuildContext context, Future<void> Function() accion) async {
  try {
    await accion();
    return true;
  } on ReglaNegocioException catch (e) {
    if (context.mounted) mostrarMensaje(context, e.mensaje, error: true);
  } catch (e) {
    if (context.mounted) {
      mostrarMensaje(context, 'Algo salió mal. Inténtalo de nuevo.', error: true);
    }
  }
  return false;
}
