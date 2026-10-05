import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import 'auth_service.dart';
import 'organizacion_service.dart';

/// Datos de la sesión del usuario: quién es, a qué organizaciones pertenece y
/// cuál es la "organización activa" (SRS 2.2).
///
/// La organización activa es un dato de la SESIÓN, no de la cuenta: cambiarla
/// no modifica ninguna membresía (RF-019). Extiende [ChangeNotifier] para que
/// las pantallas se redibujen cuando algo cambia.
class SesionController extends ChangeNotifier {
  SesionController(this._auth, this._orgs);
  final AuthService _auth;
  final OrganizacionService _orgs;

  Usuario? _usuario;
  List<Membresia> _membresias = [];
  final Map<int, Organizacion> _organizaciones = {};
  int? _orgActivaId;

  // ---- Lectura ----
  Usuario? get usuario => _usuario;
  bool get haySesion => _usuario != null;
  List<Membresia> get membresias => _membresias;
  bool get tieneOrganizaciones => _membresias.isNotEmpty;

  Organizacion? get organizacionActiva =>
      _orgActivaId == null ? null : _organizaciones[_orgActivaId];

  Membresia? get membresiaActiva {
    for (final m in _membresias) {
      if (m.organizacionId == _orgActivaId) return m;
    }
    return null;
  }

  Organizacion? organizacion(int id) => _organizaciones[id];

  /// Es administrador SOLO de la organización activa (SRS 2.2).
  bool get esAdminActivo => membresiaActiva?.esAdministrador ?? false;

  /// RF-018: true si está suspendido o baneado en la organización activa.
  bool get bloqueadoEnActiva => membresiaActiva?.estaBloqueado ?? false;

  // ---- Acciones ----

  Future<void> iniciarSesion(String correo, String contrasena) async {
    _usuario = await _auth.iniciarSesion(correo, contrasena);
    await recargar();
  }

  Future<void> registrar(String nombre, String correo, String contrasena) async {
    _usuario = await _auth.registrar(
        nombre: nombre, correo: correo, contrasena: contrasena);
    await recargar();
  }

  void cerrarSesion() {
    _usuario = null;
    _membresias = [];
    _organizaciones.clear();
    _orgActivaId = null;
    notifyListeners();
  }

  /// Vuelve a leer membresías y organizaciones (tras unirse, sancionar, etc.).
  /// Si no hay organización activa elige la primera disponible.
  Future<void> recargar({int? activarOrganizacionId}) async {
    final u = _usuario;
    if (u == null) return;
    _membresias = await _orgs.membresiasDe(u.id);
    _organizaciones.clear();
    for (final m in _membresias) {
      final o = await _orgs.porId(m.organizacionId);
      if (o != null) _organizaciones[o.id] = o;
    }
    if (activarOrganizacionId != null) {
      _orgActivaId = activarOrganizacionId;
    }
    final sigueValida =
        _membresias.any((m) => m.organizacionId == _orgActivaId);
    if (!sigueValida) {
      _orgActivaId = _membresias.isEmpty ? null : _membresias.first.organizacionId;
    }
    notifyListeners();
  }

  /// RF-019: cambia la organización activa sin tocar ninguna membresía.
  void cambiarOrganizacion(int organizacionId) {
    if (_membresias.any((m) => m.organizacionId == organizacionId)) {
      _orgActivaId = organizacionId;
      notifyListeners();
    }
  }

  /// Avisa a las pantallas que los datos cambiaron (sin recargar membresías).
  void notificar() => notifyListeners();
}
