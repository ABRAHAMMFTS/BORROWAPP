import '../data/borrow_repository.dart';
import '../models/enums.dart';
import '../models/operaciones.dart';
import '../models/usuario.dart';
import '../utils/regla_negocio_exception.dart';
import '../utils/validadores.dart';
import 'organizacion_service.dart';

/// Lógica de necesidades y ofertas (RF-005 a RF-011, RF-018, RF-020).
class NecesidadService {
  NecesidadService(this._repo, this._orgs);
  final BorrowRepository _repo;
  final OrganizacionService _orgs;

  /// RF-005 y RF-018: el usuario debe ser miembro de la organización y no estar
  /// suspendido ni baneado. Devuelve su membresía si todo está bien.
  Future<Membresia> _exigirPuedeActuar(int usuarioId, int organizacionId) async {
    final m = await _orgs.membresia(usuarioId, organizacionId);
    if (m == null) {
      throw const ReglaNegocioException(
          'No perteneces a esta organización, así que no puedes hacer esto.');
    }
    if (m.estaBloqueado) {
      final hasta = m.sancionHasta;
      final motivo = m.estado == EstadoMembresia.baneado
          ? 'Fuiste baneado de esta organización.'
          : 'Estás suspendido en esta organización${hasta != null ? ' hasta que termine tu suspensión' : ''}.';
      throw ReglaNegocioException(
          '$motivo No puedes publicar, ofrecer ni aceptar mientras tanto. '
          'Tus otras organizaciones no se ven afectadas.');
    }
    return m;
  }

  /// Consulta si el usuario puede actuar (para bloquear botones en pantalla).
  Future<bool> puedeActuar(int usuarioId, int organizacionId) async {
    final m = await _orgs.membresia(usuarioId, organizacionId);
    return m != null && !m.estaBloqueado;
  }

  // ---------------- Necesidades ----------------

  /// RF-007: necesidades de la organización activa, las más recientes primero.
  Future<List<Necesidad>> listar(int organizacionId) async {
    final lista = await _repo.necesidadesDeOrganizacion(organizacionId);
    lista.sort((a, b) => b.id.compareTo(a.id));
    return lista;
  }

  Future<Necesidad?> detalle(int id) => _repo.necesidadPorId(id);

