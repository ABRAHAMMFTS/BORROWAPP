/// Error que lanzan los servicios cuando se rompe una regla del negocio
/// (SRS 3.4). El mensaje ya está escrito para mostrarse tal cual al usuario.
class ReglaNegocioException implements Exception {
  final String mensaje;
  const ReglaNegocioException(this.mensaje);

  @override
  String toString() => mensaje;
}
