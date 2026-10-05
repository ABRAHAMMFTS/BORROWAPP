import '../models/enums.dart';
import '../models/operaciones.dart';
import '../models/usuario.dart';
import '../utils/hash_util.dart';
import 'borrow_repository.dart';

/// Implementación en memoria del repositorio.
///
/// Guarda todo en listas mientras la app está abierta. Arranca con los datos de
/// ejemplo del SRS (sección 1.6 y Apéndice B) para poder probar el flujo
/// completo sin servidor. Al recargar la página los datos vuelven al inicio.
class MemoryRepository implements BorrowRepository {
  MemoryRepository() {
    _cargarDatosDeEjemplo();
  }

  int _contador = 100;

  final List<Usuario> _usuarios = [];
  final List<Organizacion> _organizaciones = [];
  final List<Membresia> _membresias = [];
  final List<Necesidad> _necesidades = [];
  final List<Oferta> _ofertas = [];
  final List<Prestamo> _prestamos = [];
  final List<Reporte> _reportes = [];

  @override
  int siguienteId() => ++_contador;

  // Reemplaza el elemento con el mismo id o lo agrega si no existe.
  void _upsert<T>(List<T> lista, T item, int Function(T) idDe) {
    final i = lista.indexWhere((e) => idDe(e) == idDe(item));
    if (i >= 0) {
      lista[i] = item;
    } else {
      lista.add(item);
    }
  }

  // ---------------- Usuarios ----------------
  @override
  Future<Usuario?> usuarioPorId(int id) async =>
      _usuarios.where((u) => u.id == id).firstOrNull;

  @override
  Future<Usuario?> usuarioPorCorreo(String correo) async => _usuarios
      .where((u) => u.correo.toLowerCase() == correo.toLowerCase())
      .firstOrNull;

  @override
  Future<void> guardarUsuario(Usuario usuario) async =>
      _upsert(_usuarios, usuario, (u) => u.id);

  // ---------------- Organizaciones ----------------
  @override
  Future<Organizacion?> organizacionPorId(int id) async =>
      _organizaciones.where((o) => o.id == id).firstOrNull;

  @override
  Future<Organizacion?> organizacionPorCodigo(String codigo) async =>
      _organizaciones
          .where((o) => o.codigo.toUpperCase() == codigo.toUpperCase())
          .firstOrNull;

  @override
  Future<void> guardarOrganizacion(Organizacion organizacion) async =>
      _upsert(_organizaciones, organizacion, (o) => o.id);

  // ---------------- Membresías ----------------
  @override
  Future<List<Membresia>> membresiasDeUsuario(int usuarioId) async =>
      _membresias.where((m) => m.usuarioId == usuarioId).toList();

  @override
  Future<List<Membresia>> membresiasDeOrganizacion(int organizacionId) async =>
      _membresias.where((m) => m.organizacionId == organizacionId).toList();

  @override
  Future<Membresia?> membresia(int usuarioId, int organizacionId) async =>
      _membresias
          .where((m) =>
              m.usuarioId == usuarioId && m.organizacionId == organizacionId)
          .firstOrNull;

  @override
  Future<void> guardarMembresia(Membresia membresia) async =>
      _upsert(_membresias, membresia, (m) => m.id);

  // ---------------- Necesidades ----------------
  @override
  Future<List<Necesidad>> necesidadesDeOrganizacion(int organizacionId) async =>
      _necesidades.where((n) => n.organizacionId == organizacionId).toList();

  @override
  Future<Necesidad?> necesidadPorId(int id) async =>
      _necesidades.where((n) => n.id == id).firstOrNull;

  @override
  Future<void> guardarNecesidad(Necesidad necesidad) async =>
      _upsert(_necesidades, necesidad, (n) => n.id);

  // ---------------- Ofertas ----------------
  @override
  Future<List<Oferta>> ofertasDeNecesidad(int necesidadId) async =>
      _ofertas.where((o) => o.necesidadId == necesidadId).toList();

  @override
  Future<List<Oferta>> ofertasDePrestador(int prestadorId) async =>
      _ofertas.where((o) => o.prestadorId == prestadorId).toList();

  @override
  Future<Oferta?> ofertaPorId(int id) async =>
      _ofertas.where((o) => o.id == id).firstOrNull;