  /// RF-006: publica una necesidad con estado BUSCANDO_PRESTADOR.
  Future<Necesidad> publicar({
    required int solicitanteId,
    required int organizacionId,
    required String objeto,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    await _exigirPuedeActuar(solicitanteId, organizacionId);

    final error = Validadores.requerido(objeto, campo: 'El objeto', min: 3) ??
        Validadores.requerido(descripcion, campo: 'La descripción', min: 5);
    if (error != null) throw ReglaNegocioException(error);

    final hoy = DateTime.now();
    final inicioDia = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    if (inicioDia.isBefore(DateTime(hoy.year, hoy.month, hoy.day))) {
      throw const ReglaNegocioException(
          'La fecha de inicio no puede ser anterior a hoy.');
    }
    if (fechaFin.isBefore(fechaInicio)) {
      throw const ReglaNegocioException(
          'La fecha de fin debe ser igual o posterior a la de inicio.');
    }

    final n = Necesidad(
      id: _repo.siguienteId(),
      organizacionId: organizacionId,
      solicitanteId: solicitanteId,
      objeto: objeto.trim(),
      descripcion: descripcion.trim(),
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estado: EstadoNecesidad.buscandoPrestador,
    );
    await _repo.guardarNecesidad(n);
    return n;
  }

  /// RF-020: cancela la necesidad si sigue buscando prestador. Las ofertas
  /// pendientes pasan a CERRADA.
  Future<void> cancelar({required int usuarioId, required int necesidadId}) async {
    final n = await _necesidadOError(necesidadId);
    if (n.solicitanteId != usuarioId) {
      throw const ReglaNegocioException(
          'Solo quien publicó la necesidad puede cancelarla.');
    }
    if (n.estado != EstadoNecesidad.buscandoPrestador) {
      throw const ReglaNegocioException(
          'Esta necesidad ya tiene un préstamo confirmado y no se puede cancelar.');
    }
    await _cerrarOfertasPendientes(necesidadId);
    await _repo.guardarNecesidad(n.copyWith(estado: EstadoNecesidad.cerrada));
  }

  // ---------------- Ofertas ----------------

  Future<List<Oferta>> ofertasDe(int necesidadId) async {
    final lista = await _repo.ofertasDeNecesidad(necesidadId);
    lista.sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));
    return lista;
  }

  /// La oferta pendiente de este usuario en esta necesidad (si ya ofreció).
  Future<Oferta?> ofertaPendienteDe(int necesidadId, int prestadorId) async {
    final lista = await _repo.ofertasDeNecesidad(necesidadId);
    return lista
        .where((o) =>
            o.prestadorId == prestadorId && o.estado == EstadoOferta.pendiente)
        .firstOrNull;
  }

  /// RF-009: total = precio × duración. Si es gratis, el total es $0.
  /// La duración sale del periodo de la necesidad (días, o 24 h por día).
  double calcularTotal({
    required Necesidad necesidad,
    required Modalidad modalidad,
    double? precio,
    UnidadCobro? unidad,
  }) {
    if (modalidad == Modalidad.gratis || precio == null || unidad == null) {
      return 0;
    }
    final duracion =
        unidad == UnidadCobro.dia ? necesidad.dias : necesidad.dias * 24;
    return precio * duracion;
  }

  /// RF-008: "Tengo este objeto". El prestador define las condiciones y la
  /// oferta nace PENDIENTE.
  Future<Oferta> crearOferta({
    required int prestadorId,
    required int necesidadId,
    required Modalidad modalidad,
    double? precio,
    UnidadCobro? unidad,
    required DateTime fechaEntrega,
  }) async {
    final n = await _necesidadOError(necesidadId);
    await _exigirPuedeActuar(prestadorId, n.organizacionId);

    // Regla de integridad: el prestador no puede ser el solicitante.
    if (n.solicitanteId == prestadorId) {
      throw const ReglaNegocioException(
          'No puedes ofrecer un objeto para tu propia necesidad.');
    }
    if (n.estado != EstadoNecesidad.buscandoPrestador) {
      throw const ReglaNegocioException(
          'Esta necesidad ya no está buscando prestador.');
    }
    if (await ofertaPendienteDe(necesidadId, prestadorId) != null) {
      throw const ReglaNegocioException(
          'Ya enviaste una oferta para esta necesidad. Espera la respuesta del solicitante.');
    }
    if (modalidad == Modalidad.alquiler) {
      if (precio == null || precio <= 0) {
        throw const ReglaNegocioException(
            'Para un alquiler escribe un precio mayor que cero.');
      }
      if (unidad == null) {
        throw const ReglaNegocioException(
            'Elige si cobras por hora o por día.');
      }
    }
    if (fechaEntrega.isBefore(DateTime.now())) {
      throw const ReglaNegocioException(
          'La fecha y hora de entrega no puede estar en el pasado.');
    }

    final o = Oferta(
      id: _repo.siguienteId(),
      necesidadId: necesidadId,
      prestadorId: prestadorId,
      modalidad: modalidad,
      precio: modalidad == Modalidad.alquiler ? precio : null,
      unidadCobro: modalidad == Modalidad.alquiler ? unidad : null,
      fechaEntrega: fechaEntrega,
      estado: EstadoOferta.pendiente,
    );
    await _repo.guardarOferta(o);
    return o;
  }

  /// RF-010: rechaza una oferta. La necesidad y las demás ofertas siguen abiertas.
  Future<void> rechazarOferta({
    required int solicitanteId,
    required int ofertaId,
  }) async {
    final o = await _ofertaOError(ofertaId);
    final n = await _necesidadOError(o.necesidadId);
    _exigirSolicitante(n, solicitanteId);
    if (o.estado != EstadoOferta.pendiente) {
      throw const ReglaNegocioException('Esta oferta ya no está pendiente.');
    }
    await _repo.guardarOferta(o.copyWith(estado: EstadoOferta.rechazada));
  }

  /// RF-010, RF-011 y RNF-007: acepta una oferta. En UNA sola operación:
  ///  1) la oferta pasa a ACEPTADA,
  ///  2) las demás pendientes pasan a CERRADA,
  ///  3) la necesidad pasa a CON_PRESTAMO_CONFIRMADO,
  ///  4) se crea el préstamo en estado CONFIRMADO.
  /// Primero se validan todas las condiciones y solo después se guarda, para
  /// que "o pasa todo o no pasa nada". En el backend real esto irá dentro de
  /// una transacción de PostgreSQL.
  Future<Prestamo> aceptarOferta({
    required int solicitanteId,
    required int ofertaId,
  }) async {
    final o = await _ofertaOError(ofertaId);
    final n = await _necesidadOError(o.necesidadId);
    _exigirSolicitante(n, solicitanteId);
    await _exigirPuedeActuar(solicitanteId, n.organizacionId);

    if (o.estado != EstadoOferta.pendiente) {
      throw const ReglaNegocioException('Esta oferta ya no está pendiente.');
    }
    if (n.estado != EstadoNecesidad.buscandoPrestador) {
      throw const ReglaNegocioException(
          'Esta necesidad ya tiene un préstamo confirmado.');
    }
    final org = (await _orgs.porId(n.organizacionId))!;

    // --- Todo validado: ahora sí se guardan los cambios juntos ---
    final prestamo = Prestamo(
      id: _repo.siguienteId(),
      ofertaId: o.id,
      necesidadId: n.id,
      organizacionId: n.organizacionId,
      solicitanteId: n.solicitanteId,
      prestadorId: o.prestadorId,
      objeto: n.objeto,
      fechaInicio: n.fechaInicio,
      fechaFin: n.fechaFin,
      modalidad: o.modalidad,
      precioTotal: calcularTotal(
          necesidad: n,
          modalidad: o.modalidad,
          precio: o.precio,
          unidad: o.unidadCobro),
      puntoCentral: org.puntoCentral, // copia que no cambia después
      estado: EstadoPrestamo.confirmado,
    );

    await _cerrarOfertasPendientes(n.id, exceptoId: o.id);
    await _repo.guardarOferta(o.copyWith(estado: EstadoOferta.aceptada));
    await _repo.guardarNecesidad(
        n.copyWith(estado: EstadoNecesidad.conPrestamoConfirmado));
    await _repo.guardarPrestamo(prestamo);
    return prestamo;
  }

  /// Cuántas otras ofertas se cerrarán al aceptar una (para el aviso de P13).
  Future<int> otrasPendientes(int necesidadId, int ofertaId) async {
    final lista = await _repo.ofertasDeNecesidad(necesidadId);
    return lista
        .where((x) => x.id != ofertaId && x.estado == EstadoOferta.pendiente)
        .length;
  }

  // ---------------- Auxiliares privados ----------------

  void _exigirSolicitante(Necesidad n, int usuarioId) {
    if (n.solicitanteId != usuarioId) {
      throw const ReglaNegocioException(
          'Solo quien publicó la necesidad puede decidir sobre sus ofertas.');
    }
  }

  Future<void> _cerrarOfertasPendientes(int necesidadId, {int? exceptoId}) async {
    for (final x in await _repo.ofertasDeNecesidad(necesidadId)) {
      if (x.id != exceptoId && x.estado == EstadoOferta.pendiente) {
        await _repo.guardarOferta(x.copyWith(estado: EstadoOferta.cerrada));
      }
    }
  }

  Future<Necesidad> _necesidadOError(int id) async {
    final n = await _repo.necesidadPorId(id);
    if (n == null) throw const ReglaNegocioException('Esa necesidad ya no existe.');
    return n;
  }

  Future<Oferta> _ofertaOError(int id) async {
    final o = await _repo.ofertaPorId(id);
    if (o == null) throw const ReglaNegocioException('Esa oferta ya no existe.');
    return o;
  }

  /// Nombre del usuario por su id (para mostrar en listas).
  Future<Usuario?> usuario(int id) => _repo.usuarioPorId(id);
}
