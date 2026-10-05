/// Funciones para mostrar fechas y dinero en español de Colombia.
class Formato {
  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// Ejemplo: 14 sep 2026
  static String fecha(DateTime f) => '${f.day} ${_meses[f.month - 1]} ${f.year}';

  /// Ejemplo: 14 sep, 9:00 a. m.
  static String fechaHora(DateTime f) {
    final h = f.hour % 12 == 0 ? 12 : f.hour % 12;
    final m = f.minute.toString().padLeft(2, '0');
    final sufijo = f.hour < 12 ? 'a. m.' : 'p. m.';
    return '${f.day} ${_meses[f.month - 1]}, $h:$m $sufijo';
  }

  /// Ejemplo: 14 sep al 16 sep  (o solo "14 sep" si es el mismo día)
  static String rango(DateTime ini, DateTime fin) {
    final a = '${ini.day} ${_meses[ini.month - 1]}';
    final b = '${fin.day} ${_meses[fin.month - 1]}';
    return a == b ? a : '$a al $b';
  }

  /// Dinero con puntos de miles. Ejemplo: $30.000. Si es 0 devuelve "Gratis".
  static String dinero(double valor, {bool gratisSiCero = false}) {
    if (valor == 0 && gratisSiCero) return 'Gratis';
    final entero = valor.round().toString();
    final conPuntos = entero.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '\$$conPuntos';
  }
}
