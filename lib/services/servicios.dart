import 'package:flutter/widgets.dart';

import '../data/api_repository.dart';
import '../data/borrow_repository.dart';
import '../data/memory_repository.dart';
import 'auth_service.dart';
import 'necesidad_service.dart';
import 'organizacion_service.dart';
import 'prestamo_service.dart';
import 'sesion_controller.dart';

/// Punto único donde se arman todas las capas (repositorio -> servicios -> sesión).
///
/// Las pantallas piden lo que necesitan con `Servicios.i`. Por defecto usa
/// [ApiRepository] (conectado a FastAPI y PostgreSQL) y permite inyectar
/// [MemoryRepository] para pruebas unitarias y de widgets.
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

  static Servicios? _instancia;

  static Servicios get i => _instancia ??= Servicios._(
        _esEntornoTest() ? MemoryRepository() : ApiRepository(),
      );

  static set i(Servicios valor) => _instancia = valor;

  static bool _esEntornoTest() {
    try {
      final tipo = WidgetsBinding.instance.runtimeType.toString();
      return tipo.contains('TestWidgetsFlutterBinding') ||
          tipo.contains('AutomatedTestWidgetsFlutterBinding');
    } catch (_) {
      return false;
    }
  }

  /// Se llama una vez al arrancar la app (main.dart).
  /// Usa [ApiRepository] por defecto en ejecución real y mantiene compatibilidad
  /// con [MemoryRepository] en los tests de Flutter.
  static void iniciar([BorrowRepository? repositorio]) {
    _instancia = Servicios._(
      repositorio ?? (_esEntornoTest() ? MemoryRepository() : ApiRepository()),
    );
  }
}
