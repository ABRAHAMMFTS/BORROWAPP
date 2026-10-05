import '../models/operaciones.dart';
import '../models/usuario.dart';

/// Contrato de la capa de datos.
///
/// Los servicios (capa de lógica) SOLO hablan con esta interfaz. Hoy la
/// implementa [MemoryRepository] (datos en memoria); cuando esté listo el
/// backend, se crea un `ApiRepository` que use la API REST + PostgreSQL y se
/// cambia en un solo lugar (main.dart) sin tocar servicios ni pantallas.
abstract class BorrowRepository {
  /// Entrega un id nuevo y único para cualquier entidad.
  int siguienteId();

  // ---- Usuarios ----
  Future<Usuario?> usuarioPorId(int id);
  Future<Usuario?> usuarioPorCorreo(String correo);
  Future<void> guardarUsuario(Usuario usuario);

  // ---- Organizaciones ----
  Future<Organizacion?> organizacionPorId(int id);
  Future<Organizacion?> organizacionPorCodigo(String codigo);
  Future<void> guardarOrganizacion(Organizacion organizacion);

  // ---- Membresías ----
  Future<List<Membresia>> membresiasDeUsuario(int usuarioId);
  Future<List<Membresia>> membresiasDeOrganizacion(int organizacionId);
  Future<Membresia?> membresia(int usuarioId, int organizacionId);
  Future<void> guardarMembresia(Membresia membresia);

  // ---- Necesidades ----
  Future<List<Necesidad>> necesidadesDeOrganizacion(int organizacionId);
  Future<Necesidad?> necesidadPorId(int id);
  Future<void> guardarNecesidad(Necesidad necesidad);

  // ---- Ofertas ----
  Future<List<Oferta>> ofertasDeNecesidad(int necesidadId);
  Future<List<Oferta>> ofertasDePrestador(int prestadorId);
  Future<Oferta?> ofertaPorId(int id);
  Future<void> guardarOferta(Oferta oferta);

  // ---- Préstamos ----
  Future<List<Prestamo>> prestamosDeOrganizacion(int organizacionId);
  Future<Prestamo?> prestamoPorId(int id);
  Future<void> guardarPrestamo(Prestamo prestamo);

  // ---- Reportes ----
  Future<List<Reporte>> reportesDeOrganizacion(int organizacionId);
  Future<Reporte?> reportePorId(int id);
  Future<void> guardarReporte(Reporte reporte);

  /// Vuelve a los datos de ejemplo. Útil para pruebas y demostraciones.
  Future<void> reiniciar();
}
