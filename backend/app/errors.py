"""Errores de negocio. Los routers los convierten en respuestas HTTP con un
mensaje que la app muestra tal cual al usuario."""


class ReglaNegocio(Exception):
    """Se rompió una regla del SRS (HTTP 400)."""

    def __init__(self, mensaje: str, codigo: int = 400):
        super().__init__(mensaje)
        self.mensaje = mensaje
        self.codigo = codigo


class NoEncontrado(ReglaNegocio):
    def __init__(self, mensaje: str):
        super().__init__(mensaje, 404)


class SinPermiso(ReglaNegocio):
    def __init__(self, mensaje: str):
        super().__init__(mensaje, 403)
