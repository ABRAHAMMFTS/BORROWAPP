"""Formas de los datos que entran y salen de la API (Pydantic)."""
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models import (EstadoMembresia, EstadoNecesidad, EstadoOferta, EstadoPrestamo,
                        EstadoReporte, Modalidad, Rol, Sancion, TipoOrganizacion,
                        TipoReporte, UnidadCobro)


class _Base(BaseModel):
    # Permite construir estos esquemas directamente desde objetos de la base.
    model_config = ConfigDict(from_attributes=True)


# ---------------- Usuarios y sesión ----------------
class UsuarioResumen(_Base):
    id: int
    nombre: str
    iniciales: str


class UsuarioOut(UsuarioResumen):
    correo: str


class RegistroIn(BaseModel):
    nombre: str
    correo: str
    contrasena: str


class LoginIn(BaseModel):
    correo: str
    contrasena: str


# ---------------- Organizaciones ----------------
class OrganizacionOut(_Base):
    id: int
    nombre: str
    tipo: TipoOrganizacion
    # El código solo lo ve el administrador de esa organización.
    codigo: str | None = None
    punto_central: str
    creada_por: int


class OrganizacionPreview(_Base):
    """Lo que se muestra al escribir un código, antes de unirse (P05)."""
    id: int
    nombre: str
    tipo: TipoOrganizacion
    punto_central: str
    total_miembros: int


class MembresiaOut(_Base):
    id: int
    rol: Rol
    estado: EstadoMembresia
    identificador_interno: str
    sancion_hasta: datetime | None
    organizacion: OrganizacionOut


class SesionOut(BaseModel):
    token: str
    usuario: UsuarioOut
    membresias: list[MembresiaOut]


class OrganizacionCrearIn(BaseModel):
    nombre: str
    tipo: TipoOrganizacion
    punto_central: str
    identificador_interno: str


class UnirseIn(BaseModel):
    codigo: str
    identificador_interno: str


class PuntoCentralIn(BaseModel):
    punto_central: str


class MiembroOut(BaseModel):
    usuario: UsuarioResumen
    correo: str
    membresia_id: int
    rol: Rol
    estado: EstadoMembresia
    identificador_interno: str
    sancion_hasta: datetime | None


# ---------------- Necesidades y ofertas ----------------
class NecesidadCrearIn(BaseModel):
    objeto: str
    descripcion: str
    fecha_inicio: datetime
    fecha_fin: datetime


class NecesidadOut(_Base):
    id: int
    organizacion_id: int
    objeto: str
    descripcion: str
    fecha_inicio: datetime
    fecha_fin: datetime
    estado: EstadoNecesidad
    solicitante: UsuarioResumen
    # Cuántas ofertas pendientes tiene (para avisar al solicitante).
    ofertas_pendientes: int = 0
    # Si el usuario actual ya ofreció, id de su oferta pendiente.
    mi_oferta_id: int | None = None


class OfertaCrearIn(BaseModel):
    modalidad: Modalidad
    precio: float | None = Field(default=None)
    unidad_cobro: UnidadCobro | None = None
    fecha_entrega: datetime


class OfertaOut(_Base):
    id: int
    necesidad_id: int
    modalidad: Modalidad
    precio: float | None
    unidad_cobro: UnidadCobro | None
    fecha_entrega: datetime
    estado: EstadoOferta
    prestador: UsuarioResumen
    total_calculado: float = 0


# ---------------- Préstamos y reportes ----------------
class PrestamoOut(_Base):
    id: int
    necesidad_id: int
    organizacion_id: int
    objeto: str
    fecha_inicio: datetime
    fecha_fin: datetime
    modalidad: Modalidad
    precio_total: float
    punto_central: str
    estado: EstadoPrestamo
    en_conflicto: bool
    vencido: bool = False
    entrega_prestador_en: datetime | None
    entrega_solicitante_en: datetime | None
    devolucion_solicitante_en: datetime | None
    devolucion_prestador_en: datetime | None
    solicitante: UsuarioResumen
    prestador: UsuarioResumen
    # Texto de la franja amarilla ("Te toca confirmar la recepción") o null.
    accion_pendiente: str | None = None
    # Qué botón de acción corresponde al usuario actual (o null).
    accion_clave: str | None = None


class ReporteCrearIn(BaseModel):
    tipo: TipoReporte
    descripcion: str


class ResolverReporteIn(BaseModel):
    sancion: Sancion
    nota: str
    suspension_hasta: datetime | None = None


class ReporteOut(_Base):
    id: int
    prestamo_id: int
    organizacion_id: int
    tipo: TipoReporte
    descripcion: str
    estado: EstadoReporte
    creado_en: datetime
    sancion: Sancion | None
    nota_resolucion: str | None
    resuelto_en: datetime | None
    reportante: UsuarioResumen
    reportado: UsuarioResumen
    objeto: str = ""


class HistorialItem(BaseModel):
    tipo: str  # "necesidad", "oferta" o "prestamo"
    papel: str  # "SOLICITANTE" o "PRESTADOR"
    referencia_id: int
    titulo: str
    estado: str
    fecha: datetime
    monto: float | None = None
