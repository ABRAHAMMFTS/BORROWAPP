import 'package:flutter/material.dart';

/// Atajos de navegación para no repetir `MaterialPageRoute` en cada pantalla.
class Nav {
  /// Abre una pantalla encima de la actual (se puede volver con la flecha).
  static Future<T?> ir<T>(BuildContext context, Widget pantalla) =>
      Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => pantalla));

  /// Reemplaza TODO el historial: se usa al entrar o salir de la sesión para
  /// que el botón "atrás" no regrese a pantallas anteriores.
  static void reiniciarEn(BuildContext context, Widget pantalla) {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => pantalla), (_) => false);
  }

  /// Vuelve a la primera pantalla del historial (el inicio con barra inferior).
  static void alInicio(BuildContext context) =>
      Navigator.of(context).popUntil((r) => r.isFirst);
}