  @override
  Future<void> guardarOferta(Oferta oferta) async =>
      _upsert(_ofertas, oferta, (o) => o.id);

  // ---------------- Préstamos ----------------
  @override
  Future<List<Prestamo>> prestamosDeOrganizacion(int organizacionId) async =>
      _prestamos.where((p) => p.organizacionId == organizacionId).toList();

  @override
  Future<Prestamo?> prestamoPorId(int id) async =>
      _prestamos.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> guardarPrestamo(Prestamo prestamo) async =>
      _upsert(_prestamos, prestamo, (p) => p.id);

  // ---------------- Reportes ----------------
  @override
  Future<List<Reporte>> reportesDeOrganizacion(int organizacionId) async =>
      _reportes.where((r) => r.organizacionId == organizacionId).toList();

  @override
  Future<Reporte?> reportePorId(int id) async =>
      _reportes.where((r) => r.id == id).firstOrNull;

  @override
  Future<void> guardarReporte(Reporte reporte) async =>
      _upsert(_reportes, reporte, (r) => r.id);

  @override
  Future<void> reiniciar() async {
    for (final l in [
      _usuarios, _organizaciones, _membresias, _necesidades,
      _ofertas, _prestamos, _reportes,
    ]) {
      l.clear();
    }
    _contador = 100;
    _cargarDatosDeEjemplo();
  }

