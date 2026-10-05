import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utilidades de seguridad para contraseñas (RNF-002).
///
/// En el servidor real se usará bcrypt. Mientras no hay backend usamos SHA-256
/// para que la contraseña NUNCA se guarde en texto plano.
class HashUtil {
  /// Convierte una contraseña en su hash.
  static String hashContrasena(String contrasena) =>
      sha256.convert(utf8.encode(contrasena)).toString();
}
