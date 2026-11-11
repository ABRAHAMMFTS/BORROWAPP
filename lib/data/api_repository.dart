import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../models/usuario.dart';
import '../utils/regla_negocio_exception.dart';
import 'borrow_repository.dart';

/// Implementación de [BorrowRepository] conectada a la API REST en FastAPI
/// y PostgreSQL (Supabase / Render).
///
/// Sigue los estándares de las guías `Guia_API_MySQL_Local` y
/// `Guia_API_Publicar_en_Render`.
class ApiRepository implements BorrowRepository {
  ApiRepository({String? urlBase, http.Client? client})
    : _baseUrl = _normalizarBaseUrl(urlBase ?? baseUrl),
      _client = client ?? http.Client();

  // ===========================================================================
  // CONFIGURACIÓN DE LA URL DE LA API (Guía del Profesor)
  // ===========================================================================
  // Opción A — Chrome, Edge o Windows en el mismo PC donde corre Uvicorn:
  // static const String baseUrl = 'http://127.0.0.1:8000';
  //
  // Opción B — Emulador de Android (10.0.2.2 apunta al PC anfitrión):
  // static const String baseUrl = 'http://10.0.2.2:8000';
  //
  // Opción C — API publicada en Render (producción en la nube):
  // static const String baseUrl = https://borrowapp.onrender.com;
  //
  // Por defecto usa 127.0.0.1:8000 en local y permite inyectar la URL de Render
  // al compilar con: --dart-define=API_URL=https://tu-api.onrender.com
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://borrowapp.onrender.com',
  );

  final String _baseUrl;
  final http.Client _client;

  /// Token JWT recibido tras iniciar sesión o registrarse.
  String? token;

  int _contadorTemp = 10000;

  // Cachés en memoria de la sesión actual para resolver relaciones rápidas.
  final Map<int, Usuario> _usuarios = {};
  final Map<int, Organizacion> _organizaciones = {};
  final Map<int, Membresia> _membresias = {};
  final Map<String, String> _motivosSancion = {};
  final Map<int, Necesidad> _necesidades = {};
  final Map<int, Oferta> _ofertas = {};
  final Map<int, Prestamo> _prestamos = {};
  final Map<int, Reporte> _reportes = {};

  static String _normalizarBaseUrl(String url) {
    final limpia = url.trim();
    if (limpia.endsWith('/')) {
      return limpia.substring(0, limpia.length - 1);
    }
    return limpia;
  }

  Uri _uri(String ruta, [Map<String, String>? queryParameters]) {
    final path = ruta.startsWith('/') ? ruta : '/$ruta';
    return Uri.parse('$_baseUrl$path')
        .replace(queryParameters: queryParameters);
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Ayudante central para enviar peticiones HTTP con timeout de 70 segundos
  /// (para soportar el arranque en frío de Render en el plan gratuito).
  Future<http.Response> _enviar(Future<http.Response> peticion) async {
    final http.Response respuesta;
    try {
      respuesta = await peticion.timeout(const Duration(seconds: 70));
    } catch (_) {
      throw ReglaNegocioException(
        'No se pudo conectar con la API en $_baseUrl. ¿Está encendida? '
        'Si está en Render, espera un minuto y vuelve a intentar.',
      );
    }

    if (respuesta.statusCode >= 400) {
      throw ReglaNegocioException(_extraerMensajeError(respuesta));
    }
    return respuesta;
  }

  String _extraerMensajeError(http.Response respuesta) {
    try {
      final body = utf8.decode(respuesta.bodyBytes);
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
        if (detail is List && detail.isNotEmpty) {
          final primero = detail.first;
          if (primero is Map && primero['msg'] is String) {
            final msg = (primero['msg'] as String)
                .replaceFirst(RegExp(r'^Value error,\s*'), '')
                .trim();
            if (msg.isNotEmpty) return msg;
          }
        }
        if (decoded['mensaje'] is String) {
          return (decoded['mensaje'] as String).trim();
        }
      }
    } catch (_) {
      // Si el cuerpo no es JSON válido, cae al mensaje por código de estado.
    }
    return 'Error del servidor (código ${respuesta.statusCode}).';
  }

  dynamic _decodificar(http.Response respuesta) {
    final texto = utf8.decode(respuesta.bodyBytes);
    if (texto.isEmpty) return null;
    return jsonDecode(texto);
  }

  @override
  int siguienteId() => ++_contadorTemp;

  // ===========================================================================
  // PARSERS DE JSON A MODELOS DART
  // ===========================================================================

  Usuario _parseUsuario(Map<String, dynamic> json) {
    final u = Usuario(
      id: (json['id'] as num).toInt(),
      nombre: (json['nombre'] as String?) ?? 'Usuario',
      correo:
          (json['correo'] as String?) ??
          _usuarios[(json['id'] as num).toInt()]?.correo ??
          '',
      contrasenaHash: '',
    );
    _usuarios[u.id] = u;
    return u;
  }

  TipoOrganizacion _parseTipoOrganizacion(String valor) {
    switch (valor.toUpperCase()) {
      case 'UNIVERSIDAD':
        return TipoOrganizacion.universidad;
      case 'EMPRESA':
        return TipoOrganizacion.empresa;
      case 'CONJUNTO_RESIDENCIAL':
      default:
        return TipoOrganizacion.conjuntoResidencial;
    }
  }

  String _serializarTipoOrganizacion(TipoOrganizacion tipo) {
    switch (tipo) {
      case TipoOrganizacion.universidad:
        return 'UNIVERSIDAD';
      case TipoOrganizacion.empresa:
        return 'EMPRESA';
      case TipoOrganizacion.conjuntoResidencial:
        return 'CONJUNTO_RESIDENCIAL';
    }
  }

  RolMembresia _parseRol(String valor) {
    switch (valor.toUpperCase()) {
      case 'ADMINISTRADOR':
        return RolMembresia.administrador;
      case 'MIEMBRO':
      default:
        return RolMembresia.miembro;
    }
  }

  EstadoMembresia _parseEstadoMembresia(String valor) {
    switch (valor.toUpperCase()) {
      case 'ADVERTIDO':
        return EstadoMembresia.advertido;
      case 'SUSPENDIDO':
        return EstadoMembresia.suspendido;
      case 'BANEADO':
        return EstadoMembresia.baneado;
      case 'ACTIVO':
      default:
        return EstadoMembresia.activo;
    }
  }

  EstadoNecesidad _parseEstadoNecesidad(String valor) {
    switch (valor.toUpperCase()) {
      case 'CON_PRESTAMO_CONFIRMADO':
        return EstadoNecesidad.conPrestamoConfirmado;
      case 'CERRADA':
        return EstadoNecesidad.cerrada;
      case 'BUSCANDO_PRESTADOR':
      default:
        return EstadoNecesidad.buscandoPrestador;
    }
  }

  Modalidad _parseModalidad(String valor) {
    switch (valor.toUpperCase()) {
      case 'ALQUILER':
        return Modalidad.alquiler;
      case 'GRATIS':
      default:
        return Modalidad.gratis;
    }
  }

  String _serializarModalidad(Modalidad modalidad) {
    switch (modalidad) {
      case Modalidad.gratis:
        return 'GRATIS';
      case Modalidad.alquiler:
        return 'ALQUILER';
    }
  }

  UnidadCobro? _parseUnidadCobro(String? valor) {
    if (valor == null) return null;
    switch (valor.toUpperCase()) {
      case 'HORA':
        return UnidadCobro.hora;
      case 'DIA':
        return UnidadCobro.dia;
      default:
        return null;
    }
  }

  String? _serializarUnidadCobro(UnidadCobro? unidad) {
    if (unidad == null) return null;
    switch (unidad) {
      case UnidadCobro.hora:
        return 'HORA';
      case UnidadCobro.dia:
        return 'DIA';
    }
  }

  EstadoOferta _parseEstadoOferta(String valor) {
    switch (valor.toUpperCase()) {
      case 'ACEPTADA':
        return EstadoOferta.aceptada;
      case 'RECHAZADA':
        return EstadoOferta.rechazada;
      case 'CERRADA':
        return EstadoOferta.cerrada;
      case 'PENDIENTE':
      default:
        return EstadoOferta.pendiente;
    }
  }

  EstadoPrestamo _parseEstadoPrestamo(String valor) {
    switch (valor.toUpperCase()) {
      case 'ENTREGA_PENDIENTE':
        return EstadoPrestamo.entregaPendiente;
      case 'ACTIVO':
        return EstadoPrestamo.activo;
      case 'DEVOLUCION_PENDIENTE':
        return EstadoPrestamo.devolucionPendiente;
      case 'FINALIZADO':
        return EstadoPrestamo.finalizado;
      case 'CONFIRMADO':
      default:
        return EstadoPrestamo.confirmado;
    }
  }

  TipoReporte _parseTipoReporte(String valor) {
    switch (valor.toUpperCase()) {
      case 'NO_DEVUELTO':
        return TipoReporte.noDevuelto;
      case 'DANADO':
        return TipoReporte.danado;
      case 'NO_ASISTIO':
      case 'INASISTENCIA':
      default:
        return TipoReporte.noAsistio;
    }
  }

  String _serializarTipoReporte(TipoReporte tipo) {
    switch (tipo) {
      case TipoReporte.noDevuelto:
        return 'NO_DEVUELTO';
      case TipoReporte.danado:
        return 'DANADO';
      case TipoReporte.noAsistio:
        return 'NO_ASISTIO';
    }
  }

  EstadoReporte _parseEstadoReporte(String valor) {
    switch (valor.toUpperCase()) {
      case 'RESUELTO':
        return EstadoReporte.resuelto;
      case 'PENDIENTE':
      default:
        return EstadoReporte.pendiente;
    }
  }

  Sancion? _parseSancion(String? valor) {
    if (valor == null) return null;
    switch (valor.toUpperCase()) {
      case 'ADVERTENCIA':
        return Sancion.advertencia;
      case 'SUSPENSION':
      case 'SUSPENSION_TEMPORAL':
        return Sancion.suspension;
      case 'BANEO':
      case 'BANEO_PERMANENTE':
        return Sancion.baneo;
      default:
        return null;
    }
  }

  String _serializarSancion(Sancion sancion) {
    switch (sancion) {
      case Sancion.advertencia:
        return 'ADVERTENCIA';
      case Sancion.suspension:
        return 'SUSPENSION_TEMPORAL';
      case Sancion.baneo:
        return 'BANEO_PERMANENTE';
    }
  }

  DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    if (valor is String && valor.isNotEmpty) {
      return DateTime.tryParse(valor);
    }
    return null;
  }

  Organizacion _parseOrganizacion(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    final existente = _organizaciones[id];
    final codigoJson = (json['codigo'] as String?) ?? '';
    final org = Organizacion(
      id: id,
      nombre: (json['nombre'] as String?) ?? '',
      tipo: _parseTipoOrganizacion((json['tipo'] as String?) ?? 'UNIVERSIDAD'),
      codigo: codigoJson.isNotEmpty ? codigoJson : (existente?.codigo ?? ''),
      puntoCentral:
          ((json['punto_central'] ?? json['puntoCentral']) as String?) ?? '',
      creadaPor:
          ((json['creada_por'] ?? json['creadaPor']) as num?)?.toInt() ??
          existente?.creadaPor ??
          0,
    );
    _organizaciones[org.id] = org;
    return org;
  }

  Membresia _parseMembresia(Map<String, dynamic> json) {
    if (json['organizacion'] is Map<String, dynamic>) {
      _parseOrganizacion(json['organizacion'] as Map<String, dynamic>);
    }
    if (json['usuario'] is Map<String, dynamic>) {
      final uMap = Map<String, dynamic>.from(json['usuario'] as Map);
      if (json['correo'] is String && uMap['correo'] == null) {
        uMap['correo'] = json['correo'];
      }
      _parseUsuario(uMap);
    }
    final id = ((json['id'] ?? json['membresia_id']) as num).toInt();
    final usuarioId =
        (json['usuario_id'] as num?)?.toInt() ??
        ((json['usuario'] is Map)
            ? ((json['usuario']['id']) as num).toInt()
            : 0);
    final orgId =
        (json['organizacion_id'] as num?)?.toInt() ??
        ((json['organizacion'] is Map)
            ? ((json['organizacion']['id']) as num).toInt()
            : 0);
    final motivo =
        (json['sancion_motivo'] ?? json['motivo_sancion']) as String?;
    if (motivo != null && motivo.trim().isNotEmpty) {
      _motivosSancion['${usuarioId}_$orgId'] = motivo.trim();
    }
    final m = Membresia(
      id: id,
      usuarioId: usuarioId,
      organizacionId: orgId,
      rol: _parseRol((json['rol'] as String?) ?? 'MIEMBRO'),
      estado: _parseEstadoMembresia((json['estado'] as String?) ?? 'ACTIVO'),
      identificadorInterno:
          ((json['identificador_interno'] ?? json['identificadorInterno'])
              as String?) ??
          '',
      sancionHasta: _parseFecha(
        json['sancion_hasta'] ?? json['fecha_fin_suspension'],
      ),
    );
    _membresias[m.id] = m;
    return m;
  }

  Necesidad _parseNecesidad(Map<String, dynamic> json) {
    if (json['solicitante'] is Map<String, dynamic>) {
      _parseUsuario(json['solicitante'] as Map<String, dynamic>);
    }
    final solicitanteId =
        (json['solicitante_id'] as num?)?.toInt() ??
        ((json['solicitante'] is Map)
            ? ((json['solicitante']['id']) as num).toInt()
            : 0);
    final n = Necesidad(
      id: (json['id'] as num).toInt(),
      organizacionId: (json['organizacion_id'] as num).toInt(),
      solicitanteId: solicitanteId,
      objeto: (json['objeto'] as String?) ?? '',
      descripcion: (json['descripcion'] as String?) ?? '',
      fechaInicio: _parseFecha(json['fecha_inicio']) ?? DateTime.now(),
      fechaFin: _parseFecha(json['fecha_fin']) ?? DateTime.now(),
      estado: _parseEstadoNecesidad(
        (json['estado'] as String?) ?? 'BUSCANDO_PRESTADOR',
      ),
    );
    _necesidades[n.id] = n;
    return n;
  }

  Oferta _parseOferta(Map<String, dynamic> json) {
    if (json['prestador'] is Map<String, dynamic>) {
      _parseUsuario(json['prestador'] as Map<String, dynamic>);
    }
    final prestadorId =
        (json['prestador_id'] as num?)?.toInt() ??
        ((json['prestador'] is Map)
            ? ((json['prestador']['id']) as num).toInt()
            : 0);
    final o = Oferta(
      id: (json['id'] as num).toInt(),
      necesidadId: (json['necesidad_id'] as num).toInt(),
      prestadorId: prestadorId,
      modalidad: _parseModalidad((json['modalidad'] as String?) ?? 'GRATIS'),
      precio: (json['precio'] as num?)?.toDouble(),
      unidadCobro: _parseUnidadCobro(json['unidad_cobro'] as String?),
      fechaEntrega: _parseFecha(json['fecha_entrega']) ?? DateTime.now(),
      estado: _parseEstadoOferta((json['estado'] as String?) ?? 'PENDIENTE'),
    );
    _ofertas[o.id] = o;
    return o;
  }

  Prestamo _parsePrestamo(Map<String, dynamic> json) {
    if (json['solicitante'] is Map<String, dynamic>) {
      _parseUsuario(json['solicitante'] as Map<String, dynamic>);
    }
    if (json['prestador'] is Map<String, dynamic>) {
      _parseUsuario(json['prestador'] as Map<String, dynamic>);
    }
    final solicitanteId =
        (json['solicitante_id'] as num?)?.toInt() ??
        ((json['solicitante'] is Map)
            ? ((json['solicitante']['id']) as num).toInt()
            : 0);
    final prestadorId =
        (json['prestador_id'] as num?)?.toInt() ??
        ((json['prestador'] is Map)
            ? ((json['prestador']['id']) as num).toInt()
            : 0);
    final p = Prestamo(
      id: (json['id'] as num).toInt(),
      ofertaId: (json['oferta_id'] as num?)?.toInt() ?? 0,
      necesidadId: (json['necesidad_id'] as num).toInt(),
      organizacionId: (json['organizacion_id'] as num).toInt(),
      solicitanteId: solicitanteId,
      prestadorId: prestadorId,
      objeto: (json['objeto'] as String?) ?? '',
      fechaInicio: _parseFecha(json['fecha_inicio']) ?? DateTime.now(),
      fechaFin: _parseFecha(json['fecha_fin']) ?? DateTime.now(),
      modalidad: _parseModalidad((json['modalidad'] as String?) ?? 'GRATIS'),
      precioTotal: (json['precio_total'] as num?)?.toDouble() ?? 0,
      puntoCentral: (json['punto_central'] as String?) ?? '',
      estado: _parseEstadoPrestamo((json['estado'] as String?) ?? 'CONFIRMADO'),
      enConflicto: (json['en_conflicto'] as bool?) ?? false,
      entregaPrestadorEn: _parseFecha(json['entrega_prestador_en']),
      entregaSolicitanteEn: _parseFecha(json['entrega_solicitante_en']),
      devolucionSolicitanteEn: _parseFecha(json['devolucion_solicitante_en']),
      devolucionPrestadorEn: _parseFecha(json['devolucion_prestador_en']),
    );
    _prestamos[p.id] = p;
    return p;
  }

  Reporte _parseReporte(Map<String, dynamic> json) {
    if (json['reportante'] is Map<String, dynamic>) {
      _parseUsuario(json['reportante'] as Map<String, dynamic>);
    }
    if (json['reportado'] is Map<String, dynamic>) {
      _parseUsuario(json['reportado'] as Map<String, dynamic>);
    }
    final reportanteId =
        (json['reportante_id'] as num?)?.toInt() ??
        ((json['reportante'] is Map)
            ? ((json['reportante']['id']) as num).toInt()
            : 0);
    final reportadoId =
        (json['reportado_id'] as num?)?.toInt() ??
        ((json['reportado'] is Map)
            ? ((json['reportado']['id']) as num).toInt()
            : 0);
    final r = Reporte(
      id: (json['id'] as num).toInt(),
      prestamoId: (json['prestamo_id'] as num).toInt(),
      organizacionId: (json['organizacion_id'] as num).toInt(),
      reportanteId: reportanteId,
      reportadoId: reportadoId,
      tipo: _parseTipoReporte((json['tipo'] as String?) ?? 'NO_DEVUELTO'),
      descripcion: (json['descripcion'] as String?) ?? '',
      estado: _parseEstadoReporte((json['estado'] as String?) ?? 'PENDIENTE'),
      creadoEn: _parseFecha(json['creado_en']) ?? DateTime.now(),
      sancion: _parseSancion(json['sancion'] as String?),
      notaResolucion: json['nota_resolucion'] as String?,
      adminId: ((json['admin_id'] ?? json['admin_resolutor_id']) as num?)
          ?.toInt(),
      resueltoEn: _parseFecha(json['resuelto_en']),
    );
    _reportes[r.id] = r;
    if (r.notaResolucion != null && r.notaResolucion!.trim().isNotEmpty) {
      _motivosSancion['${r.reportadoId}_${r.organizacionId}'] = r
          .notaResolucion!
          .trim();
    }
    return r;
  }

  // ===========================================================================
  // MÉTODOS DE AUTENTICACIÓN Y ENDPOINTS DE NEGOCIO DIRECTOS
  // ===========================================================================

  /// POST /api/v1/auth/register
  Future<Usuario> registrarRemoto({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'nombre': nombre.trim(),
          'correo': correo.trim().toLowerCase(),
          'contrasena': contrasena,
        }),
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    token = (data['access_token'] ?? data['token']) as String?;
    final usuario = _parseUsuario(data['usuario'] as Map<String, dynamic>);
    if (data['membresias'] is List) {
      for (final m in data['membresias'] as List) {
        _parseMembresia(m as Map<String, dynamic>);
      }
    }
    return usuario;
  }

  /// POST /api/v1/auth/login
  Future<Usuario> iniciarSesionRemoto({
    required String correo,
    required String contrasena,
  }) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'correo': correo.trim().toLowerCase(),
          'contrasena': contrasena,
        }),
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    token = (data['access_token'] ?? data['token']) as String?;
    final usuario = _parseUsuario(data['usuario'] as Map<String, dynamic>);
    _membresias.clear();
    if (data['membresias'] is List) {
      for (final m in data['membresias'] as List) {
        _parseMembresia(m as Map<String, dynamic>);
      }
    }
    return usuario;
  }

  /// Limpia el token JWT y los datos en caché al cerrar sesión.
  void limpiarSesion() {
    token = null;
    _membresias.clear();
    _organizaciones.clear();
    _necesidades.clear();
    _ofertas.clear();
    _prestamos.clear();
    _reportes.clear();
  }

  /// POST /api/v1/organizations (RF-003)
  Future<Organizacion> crearOrganizacionRemota({
    required String nombre,
    required TipoOrganizacion tipo,
    required String puntoCentral,
    required String identificadorInterno,
  }) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/organizations'),
        headers: _headers,
        body: jsonEncode({
          'nombre': nombre.trim(),
          'tipo': _serializarTipoOrganizacion(tipo),
          'punto_central': puntoCentral.trim(),
          'identificador_interno': identificadorInterno.trim(),
        }),
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    final org = _parseOrganizacion(data);
    if (data['membresia'] is Map<String, dynamic>) {
      _parseMembresia(data['membresia'] as Map<String, dynamic>);
    }
    return org;
  }

  /// POST /api/v1/organizations/{org_id}/join (RF-004 paso 2)
  Future<Membresia> unirseAOrganizacionRemota({
    required int organizacionId,
    required String identificadorInterno,
  }) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/organizations/$organizacionId/join'),
        headers: _headers,
        body: jsonEncode({
          'identificador_interno': identificadorInterno.trim(),
        }),
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    return _parseMembresia(data);
  }

  /// PATCH /api/v1/organizations/{org_id}/central-point (RF-016)
  Future<Organizacion> cambiarPuntoCentralRemoto({
    required int organizacionId,
    required String nuevoPunto,
  }) async {
    final res = await _enviar(
      _client.patch(
        _uri('/api/v1/organizations/$organizacionId/central-point'),
        headers: _headers,
        body: jsonEncode({'punto_central': nuevoPunto.trim()}),
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    return _parseOrganizacion(data);
  }

  /// POST /api/v1/organizations/{org_id}/needs (RF-006)
  Future<Necesidad> publicarNecesidadRemota({
    required int organizacionId,
    required String objeto,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/organizations/$organizacionId/needs'),
        headers: _headers,
        body: jsonEncode({
          'organizacion_id': organizacionId,
          'objeto': objeto.trim(),
          'descripcion': descripcion.trim(),
          'fecha_inicio': fechaInicio.toIso8601String(),
          'fecha_fin': fechaFin.toIso8601String(),
        }),
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    return _parseNecesidad(data);
  }

  /// POST /api/v1/needs/{need_id}/cancel (RF-020)
  Future<Necesidad> cancelarNecesidadRemota(int necesidadId) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/needs/$necesidadId/cancel'),
        headers: _headers,
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    return _parseNecesidad(data);
  }

  /// POST /api/v1/needs/{need_id}/offers (RF-008 y RF-009)
  Future<Oferta> crearOfertaRemota({
    required int necesidadId,
    required Modalidad modalidad,
    double? precio,
    UnidadCobro? unidad,
    required DateTime fechaEntrega,
  }) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/needs/$necesidadId/offers'),
        headers: _headers,
        body: jsonEncode({
          'necesidad_id': necesidadId,
          'modalidad': _serializarModalidad(modalidad),
          'precio': modalidad == Modalidad.alquiler ? precio : null,
          'unidad_cobro': modalidad == Modalidad.alquiler
              ? _serializarUnidadCobro(unidad)
              : null,
          'fecha_entrega': fechaEntrega.toIso8601String(),
        }),
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    return _parseOferta(data);
  }

  /// POST /api/v1/offers/{offer_id}/reject (RF-010)
  Future<Oferta> rechazarOfertaRemota(int ofertaId) async {
    final res = await _enviar(
      _client.post(_uri('/api/v1/offers/$ofertaId/reject'), headers: _headers),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    return _parseOferta(data);
  }

  /// POST /api/v1/offers/{offer_id}/accept (RF-010, RF-011, RNF-007)
  Future<Prestamo> aceptarOfertaRemota(int ofertaId) async {
    final res = await _enviar(
      _client.post(_uri('/api/v1/offers/$ofertaId/accept'), headers: _headers),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    return _parsePrestamo(data);
  }

  /// POST /api/v1/loans/{loan_id}/mark-delivered (RF-012 paso 1)
  Future<Prestamo> marcarEntregadoRemoto(int prestamoId) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/loans/$prestamoId/mark-delivered'),
        headers: _headers,
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    return _parsePrestamo(data);
  }

  /// POST /api/v1/loans/{loan_id}/confirm-received (RF-012 paso 2)
  Future<Prestamo> confirmarRecibidoRemoto(int prestamoId) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/loans/$prestamoId/confirm-received'),
        headers: _headers,
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    return _parsePrestamo(data);
  }

  /// POST /api/v1/loans/{loan_id}/mark-returned (RF-013 paso 3)
  Future<Prestamo> marcarDevueltoRemoto(int prestamoId) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/loans/$prestamoId/mark-returned'),
        headers: _headers,
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    return _parsePrestamo(data);
  }

  /// POST /api/v1/loans/{loan_id}/confirm-returned (RF-013 paso 4)
  Future<Prestamo> confirmarDevolucionRemota(int prestamoId) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/loans/$prestamoId/confirm-returned'),
        headers: _headers,
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    return _parsePrestamo(data);
  }

  /// POST /api/v1/loans/{loan_id}/reports (RF-014)
  Future<Reporte> reportarProblemaRemoto({
    required int prestamoId,
    required TipoReporte tipo,
    required String descripcion,
  }) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/loans/$prestamoId/reports'),
        headers: _headers,
        body: jsonEncode({
          'tipo': _serializarTipoReporte(tipo),
          'descripcion': descripcion.trim(),
        }),
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    final r = _parseReporte(data);
    final p = _prestamos[prestamoId];
    if (p != null) {
      _prestamos[prestamoId] = p.copyWith(enConflicto: true);
    }
    return r;
  }

  /// POST /api/v1/reports/{report_id}/resolve (RF-017)
  Future<Reporte> resolverReporteRemoto({
    required int reporteId,
    required Sancion sancion,
    required String nota,
    DateTime? suspensionHasta,
  }) async {
    final res = await _enviar(
      _client.post(
        _uri('/api/v1/reports/$reporteId/resolve'),
        headers: _headers,
        body: jsonEncode({
          'sancion': _serializarSancion(sancion),
          'nota_resolucion': nota.trim(),
          'nota': nota.trim(),
          if (suspensionHasta != null)
            'sancion_hasta': suspensionHasta.toIso8601String(),
        }),
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    final r = _parseReporte(data);
    final p = _prestamos[r.prestamoId];
    if (p != null) {
      _prestamos[r.prestamoId] = p.copyWith(enConflicto: false);
    }
    return r;
  }

  /// POST /api/v1/organizations/{org_id}/members/{user_id}/revert-sanction (RF-017)
  Future<Membresia> revertirSancionRemota({
    required int organizacionId,
    required int usuarioId,
  }) async {
    final res = await _enviar(
      _client.post(
        _uri(
          '/api/v1/organizations/$organizacionId/members/$usuarioId/revert-sanction',
        ),
        headers: _headers,
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    _motivosSancion.remove('${usuarioId}_$organizacionId');
    return _parseMembresia(data);
  }

  /// Obtiene el motivo de sanción cacheado o desde los reportes de la organización.
  Future<String?> motivoSancionRemoto(int usuarioId, int organizacionId) async {
    final enCache = _motivosSancion['${usuarioId}_$organizacionId'];
    if (enCache != null && enCache.isNotEmpty) return enCache;
    try {
      await reportesDeOrganizacion(organizacionId);
      return _motivosSancion['${usuarioId}_$organizacionId'];
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // IMPLEMENTACIÓN DE BORROWREPOSITORY
  // ===========================================================================

  @override
  Future<Usuario?> usuarioPorId(int id) async {
    final enCache = _usuarios[id];
    if (enCache != null) return enCache;
    try {
      final res = await _enviar(
        _client.get(_uri('/api/v1/users/$id'), headers: _headers),
      );
      final data = _decodificar(res) as Map<String, dynamic>;
      return _parseUsuario(data);
    } on ReglaNegocioException {
      return null;
    }
  }

  @override
  Future<Usuario?> usuarioPorCorreo(String correo) async {
    final limpio = correo.trim().toLowerCase();
    for (final u in _usuarios.values) {
      if (u.correo.toLowerCase() == limpio) return u;
    }
    return null;
  }

  @override
  Future<void> guardarUsuario(Usuario usuario) async {
    _usuarios[usuario.id] = usuario;
  }

  @override
  Future<Organizacion?> organizacionPorId(int id) async {
    final enCache = _organizaciones[id];
    if (enCache != null) return enCache;
    try {
      final res = await _enviar(
        _client.get(
          _uri('/api/v1/organizations/my-memberships'),
          headers: _headers,
        ),
      );
      final lista = _decodificar(res) as List;
      for (final item in lista) {
        _parseMembresia(item as Map<String, dynamic>);
      }
      return _organizaciones[id];
    } on ReglaNegocioException {
      return null;
    }
  }

  @override
  Future<Organizacion?> organizacionPorCodigo(String codigo) async {
    final res = await _enviar(
      _client.get(
        _uri('/api/v1/organizations/by-code/${codigo.trim().toUpperCase()}'),
        headers: _headers,
      ),
    );
    final data = _decodificar(res) as Map<String, dynamic>;
    return _parseOrganizacion(data);
  }

  @override
  Future<void> guardarOrganizacion(Organizacion organizacion) async {
    _organizaciones[organizacion.id] = organizacion;
  }

  @override
  Future<List<Membresia>> membresiasDeUsuario(int usuarioId) async {
    final res = await _enviar(
      _client.get(
        _uri('/api/v1/organizations/my-memberships'),
        headers: _headers,
      ),
    );
    final lista = _decodificar(res) as List;
    final salida = <Membresia>[];
    for (final item in lista) {
      salida.add(_parseMembresia(item as Map<String, dynamic>));
    }
    return salida;
  }

  @override
  Future<List<Membresia>> membresiasDeOrganizacion(int organizacionId) async {
    final res = await _enviar(
      _client.get(
        _uri('/api/v1/organizations/$organizacionId/members'),
        headers: _headers,
      ),
    );
    final lista = _decodificar(res) as List;
    final salida = <Membresia>[];
    for (final item in lista) {
      salida.add(_parseMembresia(item as Map<String, dynamic>));
    }
    return salida;
  }

  @override
  Future<Membresia?> membresia(int usuarioId, int organizacionId) async {
    for (final m in _membresias.values) {
      if (m.usuarioId == usuarioId && m.organizacionId == organizacionId) {
        return m;
      }
    }
    try {
      final miembros = await membresiasDeOrganizacion(organizacionId);
      for (final m in miembros) {
        if (m.usuarioId == usuarioId) return m;
      }
    } catch (_) {
      // Si no pertenece a la organización, retorna null.
    }
    return null;
  }

  @override
  Future<void> guardarMembresia(Membresia membresia) async {
    _membresias[membresia.id] = membresia;
  }

  @override
  Future<List<Necesidad>> necesidadesDeOrganizacion(int organizacionId) async {
    final res = await _enviar(
      _client.get(
        _uri('/api/v1/organizations/$organizacionId/needs'),
        headers: _headers,
      ),
    );
    final lista = _decodificar(res) as List;
    final salida = <Necesidad>[];
    for (final item in lista) {
      salida.add(_parseNecesidad(item as Map<String, dynamic>));
    }
    return salida;
  }

  @override
  Future<Necesidad?> necesidadPorId(int id) async {
    final enCache = _necesidades[id];
    if (enCache != null) return enCache;
    final res = await _enviar(
      _client.get(_uri('/api/v1/needs'), headers: _headers),
    );
    final lista = _decodificar(res) as List;
    for (final item in lista) {
      _parseNecesidad(item as Map<String, dynamic>);
    }
    return _necesidades[id];
  }

  @override
  Future<void> guardarNecesidad(Necesidad necesidad) async {
    _necesidades[necesidad.id] = necesidad;
  }

  @override
  Future<List<Oferta>> ofertasDeNecesidad(int necesidadId) async {
    final res = await _enviar(
      _client.get(_uri('/api/v1/needs/$necesidadId/offers'), headers: _headers),
    );
    final lista = _decodificar(res) as List;
    final salida = <Oferta>[];
    for (final item in lista) {
      salida.add(_parseOferta(item as Map<String, dynamic>));
    }
    return salida;
  }

  @override
  Future<List<Oferta>> ofertasDePrestador(int prestadorId) async {
    final res = await _enviar(
      _client.get(_uri('/api/v1/offers/me'), headers: _headers),
    );
    final lista = _decodificar(res) as List;
    final salida = <Oferta>[];
    for (final item in lista) {
      salida.add(_parseOferta(item as Map<String, dynamic>));
    }
    return salida;
  }

  @override
  Future<Oferta?> ofertaPorId(int id) async => _ofertas[id];

  @override
  Future<void> guardarOferta(Oferta oferta) async {
    _ofertas[oferta.id] = oferta;
  }

  @override
  Future<List<Prestamo>> prestamosDeOrganizacion(int organizacionId) async {
    final res = await _enviar(
      _client.get(
        _uri('/api/v1/organizations/$organizacionId/loans'),
        headers: _headers,
      ),
    );
    final lista = _decodificar(res) as List;
    final salida = <Prestamo>[];
    for (final item in lista) {
      salida.add(_parsePrestamo(item as Map<String, dynamic>));
    }
    return salida;
  }

  @override
  Future<Prestamo?> prestamoPorId(int id) async {
    try {
      final res = await _enviar(
        _client.get(_uri('/api/v1/loans/$id'), headers: _headers),
      );
      final data = _decodificar(res) as Map<String, dynamic>;
      return _parsePrestamo(data);
    } on ReglaNegocioException {
      return _prestamos[id];
    }
  }

  @override
  Future<void> guardarPrestamo(Prestamo prestamo) async {
    _prestamos[prestamo.id] = prestamo;
  }

  @override
  Future<List<Reporte>> reportesDeOrganizacion(int organizacionId) async {
    final res = await _enviar(
      _client.get(
        _uri('/api/v1/organizations/$organizacionId/reports'),
        headers: _headers,
      ),
    );
    final lista = _decodificar(res) as List;
    final salida = <Reporte>[];
    for (final item in lista) {
      salida.add(_parseReporte(item as Map<String, dynamic>));
    }
    return salida;
  }

  @override
  Future<Reporte?> reportePorId(int id) async => _reportes[id];

  @override
  Future<void> guardarReporte(Reporte reporte) async {
    _reportes[reporte.id] = reporte;
  }

  @override
  Future<void> reiniciar() async {
    limpiarSesion();
  }
}
