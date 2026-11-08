"""Formas de los datos que entran y salen de la API (Pydantic)."""
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from app.models import (
    EstadoMembresia,
    EstadoNecesidad,
    EstadoOferta,
    EstadoPrestamo,
    EstadoReporte,
    Modalidad,
    Rol,
    RolMembresia,
    Sancion,
    TipoOrganizacion,
    TipoReporte,
    TipoSancion,
    UnidadCobro,
)


class _Base(BaseModel):
    # Permite construir estos esquemas directamente desde objetos ORM de SQLAlchemy.
    model_config = ConfigDict(from_attributes=True)


# ---------------- Usuarios y sesión ----------------
class UsuarioResumen(_Base):
    """Datos públicos básicos de un usuario (jamás expone contrasena_hash)."""
    id: int
    nombre: str
    iniciales: str


class UsuarioPublicoOut(UsuarioResumen):
    """Datos públicos de un usuario al consultarlo por ID."""
    correo: str


class UsuarioOut(UsuarioResumen):
    """Usuario autenticado (jamás incluye contrasena_hash)."""
    correo: str


class RegistroIn(BaseModel):
    nombre: str = Field(
        ...,
        min_length=3,
        max_length=120,
        description="Nombre completo (mínimo nombre y apellido)",
    )
    correo: str = Field(
        ...,
        min_length=5,
        max_length=160,
        description="Correo electrónico válido",
    )
    contrasena: str = Field(
        ...,
        min_length=8,
        max_length=128,
        description="Contraseña de mínimo 8 caracteres",
    )

    @field_validator("nombre")
    @classmethod
    def validar_nombre_completo(cls, valor: str) -> str:
        limpio = " ".join(valor.strip().split())
        if len(limpio.split(" ")) < 2:
            raise ValueError("Escribe tu nombre y apellido completos.")
        return limpio

    @field_validator("correo")
    @classmethod
    def validar_correo(cls, valor: str) -> str:
        limpio = valor.strip().lower()
        if "@" not in limpio or "." not in limpio.split("@")[-1]:
            raise ValueError(
                "Ese correo no parece válido. Revisa que tenga @ y dominio."
            )
        return limpio

    @field_validator("contrasena")
    @classmethod
    def validar_contrasena(cls, valor: str) -> str:
        if len(valor) < 8:
            raise ValueError("La contraseña debe tener al menos 8 caracteres.")
        return valor


class LoginIn(BaseModel):
    correo: str | None = Field(default=None, description="Correo electrónico")
    usuario: str | None = Field(default=None, description="Alias de correo")
    contrasena: str = Field(..., min_length=1, description="Contraseña")

    @model_validator(mode="after")
    def asegurar_correo(self) -> "LoginIn":
        identificador = (self.correo or self.usuario or "").strip().lower()
        if not identificador:
            raise ValueError("Debes ingresar tu correo electrónico.")
        self.correo = identificador
        return self


# ---------------- Organizaciones y Membresías ----------------
class OrganizacionOut(_Base):
    id: int
    nombre: str
    tipo: TipoOrganizacion
    codigo: str | None = None
    punto_central: str
    creada_por: int


class OrganizacionPreview(_Base):
    """Lo que se muestra al verificar un código, antes de unirse (P05)."""
    id: int
    nombre: str
    tipo: TipoOrganizacion
    codigo: str
    punto_central: str
    creada_por: int
    total_miembros: int = 0


class MembresiaOut(_Base):
    id: int
    usuario_id: int
    organizacion_id: int
    rol: RolMembresia
    estado: EstadoMembresia
    identificador_interno: str
    sancion_motivo: str | None = None
    motivo_sancion: str | None = None
    sancion_hasta: datetime | None = None
    fecha_fin_suspension: datetime | None = None
    organizacion: OrganizacionOut | None = None


class AuthOut(BaseModel):
    """Respuesta estándar de registro e inicio de sesión."""
    access_token: str
    token_type: str = "bearer"
    token: str
    usuario: UsuarioOut
    membresias: list[MembresiaOut] = Field(default_factory=list)


class SesionOut(AuthOut):
    """Alias compatible con SesionOut."""
    pass


class PerfilMeOut(_Base):
    """Respuesta de GET /api/v1/auth/me con el usuario, sus membresías y organizaciones."""
    id: int
    nombre: str
    correo: str
    iniciales: str
    usuario: UsuarioOut
    membresias: list[MembresiaOut] = Field(default_factory=list)
    organizaciones: list[OrganizacionOut] = Field(default_factory=list)


