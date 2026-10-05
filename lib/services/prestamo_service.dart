import '../data/borrow_repository.dart';
import '../models/enums.dart';
import '../models/operaciones.dart';
import '../utils/regla_negocio_exception.dart';
import '../utils/validadores.dart';
import 'organizacion_service.dart';

/// Lógica de préstamos, reportes y sanciones (RF-012 a RF-018).
class PrestamoService {
  PrestamoService(this._repo, this._orgs);
  final BorrowRepository _repo;
  final OrganizacionService _orgs;

  // ---------------- Consultas ----------------

  Future<List<Prestamo>> deOrganizacion(int organizacionId) async {
    final lista = await _repo.prestamosDeOrganizacion(organizacionId);
    lista.sort((a, b) => b.id.compareTo(a.id));
    return lista;
  }

  /// "Mis préstamos": donde el usuario es solicitante o prestador.
  Future<List<Prestamo>> deUsuario(int usuarioId, int organizacionId) async {
    final lista = await deOrganizacion(organizacionId);
    return lista
        .where((p) => p.solicitanteId == usuarioId || p.prestadorId == usuarioId)
        .toList();
  }

  Future<Prestamo?> detalle(int id) => _repo.prestamoPorId(id);

  /// Texto de la franja amarilla "Te toca…" si el usuario debe confirmar algo.
  /// Devuelve null si no le toca a él.
  String? accionPendiente(Prestamo p, int usuarioId) {
    final esPrestador = p.prestadorId == usuarioId;
    final esSolicitante = p.solicitanteId == usuarioId;
    switch (p.estado) {
      case EstadoPrestamo.confirmado:
        return esPrestador ? 'Te toca marcar la entrega' : null;
      case EstadoPrestamo.entregaPendiente:
        return esSolicitante ? 'Te toca confirmar la recepción' : null;
      case EstadoPrestamo.activo:
        return esSolicitante ? 'Te toca marcar la devolución' : null;
      case EstadoPrestamo.devolucionPendiente:
        return esPrestador ? 'Te toca confirmar la devolución' : null;
      case EstadoPrestamo.finalizado:
        return null;
    }
  }

  // ---------------- Confirmaciones cruzadas ----------------
  // Cada paso lo da una persona distinta a la del paso anterior (SRS 3.3.2).
  // Las sanciones NO bloquean estos pasos: los préstamos en curso siguen su
  // flujo normal (RF-018).

  /// RF-012: el prestador marca "Entregado". Pasa a ENTREGA_PENDIENTE.
  Future<Prestamo> marcarEntregado(int prestamoId, int usuarioId) async {
    final p = await _prestamoOError(prestamoId);
    _exigirParte(p.prestadorId, usuarioId, 'el prestador');
    _exigirEstado(p, EstadoPrestamo.confirmado,
        'La entrega ya fue marcada o el préstamo no está confirmado.');
    return _guardar(p.copyWith(
      estado: EstadoPrestamo.entregaPendiente,
      entregaPrestadorEn: DateTime.now(),
    ));
  }

  /// RF-012: el solicitante confirma "Recibido". Solo con las dos
  /// confirmaciones el préstamo pasa a ACTIVO.
  Future<Prestamo> confirmarRecibido(int prestamoId, int usuarioId) async {
    final p = await _prestamoOError(prestamoId);
    _exigirParte(p.solicitanteId, usuarioId, 'el solicitante');
    _exigirEstado(p, EstadoPrestamo.entregaPendiente,
        'Primero el prestador debe marcar la entrega.');
    if (p.entregaPrestadorEn == null) {
      throw const ReglaNegocioException(
          'Falta la confirmación del prestador.');
    }
    return _guardar(p.copyWith(
      estado: EstadoPrestamo.activo,
      entregaSolicitanteEn: DateTime.now(),
    ));
  }

  /// RF-013: el solicitante marca "Devuelto". Pasa a DEVOLUCION_PENDIENTE.
  Future<Prestamo> marcarDevuelto(int prestamoId, int usuarioId) async {
    final p = await _prestamoOError(prestamoId);
    _exigirParte(p.solicitanteId, usuarioId, 'el solicitante');
    _exigirEstado(p, EstadoPrestamo.activo,
        'El préstamo debe estar activo para marcar la devolución.');
    return _guardar(p.copyWith(
      estado: EstadoPrestamo.devolucionPendiente,
      devolucionSolicitanteEn: DateTime.now(),
    ));
  }

  /// RF-013: el prestador confirma la devolución. Solo con las dos
  /// confirmaciones el préstamo pasa a FINALIZADO y la necesidad se cierra.
  Future<Prestamo> confirmarDevolucion(int prestamoId, int usuarioId) async {
    final p = await _prestamoOError(prestamoId);
    _exigirParte(p.prestadorId, usuarioId, 'el prestador');
    _exigirEstado(p, EstadoPrestamo.devolucionPendiente,
        'Primero el solicitante debe marcar la devolución.');
    final fin = await _guardar(p.copyWith(
      estado: EstadoPrestamo.finalizado,
      devolucionPrestadorEn: DateTime.now(),
    ));
    final n = await _repo.necesidadPorId(p.necesidadId);
    if (n != null) {
      await _repo.guardarNecesidad(n.copyWith(estado: EstadoNecesidad.cerrada));
    }
    return fin;
  }

  // ---------------- Reportes ----------------

