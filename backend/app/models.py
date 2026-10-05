"""Tablas de PostgreSQL (SRS sección 4.2).

Siete entidades: Usuario, Organizacion, Membresia, Necesidad, Oferta,
Prestamo y Reporte. Las reglas de integridad de la sección 4.3 que puede
cumplir la base de datos se declaran aquí como restricciones únicas.
"""
import enum
from datetime import datetime

from sqlalchemy import (Boolean, DateTime, Enum, Float, ForeignKey, Index, Integer,
                        String, Text, UniqueConstraint, text)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


# ---------------- Listas (enumeraciones) ----------------
class TipoOrganizacion(str, enum.Enum):
    UNIVERSIDAD = "UNIVERSIDAD"
    EMPRESA = "EMPRESA"
    CONJUNTO_RESIDENCIAL = "CONJUNTO_RESIDENCIAL"


class Rol(str, enum.Enum):
    ADMINISTRADOR = "ADMINISTRADOR"
    MIEMBRO = "MIEMBRO"


class EstadoMembresia(str, enum.Enum):
    ACTIVO = "ACTIVO"
    ADVERTIDO = "ADVERTIDO"
    SUSPENDIDO = "SUSPENDIDO"
    BANEADO = "BANEADO"


class EstadoNecesidad(str, enum.Enum):
    BUSCANDO_PRESTADOR = "BUSCANDO_PRESTADOR"
    CON_PRESTAMO_CONFIRMADO = "CON_PRESTAMO_CONFIRMADO"
    CERRADA = "CERRADA"


class Modalidad(str, enum.Enum):
    GRATIS = "GRATIS"
    ALQUILER = "ALQUILER"


class UnidadCobro(str, enum.Enum):
    HORA = "HORA"
    DIA = "DIA"


class EstadoOferta(str, enum.Enum):
    PENDIENTE = "PENDIENTE"
    ACEPTADA = "ACEPTADA"
    RECHAZADA = "RECHAZADA"
    CERRADA = "CERRADA"


class EstadoPrestamo(str, enum.Enum):
    CONFIRMADO = "CONFIRMADO"
    ENTREGA_PENDIENTE = "ENTREGA_PENDIENTE"
    ACTIVO = "ACTIVO"
    DEVOLUCION_PENDIENTE = "DEVOLUCION_PENDIENTE"
    FINALIZADO = "FINALIZADO"


class TipoReporte(str, enum.Enum):
    NO_DEVUELTO = "NO_DEVUELTO"
    DANADO = "DANADO"
    NO_ASISTIO = "NO_ASISTIO"


class EstadoReporte(str, enum.Enum):
    PENDIENTE = "PENDIENTE"
    RESUELTO = "RESUELTO"


class Sancion(str, enum.Enum):
    ADVERTENCIA = "ADVERTENCIA"
    SUSPENSION = "SUSPENSION"
    BANEO = "BANEO"


def _enum(clase):
    """Guarda el enum como texto (más fácil de leer en la base de datos)."""
    return Enum(clase, native_enum=False, length=40)


# ---------------- Tablas ----------------
class Usuario(Base):
    """La persona con cuenta. Sus datos no dependen de ninguna organización."""
    __tablename__ = "usuarios"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    nombre: Mapped[str] = mapped_column(String(120))
    correo: Mapped[str] = mapped_column(String(160), unique=True, index=True)  # único
    contrasena_hash: Mapped[str] = mapped_column(String(255))  # bcrypt

    @property
    def iniciales(self) -> str:
        partes = self.nombre.split()
        if len(partes) == 1:
            return partes[0][0].upper()
        return (partes[0][0] + partes[-1][0]).upper()


class Organizacion(Base):
    """La comunidad cerrada. De aquí sale el código que usan los demás."""
    __tablename__ = "organizaciones"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    nombre: Mapped[str] = mapped_column(String(160))
    tipo: Mapped[TipoOrganizacion] = mapped_column(_enum(TipoOrganizacion))
    codigo: Mapped[str] = mapped_column(String(5), unique=True, index=True)  # único
    punto_central: Mapped[str] = mapped_column(String(200))
    creada_por: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))


