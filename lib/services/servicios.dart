import '../data/borrow_repository.dart';
import '../data/memory_repository.dart';
import 'auth_service.dart';
import 'necesidad_service.dart';
import 'organizacion_service.dart';
import 'prestamo_service.dart';
import 'sesion_controller.dart';

/// Punto único donde se arman todas las capas (repositorio -> servicios -> sesión).
///
/// Las pantallas piden lo que necesitan con `Servicios.i`. Para conectar el
/// backend real basta cambiar el repositorio en [Servicios.iniciar].
class Servicios {
  Servicios._(this.repo)
      : auth = AuthService(repo),
        organizaciones = OrganizacionService(repo) {
    necesidades = NecesidadService(repo, organizaciones);
    prestamos = PrestamoService(repo, organizaciones);
    sesion = SesionController(auth, organizaciones);
  }

  final BorrowRepository repo;
  final AuthService auth;
  final OrganizacionService organizaciones;
  late final NecesidadService necesidades;
  late final PrestamoService prestamos;
  late final SesionController sesion;

  static late Servicios i;

  /// Se llama una vez al arrancar la app (main.dart).
  static void iniciar([BorrowRepository? repositorio]) {
    i = Servicios._(repositorio ?? MemoryRepository());
  }
}
