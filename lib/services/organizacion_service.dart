import 'dart:math';
import '../data/borrow_repository.dart';
import '../models/enums.dart';
import '../models/usuario.dart';
import '../utils/regla_negocio_exception.dart';
import '../utils/validadores.dart';

/// Lógica de organizaciones y membresías (RF-003, RF-004, RF-016, RF-018, RF-019).
class OrganizacionService {
  OrganizacionService(this._repo);
  final BorrowRepository _repo;

  static const _alfabeto = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Genera un código de 5 caracteres (mayúsculas y números) que no exista aún.
  Future<String> _generarCodigoUnico() async {
    final azar = Random.secure();
    while (true) {
      final codigo = List.generate(
          5, (_) => _alfabeto[azar.nextInt(_alfabeto.length)]).join();
      if (await _repo.organizacionPorCodigo(codigo) == null) return codigo;
    }
  }

  /// RF-003: crea la organización, genera su código y deja al creador como
  /// administrador mediante una nueva membresía.
  Future<Organizacion> crear({
    required int usuarioId,
    required String nombre,
    required TipoOrganizacion tipo,
    required String puntoCentral,
    required String identificadorInterno,
  }) async {
    final error = Validadores.requerido(nombre, campo: 'El nombre', min: 3) ??
        Validadores.requerido(puntoCentral,
            campo: 'El punto de entrega y devolución', min: 3) ??
        Validadores.requerido(identificadorInterno,
            campo: tipo.nombreIdentificador);
    if (error != null) throw ReglaNegocioException(error);

    final org = Organizacion(
      id: _repo.siguienteId(),
      nombre: nombre.trim(),
      tipo: tipo,
      codigo: await _generarCodigoUnico(),
      puntoCentral: puntoCentral.trim(),
      creadaPor: usuarioId,
    );
    await _repo.guardarOrganizacion(org);
    await _repo.guardarMembresia(Membresia(
      id: _repo.siguienteId(),
      usuarioId: usuarioId,
      organizacionId: org.id,
      rol: RolMembresia.administrador,
      estado: EstadoMembresia.activo,
      identificadorInterno: identificadorInterno.trim(),
    ));
    return org;
  }

  /// RF-004 (paso 1): busca la organización por su código de 5 caracteres.
  Future<Organizacion> buscarPorCodigo(String codigo) async {
    final error = Validadores.codigoAcceso(codigo);
    if (error != null) throw ReglaNegocioException(error);
    final org = await _repo.organizacionPorCodigo(codigo.trim());
    if (org == null) {
      throw const ReglaNegocioException(
          'Este código no corresponde a ninguna organización. Revisa que tenga 5 caracteres.');
    }
    return org;
  }

  /// RF-004 (paso 2): crea la membresía como Miembro con el identificador interno.
  Future<Membresia> unirse({
    required int usuarioId,
    required Organizacion organizacion,
    required String identificadorInterno,
  }) async {
    final error = Validadores.requerido(identificadorInterno,
        campo: organizacion.tipo.nombreIdentificador);
    if (error != null) throw ReglaNegocioException(error);

    // Regla de integridad: no puede haber dos membresías en la misma organización.
    if (await _repo.membresia(usuarioId, organizacion.id) != null) {
      throw const ReglaNegocioException('Ya perteneces a esta organización.');
    }
    final m = Membresia(
      id: _repo.siguienteId(),
      usuarioId: usuarioId,
      organizacionId: organizacion.id,
      rol: RolMembresia.miembro,
      estado: EstadoMembresia.activo,
      identificadorInterno: identificadorInterno.trim(),
    );
    await _repo.guardarMembresia(m);
    return m;
  }

  Future<Organizacion?> porId(int id) => _repo.organizacionPorId(id);

  /// Membresías del usuario. Aprovecha para levantar suspensiones vencidas.
  Future<List<Membresia>> membresiasDe(int usuarioId) async {
    final lista = await _repo.membresiasDeUsuario(usuarioId);
    return [for (final m in lista) await _restituirSiVencio(m)];
  }

  Future<Membresia?> membresia(int usuarioId, int organizacionId) async {
    final m = await _repo.membresia(usuarioId, organizacionId);
    return m == null ? null : _restituirSiVencio(m);
  }

  /// RF-018: al vencer una suspensión temporal, la membresía vuelve a ACTIVO
  /// sola, sin que el administrador intervenga.
  Future<Membresia> _restituirSiVencio(Membresia m) async {
    final hasta = m.sancionHasta;
    if (m.estado == EstadoMembresia.suspendido &&
        hasta != null &&
        DateTime.now().isAfter(hasta)) {
      final activa = m.copyWith(
          estado: EstadoMembresia.activo, limpiarSancionHasta: true);
      await _repo.guardarMembresia(activa);
      return activa;
    }
    return m;
  }

  /// Miembros de la organización con su usuario (para el panel del admin).
  Future<List<({Usuario usuario, Membresia membresia})>> miembros(
      int organizacionId) async {
    final lista = await _repo.membresiasDeOrganizacion(organizacionId);
    final salida = <({Usuario usuario, Membresia membresia})>[];
    for (final m in lista) {
      final u = await _repo.usuarioPorId(m.usuarioId);
      if (u != null) {
        salida.add((usuario: u, membresia: await _restituirSiVencio(m)));
      }
    }
    return salida;
  }

  /// RF-016: solo el administrador de la organización cambia el punto central.
  /// Los préstamos ya creados conservan el punto con el que nacieron.
  Future<Organizacion> cambiarPuntoCentral({
    required int adminId,
    required int organizacionId,
    required String nuevoPunto,
  }) async {
    await exigirAdmin(adminId, organizacionId);
    final error =
        Validadores.requerido(nuevoPunto, campo: 'El punto central', min: 3);
    if (error != null) throw ReglaNegocioException(error);
    final org = (await _repo.organizacionPorId(organizacionId))!;
    final nueva = org.copyWith(puntoCentral: nuevoPunto.trim());
    await _repo.guardarOrganizacion(nueva);
    return nueva;
  }

  /// Verifica que el usuario sea administrador DE ESA organización.
  Future<Membresia> exigirAdmin(int usuarioId, int organizacionId) async {
    final m = await membresia(usuarioId, organizacionId);
    if (m == null || !m.esAdministrador) {
      throw const ReglaNegocioException(
          'Solo el administrador de esta organización puede hacer esto.');
    }
    return m;
  }
}
