import '../data/borrow_repository.dart';
import '../models/usuario.dart';
import '../utils/hash_util.dart';
import '../utils/regla_negocio_exception.dart';
import '../utils/validadores.dart';

/// Lógica de cuentas de usuario (RF-001 y RF-002).
class AuthService {
  AuthService(this._repo);
  final BorrowRepository _repo;

  /// RF-001: registra un usuario con correo único y contraseña de 8+ caracteres.
  Future<Usuario> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final error = Validadores.nombre(nombre) ??
        Validadores.correo(correo) ??
        Validadores.contrasena(contrasena);
    if (error != null) throw ReglaNegocioException(error);

    // Regla de integridad: el correo es único en todo el sistema.
    if (await _repo.usuarioPorCorreo(correo.trim()) != null) {
      throw const ReglaNegocioException(
          'Ese correo ya tiene una cuenta. Inicia sesión o usa otro correo.');
    }

    final usuario = Usuario(
      id: _repo.siguienteId(),
      nombre: nombre.trim(),
      correo: correo.trim().toLowerCase(),
      contrasenaHash: HashUtil.hashContrasena(contrasena),
    );
    await _repo.guardarUsuario(usuario);
    return usuario;
  }

  /// RF-002: autentica con correo y contraseña.
  Future<Usuario> iniciarSesion(String correo, String contrasena) async {
    final usuario = await _repo.usuarioPorCorreo(correo.trim());
    final ok = usuario != null &&
        usuario.contrasenaHash == HashUtil.hashContrasena(contrasena);
    if (!ok) {
      // Mismo mensaje en ambos casos para no revelar si el correo existe.
      throw const ReglaNegocioException(
          'Correo o contraseña incorrectos. Revisa los datos e inténtalo de nuevo.');
    }
    return usuario;
  }
}
