// Enumeraciones del dominio de BorrowApp.
// Cada una corresponde a una "Lista" del modelo de datos del SRS (sección 4.2).
// Todas tienen una etiqueta legible ("etiqueta") para mostrar en pantalla.

/// Tipo de organización. Decide cómo se llama el identificador interno.
enum TipoOrganizacion {
  universidad('Universidad', 'Código estudiantil'),
  empresa('Empresa', 'Código de empleado'),
  conjuntoResidencial('Conjunto residencial', 'Número de apartamento');

  const TipoOrganizacion(this.etiqueta, this.nombreIdentificador);
  final String etiqueta;

  /// Cómo se llama el "identificador interno" para este tipo (SRS 1.3).
  final String nombreIdentificador;
}

/// Rol de la membresía: solo quien creó la organización es administrador.
enum RolMembresia {
  administrador('Administrador'),
  miembro('Miembro');

  const RolMembresia(this.etiqueta);
  final String etiqueta;
}

/// Estado del usuario dentro de UNA organización (SRS 3.3.3).
enum EstadoMembresia {
  activo('Activo'),
  advertido('Advertido'),
  suspendido('Suspendido'),
  baneado('Baneado');

  const EstadoMembresia(this.etiqueta);
  final String etiqueta;
}

/// Estados de una necesidad (SRS 3.3.1).
enum EstadoNecesidad {
  buscandoPrestador('Buscando prestador'),
  conPrestamoConfirmado('Con préstamo confirmado'),
  cerrada('Cerrada');

  const EstadoNecesidad(this.etiqueta);
  final String etiqueta;
}

/// Modalidad de una oferta o préstamo.
enum Modalidad {
  gratis('Gratis'),
  alquiler('Alquiler');

  const Modalidad(this.etiqueta);
  final String etiqueta;
}

/// Unidad de cobro cuando la modalidad es alquiler.
enum UnidadCobro {
  hora('Por hora'),
  dia('Por día');

  const UnidadCobro(this.etiqueta);
  final String etiqueta;
}

/// Estados de una oferta (SRS 3.3.1).
enum EstadoOferta {
  pendiente('Pendiente'),
  aceptada('Aceptada'),
  rechazada('Rechazada'),
  cerrada('Cerrada');

  const EstadoOferta(this.etiqueta);
  final String etiqueta;
}

/// Estados del préstamo, en orden (SRS 3.3.2).
/// "En conflicto" NO está aquí a propósito: es una marca aparte (enConflicto).
enum EstadoPrestamo {
  confirmado('Confirmado'),
  entregaPendiente('Entrega pendiente'),
  activo('Activo'),
  devolucionPendiente('Devolución pendiente'),
  finalizado('Finalizado');

  const EstadoPrestamo(this.etiqueta);
  final String etiqueta;
}

/// Tipos de problema que se pueden reportar (RF-014).
enum TipoReporte {
  noDevuelto('El objeto no fue devuelto'),
  danado('El objeto está dañado'),
  noAsistio('La otra persona no asistió');

  const TipoReporte(this.etiqueta);
  final String etiqueta;
}

/// Estado de un reporte.
enum EstadoReporte {
  pendiente('Pendiente'),
  resuelto('Resuelto');

  const EstadoReporte(this.etiqueta);
  final String etiqueta;
}

/// Sanciones que puede aplicar el administrador (RF-017).
enum Sancion {
  advertencia('Advertencia'),
  suspension('Suspensión temporal'),
  baneo('Baneo permanente');

  const Sancion(this.etiqueta);
  final String etiqueta;
}
