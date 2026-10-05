/// Validaciones de formularios. Cada función devuelve `null` si el dato es
/// válido, o el mensaje de error si no lo es (formato que pide Flutter para
/// `TextFormField.validator`). Los mensajes dicen qué pasó y cómo arreglarlo.
class Validadores {
  /// Texto obligatorio con largo mínimo.
  static String? requerido(String? v, {String campo = 'Este campo', int min = 1}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return '$campo es obligatorio.';
    if (t.length < min) return '$campo debe tener al menos $min caracteres.';
    return null;
  }

  /// RF-001: nombre completo.
  static String? nombre(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Escribe tu nombre completo.';
    if (t.split(RegExp(r'\s+')).length < 2) {
      return 'Escribe tu nombre y apellido.';
    }
    return null;
  }

  /// RF-001: correo con formato válido.
  static String? correo(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Escribe tu correo.';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
    if (!ok) return 'Revisa el formato del correo, por ejemplo nombre@correo.com.';
    return null;
  }

  /// RF-001: contraseña de mínimo 8 caracteres.
  static String? contrasena(String? v) {
    final t = v ?? '';
    if (t.isEmpty) return 'Escribe una contraseña.';
    if (t.length < 8) return 'La contraseña debe tener mínimo 8 caracteres.';
    return null;
  }

  /// Código de acceso: exactamente 5 caracteres alfanuméricos.
  static String? codigoAcceso(String? v) {
    final t = (v ?? '').trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{5}$').hasMatch(t)) {
      return 'El código debe tener 5 caracteres entre letras y números.';
    }
    return null;
  }

  /// Precio de un alquiler: número mayor que cero.
  static String? precio(String? v) {
    final n = double.tryParse((v ?? '').replaceAll('.', '').replaceAll(',', '.'));
    if (n == null) return 'Escribe el precio solo con números.';
    if (n <= 0) return 'El precio debe ser mayor que cero.';
    return null;
  }
}