class Membresia(Base):
    """Une usuario y organización. Aquí viven rol, estado e identificador."""
    __tablename__ = "membresias"
    # Un usuario no puede tener dos membresías en la misma organización.
    __table_args__ = (UniqueConstraint("usuario_id", "organizacion_id", name="uq_membresia"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    usuario_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"), index=True)
    organizacion_id: Mapped[int] = mapped_column(ForeignKey("organizaciones.id"), index=True)
    rol: Mapped[Rol] = mapped_column(_enum(Rol))
    estado: Mapped[EstadoMembresia] = mapped_column(_enum(EstadoMembresia), default=EstadoMembresia.ACTIVO)
    identificador_interno: Mapped[str] = mapped_column(String(60))
    sancion_hasta: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    usuario: Mapped[Usuario] = relationship()
    organizacion: Mapped[Organizacion] = relationship()


class Necesidad(Base):
    """Lo que un usuario pide dentro de una organización."""
    __tablename__ = "necesidades"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    organizacion_id: Mapped[int] = mapped_column(ForeignKey("organizaciones.id"), index=True)
    solicitante_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    objeto: Mapped[str] = mapped_column(String(160))
    descripcion: Mapped[str] = mapped_column(Text)
    fecha_inicio: Mapped[datetime] = mapped_column(DateTime)
    fecha_fin: Mapped[datetime] = mapped_column(DateTime)
    estado: Mapped[EstadoNecesidad] = mapped_column(
        _enum(EstadoNecesidad), default=EstadoNecesidad.BUSCANDO_PRESTADOR)
    creada_en: Mapped[datetime] = mapped_column(DateTime, default=datetime.now)

    solicitante: Mapped[Usuario] = relationship()


class Oferta(Base):
    """La respuesta de un miembro. Las condiciones las define el prestador."""
    __tablename__ = "ofertas"
    # Una necesidad nunca tiene dos ofertas ACEPTADA (regla 4.3 y RNF-007).
    # Índice único parcial: solo cuenta las filas que están aceptadas.
    __table_args__ = (
        Index("uq_una_oferta_aceptada", "necesidad_id", unique=True,
              postgresql_where=text("estado = 'ACEPTADA'"), sqlite_where=text("estado = 'ACEPTADA'")),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    necesidad_id: Mapped[int] = mapped_column(ForeignKey("necesidades.id"), index=True)
    prestador_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    modalidad: Mapped[Modalidad] = mapped_column(_enum(Modalidad))
    precio: Mapped[float | None] = mapped_column(Float, nullable=True)
    unidad_cobro: Mapped[UnidadCobro | None] = mapped_column(_enum(UnidadCobro), nullable=True)
    fecha_entrega: Mapped[datetime] = mapped_column(DateTime)
    estado: Mapped[EstadoOferta] = mapped_column(_enum(EstadoOferta), default=EstadoOferta.PENDIENTE)

    prestador: Mapped[Usuario] = relationship()


class Prestamo(Base):
    """Nace al aceptar una oferta. Guarda una copia de las condiciones."""
    __tablename__ = "prestamos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    oferta_id: Mapped[int] = mapped_column(ForeignKey("ofertas.id"), unique=True)  # 1 oferta = 1 préstamo
    necesidad_id: Mapped[int] = mapped_column(ForeignKey("necesidades.id"))
    organizacion_id: Mapped[int] = mapped_column(ForeignKey("organizaciones.id"), index=True)
    solicitante_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    prestador_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    objeto: Mapped[str] = mapped_column(String(160))
    fecha_inicio: Mapped[datetime] = mapped_column(DateTime)
    fecha_fin: Mapped[datetime] = mapped_column(DateTime)
    modalidad: Mapped[Modalidad] = mapped_column(_enum(Modalidad))
    precio_total: Mapped[float] = mapped_column(Float, default=0)
    punto_central: Mapped[str] = mapped_column(String(200))  # copia: no cambia después
    estado: Mapped[EstadoPrestamo] = mapped_column(_enum(EstadoPrestamo), default=EstadoPrestamo.CONFIRMADO)
    en_conflicto: Mapped[bool] = mapped_column(Boolean, default=False)
    entrega_prestador_en: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    entrega_solicitante_en: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    devolucion_solicitante_en: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    devolucion_prestador_en: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    solicitante: Mapped[Usuario] = relationship(foreign_keys=[solicitante_id])
    prestador: Mapped[Usuario] = relationship(foreign_keys=[prestador_id])


class Reporte(Base):
    """Un problema con un préstamo y lo que decidió el administrador."""
    __tablename__ = "reportes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    prestamo_id: Mapped[int] = mapped_column(ForeignKey("prestamos.id"), index=True)
    organizacion_id: Mapped[int] = mapped_column(ForeignKey("organizaciones.id"), index=True)
    reportante_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    reportado_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"))
    tipo: Mapped[TipoReporte] = mapped_column(_enum(TipoReporte))
    descripcion: Mapped[str] = mapped_column(Text)
    estado: Mapped[EstadoReporte] = mapped_column(_enum(EstadoReporte), default=EstadoReporte.PENDIENTE)
    creado_en: Mapped[datetime] = mapped_column(DateTime, default=datetime.now)
    # Se llenan solo al resolver.
    sancion: Mapped[Sancion | None] = mapped_column(_enum(Sancion), nullable=True)
    nota_resolucion: Mapped[str | None] = mapped_column(Text, nullable=True)
    admin_id: Mapped[int | None] = mapped_column(ForeignKey("usuarios.id"), nullable=True)
    resuelto_en: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    reportante: Mapped[Usuario] = relationship(foreign_keys=[reportante_id])
    reportado: Mapped[Usuario] = relationship(foreign_keys=[reportado_id])
    prestamo: Mapped[Prestamo] = relationship()