class OrganizacionCrearIn(BaseModel):
    nombre: str = Field(
        ...,
        min_length=2,
        max_length=160,
        description="Nombre de la organización",
    )
    tipo: TipoOrganizacion
    punto_central: str = Field(
        ...,
        min_length=2,
        max_length=200,
        description="Punto central de encuentro para entregas y devoluciones",
    )
    identificador_interno: str = Field(
        default="ADMIN-01",
        min_length=1,
        max_length=60,
        description="Identificador interno del creador en la organización",
    )

    @field_validator("nombre", "punto_central", "identificador_interno")
    @classmethod
    def no_vacio(cls, valor: str) -> str:
        limpio = valor.strip()
        if not limpio:
            raise ValueError("Este campo no puede estar vacío.")
        return limpio


class OrganizacionCreadaOut(_Base):
    """Respuesta al crear una organización: incluye la organización (con su código) y la membresía ADMIN."""
    id: int
    nombre: str
    tipo: TipoOrganizacion
    codigo: str
    punto_central: str
    creada_por: int
    membresia: MembresiaOut | None = None


class UnirseOrgIn(BaseModel):
    """Cuerpo para POST /api/v1/organizations/{org_id}/join (RF-004 paso 2)."""
    identificador_interno: str = Field(
        ...,
        min_length=1,
        max_length=60,
        description="Código estudiantil, código de empleado o número de apartamento",
    )
    codigo: str | None = Field(default=None, max_length=5)

    @field_validator("identificador_interno")
    @classmethod
    def validar_identificador(cls, valor: str) -> str:
        limpio = valor.strip()
        if not limpio:
            raise ValueError("Escribe tu identificador dentro de la organización.")
        return limpio


class UnirseIn(BaseModel):
    """Cuerpo para unirse directamente con código + identificador_interno."""
    codigo: str = Field(
        ...,
        min_length=5,
        max_length=5,
        description="Código de 5 caracteres de la organización",
    )
    identificador_interno: str = Field(
        ...,
        min_length=1,
        max_length=60,
        description="Identificador interno del miembro",
    )

    @field_validator("codigo")
    @classmethod
    def limpiar_codigo(cls, valor: str) -> str:
        limpio = valor.strip().upper()
        if len(limpio) != 5:
            raise ValueError("El código de la organización debe tener 5 caracteres.")
        return limpio

    @field_validator("identificador_interno")
    @classmethod
    def limpiar_identificador(cls, valor: str) -> str:
        limpio = valor.strip()
        if not limpio:
            raise ValueError("Escribe tu identificador dentro de la organización.")
        return limpio


class PuntoCentralIn(BaseModel):
    punto_central: str = Field(
        ...,
        min_length=2,
        max_length=200,
        description="Nuevo punto central de encuentro",
    )

    @field_validator("punto_central")
    @classmethod
    def validar_punto(cls, valor: str) -> str:
        limpio = valor.strip()
        if not limpio:
            raise ValueError("Escribe el punto central de entrega.")
        return limpio


class MiembroOut(BaseModel):
    id: int
    membresia_id: int
    usuario_id: int
    organizacion_id: int
    usuario: UsuarioResumen
    nombre: str
    correo: str
    iniciales: str
    rol: RolMembresia
    estado: EstadoMembresia
    identificador_interno: str
    sancion_motivo: str | None = None
    sancion_hasta: datetime | None = None
    fecha_fin_suspension: datetime | None = None


# ---------------- Necesidades y ofertas ----------------
class NecesidadCrearIn(BaseModel):
    organizacion_id: int | None = None
    objeto: str = Field(..., min_length=3, max_length=160)
    descripcion: str = Field(..., min_length=5, max_length=1000)
    fecha_inicio: datetime
    fecha_fin: datetime

    @field_validator("objeto")
    @classmethod
    def validar_objeto(cls, valor: str) -> str:
        limpio = valor.strip()
        if len(limpio) < 3:
            raise ValueError("Escribe el nombre del objeto (mínimo 3 caracteres).")
        return limpio

    @field_validator("descripcion")
    @classmethod
    def validar_descripcion(cls, valor: str) -> str:
        limpio = valor.strip()
        if len(limpio) < 5:
            raise ValueError("Añade una breve descripción (mínimo 5 caracteres).")
        return limpio

    @model_validator(mode="after")
    def validar_fechas(self) -> "NecesidadCrearIn":
        hoy = datetime.now().date()
        if self.fecha_inicio.date() < hoy:
            raise ValueError("La fecha de inicio no puede estar en el pasado.")
        if self.fecha_fin < self.fecha_inicio:
            raise ValueError(
                "La fecha de devolución debe ser igual o posterior a la de inicio."
            )
        return self


