import 'enums.dart';

// Modelos de las operaciones: Necesidad, Oferta, Préstamo y Reporte (SRS 4.2).

/// Lo que un usuario pide dentro de una organización.
class Necesidad {
  final int id;
  final int organizacionId;
  final int solicitanteId;
  final String objeto;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final EstadoNecesidad estado;

  const Necesidad({
    required this.id,
    required this.organizacionId,
    required this.solicitanteId,
    required this.objeto,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
  });

  /// Días que dura la necesidad (mínimo 1). Se usa para calcular el precio.
  int get dias {
    final d = fechaFin.difference(fechaInicio).inDays + 1;
    return d < 1 ? 1 : d;
  }

  Necesidad copyWith({EstadoNecesidad? estado}) => Necesidad(
        id: id,
        organizacionId: organizacionId,
        solicitanteId: solicitanteId,
        objeto: objeto,
        descripcion: descripcion,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estado: estado ?? this.estado,
      );
}

/// Respuesta de un miembro a una necesidad. Las condiciones las define el prestador.
class Oferta {
  final int id;
  final int necesidadId;
  final int prestadorId;
  final Modalidad modalidad;
  final double? precio;
  final UnidadCobro? unidadCobro;
  final DateTime fechaEntrega;
  final EstadoOferta estado;

  const Oferta({
    required this.id,
    required this.necesidadId,
    required this.prestadorId,
    required this.modalidad,
    this.precio,
    this.unidadCobro,
    required this.fechaEntrega,
    required this.estado,
  });

  Oferta copyWith({EstadoOferta? estado}) => Oferta(
        id: id,
        necesidadId: necesidadId,
        prestadorId: prestadorId,
        modalidad: modalidad,
        precio: precio,
        unidadCobro: unidadCobro,
        fechaEntrega: fechaEntrega,
        estado: estado ?? this.estado,
      );
}

/// Acuerdo que nace al aceptar una oferta. Guarda una copia de las condiciones.
class Prestamo {
  final int id;
  final int ofertaId;
  final int necesidadId;
  final int organizacionId;
  final int solicitanteId;
  final int prestadorId;
  final String objeto;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final Modalidad modalidad;
  final double precioTotal;

  /// Se copia de la organización al crear el préstamo y ya no cambia.
  final String puntoCentral;
  final EstadoPrestamo estado;

  /// Marca superpuesta mientras haya un reporte pendiente (no cambia el estado real).
  final bool enConflicto;

  // Confirmaciones cruzadas. null significa "pendiente".
  final DateTime? entregaPrestadorEn;
  final DateTime? entregaSolicitanteEn;
  final DateTime? devolucionSolicitanteEn;
  final DateTime? devolucionPrestadorEn;

  const Prestamo({
    required this.id,
    required this.ofertaId,
    required this.necesidadId,
    required this.organizacionId,
    required this.solicitanteId,
    required this.prestadorId,
    required this.objeto,
    required this.fechaInicio,
    required this.fechaFin,
    required this.modalidad,
    required this.precioTotal,
    required this.puntoCentral,
    required this.estado,
    this.enConflicto = false,
    this.entregaPrestadorEn,
    this.entregaSolicitanteEn,
    this.devolucionSolicitanteEn,
    this.devolucionPrestadorEn,
  });

  /// Etiqueta "Vencido" (Apéndice E.2): el préstamo sigue Activo pero ya pasó
  /// su fecha de fin. No es un estado nuevo, solo una etiqueta visual.
  bool get vencido =>
      estado == EstadoPrestamo.activo && DateTime.now().isAfter(fechaFin);

  Prestamo copyWith({
    EstadoPrestamo? estado,
    bool? enConflicto,
    DateTime? entregaPrestadorEn,
    DateTime? entregaSolicitanteEn,
    DateTime? devolucionSolicitanteEn,
    DateTime? devolucionPrestadorEn,
  }) =>
      Prestamo(
        id: id,
        ofertaId: ofertaId,
        necesidadId: necesidadId,
        organizacionId: organizacionId,
        solicitanteId: solicitanteId,
        prestadorId: prestadorId,
        objeto: objeto,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        modalidad: modalidad,
        precioTotal: precioTotal,
        puntoCentral: puntoCentral,
        estado: estado ?? this.estado,
        enConflicto: enConflicto ?? this.enConflicto,
        entregaPrestadorEn: entregaPrestadorEn ?? this.entregaPrestadorEn,
        entregaSolicitanteEn: entregaSolicitanteEn ?? this.entregaSolicitanteEn,
        devolucionSolicitanteEn:
            devolucionSolicitanteEn ?? this.devolucionSolicitanteEn,
        devolucionPrestadorEn:
            devolucionPrestadorEn ?? this.devolucionPrestadorEn,
      );
}

/// Un problema con un préstamo y lo que decidió el administrador.
class Reporte {
  final int id;
  final int prestamoId;
  final int organizacionId;
  final int reportanteId;
  final int reportadoId;
  final TipoReporte tipo;
  final String descripcion;
  final EstadoReporte estado;
  final DateTime creadoEn;

  // Se llenan solo al resolver (regla de integridad 4.3).
  final Sancion? sancion;
  final String? notaResolucion;
  final int? adminId;
  final DateTime? resueltoEn;

  const Reporte({
    required this.id,
    required this.prestamoId,
    required this.organizacionId,
    required this.reportanteId,
    required this.reportadoId,
    required this.tipo,
    required this.descripcion,
    required this.estado,
    required this.creadoEn,
    this.sancion,
    this.notaResolucion,
    this.adminId,
    this.resueltoEn,
  });

  Reporte resolver({
    required Sancion sancion,
    required String nota,
    required int adminId,
  }) =>
      Reporte(
        id: id,
        prestamoId: prestamoId,
        organizacionId: organizacionId,
        reportanteId: reportanteId,
        reportadoId: reportadoId,
        tipo: tipo,
        descripcion: descripcion,
        estado: EstadoReporte.resuelto,
        creadoEn: creadoEn,
        sancion: sancion,
        notaResolucion: nota,
        adminId: adminId,
        resueltoEn: DateTime.now(),
      );
}