  /// RF-014: cualquiera de las dos partes reporta un problema. El préstamo
  /// queda "En conflicto" (marca visual) sin cambiar su estado real.
  Future<Reporte> reportar({
    required int prestamoId,
    required int reportanteId,
    required TipoReporte tipo,
    required String descripcion,
  }) async {
    final p = await _prestamoOError(prestamoId);
    final esParte =
        p.solicitanteId == reportanteId || p.prestadorId == reportanteId;
    if (!esParte) {
      throw const ReglaNegocioException(
          'Solo las dos partes del préstamo pueden reportar un problema.');
    }
    if (p.estado == EstadoPrestamo.finalizado) {
      throw const ReglaNegocioException(
          'Este préstamo ya finalizó y no se puede reportar.');
    }
    if (p.enConflicto) {
      throw const ReglaNegocioException(
          'Este préstamo ya tiene un reporte pendiente. El administrador lo está revisando.');
    }
    final error =
        Validadores.requerido(descripcion, campo: 'La descripción', min: 10);
    if (error != null) throw ReglaNegocioException(error);

    final reportado =
        p.solicitanteId == reportanteId ? p.prestadorId : p.solicitanteId;
    final r = Reporte(
      id: _repo.siguienteId(),
      prestamoId: p.id,
      organizacionId: p.organizacionId,
      reportanteId: reportanteId,
      reportadoId: reportado,
      tipo: tipo,
      descripcion: descripcion.trim(),
      estado: EstadoReporte.pendiente,
      creadoEn: DateTime.now(),
    );
    await _repo.guardarReporte(r);
    await _guardar(p.copyWith(enConflicto: true));
    return r;
  }

  /// Reportes de la organización (pendientes primero) para el administrador.
  Future<List<Reporte>> reportesDe(int adminId, int organizacionId) async {
    await _orgs.exigirAdmin(adminId, organizacionId);
    final lista = await _repo.reportesDeOrganizacion(organizacionId);
    lista.sort((a, b) {
      if (a.estado != b.estado) {
        return a.estado == EstadoReporte.pendiente ? -1 : 1;
      }
      return b.creadoEn.compareTo(a.creadoEn);
    });
    return lista;
  }

  Future<Reporte?> reporte(int id) => _repo.reportePorId(id);

  /// RF-017: el administrador resuelve un reporte aplicando una sanción.
  /// Actualiza la membresía del reportado SOLO en esta organización, marca el
  /// reporte como RESUELTO y quita la marca "En conflicto" del préstamo.
  Future<Reporte> resolverReporte({
    required int adminId,
    required int reporteId,
    required Sancion sancion,
    required String nota,
    DateTime? suspensionHasta,
  }) async {
    final r = await _repo.reportePorId(reporteId);
    if (r == null) throw const ReglaNegocioException('Ese reporte ya no existe.');
    await _orgs.exigirAdmin(adminId, r.organizacionId);
    if (r.estado == EstadoReporte.resuelto) {
      throw const ReglaNegocioException('Este reporte ya fue resuelto.');
    }
    // Integridad 4.3: un reporte resuelto siempre lleva una nota.
    final error =
        Validadores.requerido(nota, campo: 'La nota de resolución', min: 5);
    if (error != null) throw ReglaNegocioException(error);
    if (sancion == Sancion.suspension &&
        (suspensionHasta == null || suspensionHasta.isBefore(DateTime.now()))) {
      throw const ReglaNegocioException(
          'Elige una fecha de fin de suspensión posterior a hoy.');
    }

    final m = await _orgs.membresia(r.reportadoId, r.organizacionId);
    if (m == null) {
      throw const ReglaNegocioException(
          'La persona reportada ya no pertenece a la organización.');
    }
    final nueva = switch (sancion) {
      Sancion.advertencia => m.copyWith(estado: EstadoMembresia.advertido),
      Sancion.suspension => m.copyWith(
          estado: EstadoMembresia.suspendido, sancionHasta: suspensionHasta),
      Sancion.baneo => m.copyWith(estado: EstadoMembresia.baneado),
    };
    await _repo.guardarMembresia(nueva);

    final resuelto = r.resolver(sancion: sancion, nota: nota.trim(), adminId: adminId);
    await _repo.guardarReporte(resuelto);

    final p = await _repo.prestamoPorId(r.prestamoId);
    if (p != null) await _guardar(p.copyWith(enConflicto: false));
    return resuelto;
  }

  /// RF-017: el administrador revierte una sanción y la membresía vuelve a ACTIVO.
  Future<void> revertirSancion({
    required int adminId,
    required int usuarioId,
    required int organizacionId,
  }) async {
    await _orgs.exigirAdmin(adminId, organizacionId);
    final m = await _orgs.membresia(usuarioId, organizacionId);
    if (m == null) {
      throw const ReglaNegocioException('Ese miembro ya no está en la organización.');
    }
    await _repo.guardarMembresia(
        m.copyWith(estado: EstadoMembresia.activo, limpiarSancionHasta: true));
  }

  // ---------------- Auxiliares privados ----------------

  Future<Prestamo> _guardar(Prestamo p) async {
    await _repo.guardarPrestamo(p);
    return p;
  }

  void _exigirParte(int esperado, int usuarioId, String rol) {
    if (esperado != usuarioId) {
      throw ReglaNegocioException('Este paso solo lo puede dar $rol.');
    }
  }

  void _exigirEstado(Prestamo p, EstadoPrestamo esperado, String mensaje) {
    if (p.estado != esperado) throw ReglaNegocioException(mensaje);
  }

  Future<Prestamo> _prestamoOError(int id) async {
    final p = await _repo.prestamoPorId(id);
    if (p == null) throw const ReglaNegocioException('Ese préstamo ya no existe.');
    return p;
  }
}