  // ---------------- Datos de ejemplo (SRS 1.6 y Apéndice B) ----------------
  void _cargarDatosDeEjemplo() {
    final ahora = DateTime.now();
    DateTime dia(int desdeHoy, [int hora = 9, int min = 0]) =>
        DateTime(ahora.year, ahora.month, ahora.day + desdeHoy, hora, min);

    // Contraseña de todos los usuarios de ejemplo: 12345678
    final pass = HashUtil.hashContrasena('12345678');
    _usuarios.addAll([
      Usuario(id: 1, nombre: 'Jesús Vergara', correo: 'jesus@borrowapp.co', contrasenaHash: pass),
      Usuario(id: 2, nombre: 'Camilo Junco', correo: 'camilo@borrowapp.co', contrasenaHash: pass),
      Usuario(id: 3, nombre: 'Abraham Márquez', correo: 'abraham@borrowapp.co', contrasenaHash: pass),
      Usuario(id: 4, nombre: 'Laura Gómez', correo: 'laura@borrowapp.co', contrasenaHash: pass),
    ]);

    // Organización 1: Jesús es administrador. Organización 2: Laura administra.
    _organizaciones.addAll(const [
      Organizacion(id: 1, nombre: 'Universidad Tecnológica de Bolívar', tipo: TipoOrganizacion.universidad, codigo: 'K7Q4X', puntoCentral: 'Biblioteca Central, mostrador de atención', creadaPor: 1),
      Organizacion(id: 2, nombre: 'Torres del Parque', tipo: TipoOrganizacion.conjuntoResidencial, codigo: 'M2X9P', puntoCentral: 'Portería principal', creadaPor: 4),
    ]);

    _membresias.addAll(const [
      Membresia(id: 1, usuarioId: 1, organizacionId: 1, rol: RolMembresia.administrador, estado: EstadoMembresia.activo, identificadorInterno: 'T00061234'),
      Membresia(id: 2, usuarioId: 2, organizacionId: 1, rol: RolMembresia.miembro, estado: EstadoMembresia.activo, identificadorInterno: 'T00065678'),
      Membresia(id: 3, usuarioId: 3, organizacionId: 1, rol: RolMembresia.miembro, estado: EstadoMembresia.activo, identificadorInterno: 'T00069012'),
      Membresia(id: 4, usuarioId: 4, organizacionId: 1, rol: RolMembresia.miembro, estado: EstadoMembresia.activo, identificadorInterno: 'T00063456'),
      Membresia(id: 5, usuarioId: 1, organizacionId: 2, rol: RolMembresia.miembro, estado: EstadoMembresia.activo, identificadorInterno: 'Apto 502'),
      Membresia(id: 6, usuarioId: 4, organizacionId: 2, rol: RolMembresia.administrador, estado: EstadoMembresia.activo, identificadorInterno: 'Apto 301'),
    ]);

    // Necesidades de la UTB.
    _necesidades.addAll([
      Necesidad(id: 1, organizacionId: 1, solicitanteId: 2, objeto: 'Taladro percutor', descripcion: 'Lo necesito para instalar unos estantes en mi cuarto.', fechaInicio: dia(4), fechaFin: dia(6), estado: EstadoNecesidad.buscandoPrestador),
      Necesidad(id: 2, organizacionId: 1, solicitanteId: 1, objeto: 'Calculadora científica', descripcion: 'La necesito para el parcial de cálculo.', fechaInicio: dia(1), fechaFin: dia(2), estado: EstadoNecesidad.buscandoPrestador),
      Necesidad(id: 3, organizacionId: 1, solicitanteId: 3, objeto: 'Proyector', descripcion: 'Para la exposición final del grupo.', fechaInicio: dia(3), fechaFin: dia(3), estado: EstadoNecesidad.buscandoPrestador),
      Necesidad(id: 4, organizacionId: 1, solicitanteId: 4, objeto: 'Cargador de portátil', descripcion: 'Cargador USB-C de 65 W.', fechaInicio: dia(-2), fechaFin: dia(1), estado: EstadoNecesidad.conPrestamoConfirmado),
      // Necesidad de Torres del Parque: Jesús pidió una bicicleta.
      Necesidad(id: 5, organizacionId: 2, solicitanteId: 1, objeto: 'Bicicleta', descripcion: 'Para recorrer el barrio el fin de semana.', fechaInicio: dia(-4), fechaFin: dia(-1), estado: EstadoNecesidad.conPrestamoConfirmado),
    ]);

    // Ofertas: dos para el taladro (Jesús alquila, Laura gratis), una aceptada en otras.
    _ofertas.addAll([
      Oferta(id: 1, necesidadId: 1, prestadorId: 1, modalidad: Modalidad.alquiler, precio: 10000, unidadCobro: UnidadCobro.dia, fechaEntrega: dia(4, 9, 0), estado: EstadoOferta.pendiente),
      Oferta(id: 2, necesidadId: 1, prestadorId: 4, modalidad: Modalidad.gratis, fechaEntrega: dia(4, 9, 30), estado: EstadoOferta.pendiente),
      Oferta(id: 3, necesidadId: 4, prestadorId: 3, modalidad: Modalidad.gratis, fechaEntrega: dia(-2, 10, 0), estado: EstadoOferta.aceptada),
      Oferta(id: 4, necesidadId: 5, prestadorId: 4, modalidad: Modalidad.gratis, fechaEntrega: dia(-4, 8, 0), estado: EstadoOferta.aceptada),
    ]);

    // Préstamos: cargador (entrega pendiente de Laura) y bicicleta (activa y vencida, con reporte).
    _prestamos.addAll([
      Prestamo(id: 1, ofertaId: 3, necesidadId: 4, organizacionId: 1, solicitanteId: 4, prestadorId: 3, objeto: 'Cargador de portátil', fechaInicio: dia(-2), fechaFin: dia(1), modalidad: Modalidad.gratis, precioTotal: 0, puntoCentral: 'Biblioteca Central, mostrador de atención', estado: EstadoPrestamo.entregaPendiente, entregaPrestadorEn: dia(-2, 10, 5)),
      Prestamo(id: 2, ofertaId: 4, necesidadId: 5, organizacionId: 2, solicitanteId: 1, prestadorId: 4, objeto: 'Bicicleta', fechaInicio: dia(-4), fechaFin: dia(-1), modalidad: Modalidad.gratis, precioTotal: 0, puntoCentral: 'Portería principal', estado: EstadoPrestamo.activo, enConflicto: true, entregaPrestadorEn: dia(-4, 8, 5), entregaSolicitanteEn: dia(-4, 8, 10)),
    ]);

    _reportes.add(Reporte(id: 1, prestamoId: 2, organizacionId: 2, reportanteId: 4, reportadoId: 1, tipo: TipoReporte.noDevuelto, descripcion: 'Pasó la fecha de devolución y la bicicleta no ha vuelto a la portería.', estado: EstadoReporte.pendiente, creadoEn: dia(-1, 15, 0)));
  }
}