class NecesidadOut(_Base):
    id: int
    organizacion_id: int
    solicitante_id: int
    objeto: str
    descripcion: str
    fecha_inicio: datetime
    fecha_fin: datetime
    estado: EstadoNecesidad
    creada_en: datetime | None = None
    solicitante: UsuarioResumen
    ofertas_pendientes: int = 0
    mi_oferta_id: int | None = None


class OfertaCrearIn(BaseModel):
    necesidad_id: int | None = None
    modalidad: Modalidad
    precio: float | None = Field(default=None)
    unidad_cobro: UnidadCobro | None = None
    fecha_entrega: datetime | None = None

    @model_validator(mode="after")
    def validar_condiciones(self) -> "OfertaCrearIn":
        if self.modalidad == Modalidad.GRATIS:
            self.precio = None
            self.unidad_cobro = None
        else:
            if self.precio is None or self.precio <= 0:
                raise ValueError(
                    "Si eliges alquiler, indica un precio mayor a cero."
                )
            if self.unidad_cobro is None:
                raise ValueError(
                    "Indica si el cobro es por hora o por día."
                )
        return self


OfferCreate = OfertaCrearIn


class OfertaOut(_Base):
    id: int
    necesidad_id: int
    prestador_id: int
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
    oferta_id: int
    necesidad_id: int
    organizacion_id: int
    solicitante_id: int
    prestador_id: int
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
    accion_pendiente: str | None = None
    accion_clave: str | None = None


class ReporteCrearIn(BaseModel):
    tipo: TipoReporte
    descripcion: str = Field(..., min_length=10, max_length=1000)

    @field_validator("descripcion")
    @classmethod
    def validar_descripcion_reporte(cls, valor: str) -> str:
        limpio = valor.strip()
        if len(limpio) < 10:
            raise ValueError(
                "Escribe al menos 10 caracteres explicando qué pasó."
            )
        return limpio


class ResolverReporteIn(BaseModel):
    sancion: TipoSancion
    nota_resolucion: str | None = Field(default=None)
    nota: str | None = Field(default=None)
    sancion_hasta: datetime | None = Field(default=None)
    suspension_hasta: datetime | None = Field(default=None)
    fecha_fin_suspension: datetime | None = Field(default=None)

    @field_validator("sancion", mode="before")
    @classmethod
    def normalizar_sancion(cls, valor):
        if isinstance(valor, str):
            v = valor.strip().upper()
            if v in ("SUSPENSION_TEMPORAL", "SUSPENSION"):
                return TipoSancion.SUSPENSION
            if v in ("BANEO_PERMANENTE", "BANEO"):
                return TipoSancion.BANEO
            if v == "ADVERTENCIA":
                return TipoSancion.ADVERTENCIA
        return valor

    @model_validator(mode="after")
    def validar_resolucion(self) -> "ResolverReporteIn":
        texto_nota = (self.nota_resolucion or self.nota or "").strip()
        if len(texto_nota) < 3:
            raise ValueError("Debes escribir una nota de resolución.")
        self.nota_resolucion = texto_nota
        self.nota = texto_nota

        fecha_fin = (
            self.sancion_hasta
            or self.suspension_hasta
            or self.fecha_fin_suspension
        )
        self.sancion_hasta = fecha_fin
        self.suspension_hasta = fecha_fin
        self.fecha_fin_suspension = fecha_fin

        if self.sancion == TipoSancion.SUSPENSION and fecha_fin is None:
            raise ValueError(
                "Elige hasta qué fecha estará suspendido el miembro."
            )
        return self


class ReporteOut(_Base):
    id: int
    prestamo_id: int
    organizacion_id: int
    reportante_id: int
    reportado_id: int
    tipo: TipoReporte
    descripcion: str
    estado: EstadoReporte
    creado_en: datetime
    sancion: TipoSancion | None
    nota_resolucion: str | None
    admin_id: int | None = None
    admin_resolutor_id: int | None = None
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
