import 'enums.dart';

// Modelos de identidad: Usuario, Organización y Membresía (SRS 4.2).

/// La persona con cuenta en la app. No depende de ninguna organización.
class Usuario {
  final int id;
  final String nombre;
  final String correo;

  /// Contraseña cifrada. Nunca se guarda en texto plano (RNF-002).
  final String contrasenaHash;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.contrasenaHash,
  });

  /// Iniciales para el avatar (ej. "Jesús Vergara" -> "JV").
  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  /// Solo el primer nombre, para saludos ("Hola, Jesús").
  String get primerNombre => nombre.trim().split(RegExp(r'\s+')).first;
}

/// La comunidad cerrada (universidad, empresa o conjunto residencial).
class Organizacion {
  final int id;
  final String nombre;
  final TipoOrganizacion tipo;

  /// Código de acceso de 5 caracteres, único en todo el sistema.
  final String codigo;

  /// Lugar de entrega y devolución. El administrador puede cambiarlo.
  final String puntoCentral;

  /// Id del usuario que la creó (su administrador).
  final int creadaPor;

  const Organizacion({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.codigo,
    required this.puntoCentral,
    required this.creadaPor,
  });

  Organizacion copyWith({String? puntoCentral}) => Organizacion(
        id: id,
        nombre: nombre,
        tipo: tipo,
        codigo: codigo,
        puntoCentral: puntoCentral ?? this.puntoCentral,
        creadaPor: creadaPor,
      );
}

/// Une un usuario con una organización. Aquí viven el rol, el estado y el
/// identificador interno, porque cambian de una organización a otra.
class Membresia {
  final int id;
  final int usuarioId;
  final int organizacionId;
  final RolMembresia rol;
  final EstadoMembresia estado;
  final String identificadorInterno;

  /// Fecha en que termina una suspensión temporal (si la hay).
  final DateTime? sancionHasta;

  const Membresia({
    required this.id,
    required this.usuarioId,
    required this.organizacionId,
    required this.rol,
    required this.estado,
    required this.identificadorInterno,
    this.sancionHasta,
  });

  bool get esAdministrador => rol == RolMembresia.administrador;

  /// RF-018: un usuario suspendido o baneado no puede publicar, ofertar ni aceptar.
  bool get estaBloqueado =>
      estado == EstadoMembresia.suspendido || estado == EstadoMembresia.baneado;

  Membresia copyWith({
    EstadoMembresia? estado,
    DateTime? sancionHasta,
    bool limpiarSancionHasta = false,
  }) =>
      Membresia(
        id: id,
        usuarioId: usuarioId,
        organizacionId: organizacionId,
        rol: rol,
        estado: estado ?? this.estado,
        identificadorInterno: identificadorInterno,
        sancionHasta:
            limpiarSancionHasta ? null : (sancionHasta ?? this.sancionHasta),
      );
}
