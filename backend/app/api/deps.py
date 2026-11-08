"""Dependencias y 'El Portero' de autenticación y autorización por membresía."""
from datetime import datetime, timezone
from typing import Generator

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt
from sqlalchemy.orm import Session

from app.core.config import ALGORITMO_JWT, CLAVE_SECRETA
from app.core.database import SessionLocal, get_db
from app.models import (
    EstadoMembresia,
    EstadoReporte,
    Membresia,
    Reporte,
    Rol,
    Usuario,
)

# Lector de token Bearer según la Guía API Segunda Parte.
leer_token = HTTPBearer(auto_error=False)


def obtener_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def usuario_actual(
    credenciales: HTTPAuthorizationCredentials | None = Depends(leer_token),
    db: Session = Depends(get_db),
) -> Usuario:
    """Portero de autenticación: valida el JWT Bearer y devuelve el Usuario actual."""
    if credenciales is None or not credenciales.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Falta el token.",
        )

    token = credenciales.credentials
    try:
        datos = jwt.decode(token, CLAVE_SECRETA, algorithms=[ALGORITMO_JWT])
        usuario_id = int(datos["sub"])
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El token venció. Vuelve a iniciar sesión.",
        )
    except (jwt.InvalidTokenError, KeyError, ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido.",
        )

    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El usuario del token ya no existe.",
        )
    return usuario


# Alias para compatibilidad con rutas que importen get_current_user.
get_current_user = usuario_actual


# ==============================================================================
# PORTEROS DE AUTORIZACIÓN POR MEMBRESÍA (Usuario + Organización)
# ==============================================================================


def restituir_suspension_si_vencio(db: Session, membresia: Membresia) -> Membresia:
    """RF-018: Si el miembro estaba SUSPENDIDO y su fecha_fin_suspension ya venció,
    vuelve automáticamente al estado ACTIVO."""
    fin = membresia.fecha_fin_suspension
    if membresia.estado == EstadoMembresia.SUSPENDIDO and fin is not None:
        ahora = (
            datetime.now(timezone.utc)
            if fin.tzinfo is not None
            else datetime.now()
        )
        if ahora > fin:
            membresia.estado = EstadoMembresia.ACTIVO
            membresia.fecha_fin_suspension = None
            db.add(membresia)
            db.commit()
            db.refresh(membresia)
    return membresia


def _ultimo_motivo_sancion(
    db: Session, membresia: Membresia
) -> str | None:
    """Obtiene el motivo de sanción de la membresía o del último reporte resuelto."""
    if membresia.sancion_motivo and membresia.sancion_motivo.strip():
        return membresia.sancion_motivo.strip()
    reporte = (
        db.query(Reporte)
        .filter(
            Reporte.reportado_id == membresia.usuario_id,
            Reporte.organizacion_id == membresia.organizacion_id,
            Reporte.estado == EstadoReporte.RESUELTO,
            Reporte.nota_resolucion.isnot(None),
        )
        .order_by(Reporte.resuelto_en.desc(), Reporte.id.desc())
        .first()
    )
    if reporte and reporte.nota_resolucion and reporte.nota_resolucion.strip():
        return reporte.nota_resolucion.strip()
    return None


def exigir_miembro(
    db: Session, usuario_id: int, organizacion_id: int
) -> Membresia:
    """Verifica que el usuario pertenezca a la organización y restituye suspensiones vencidas."""
    membresia = (
        db.query(Membresia)
        .filter(
            Membresia.usuario_id == usuario_id,
            Membresia.organizacion_id == organizacion_id,
        )
        .first()
    )
    if membresia is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No perteneces a esta organización, así que no puedes realizar esta acción.",
        )
    return restituir_suspension_si_vencio(db, membresia)


def exigir_miembro_activo_no_bloqueado(
    db: Session, usuario_id: int, organizacion_id: int
) -> Membresia:
    """RF-018: Verifica que el miembro pertenezca a la organización y NO esté
    SUSPENDIDO ni BANEADO. Si lo está, lanza 403 con el motivo y fecha de fin."""
    membresia = exigir_miembro(db, usuario_id, organizacion_id)

    if membresia.estado in (EstadoMembresia.SUSPENDIDO, EstadoMembresia.BANEADO):
        motivo = _ultimo_motivo_sancion(db, membresia)
        texto_motivo = f" Motivo: {motivo}." if motivo else ""

        if membresia.estado == EstadoMembresia.BANEADO:
            detalle = (
                "Fuiste retirado de esta organización de forma permanente."
                f"{texto_motivo} No puedes publicar, ofrecer ni aceptar en ella."
            )
        else:
            fin = membresia.fecha_fin_suspension
            hasta_str = f" hasta el {fin.strftime('%d/%m/%Y')}" if fin else ""
            detalle = (
                f"Estás suspendido en esta organización{hasta_str}.{texto_motivo} "
                "No puedes publicar, ofrecer ni aceptar mientras tanto. "
                "Tus otras organizaciones no se ven afectadas."
            )

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=detalle,
        )

    return membresia


def exigir_admin_organizacion(
    db: Session, usuario_id: int, organizacion_id: int
) -> Membresia:
    """Verifica que el usuario sea ADMINISTRADOR de esa organización."""
    membresia = (
        db.query(Membresia)
        .filter(
            Membresia.usuario_id == usuario_id,
            Membresia.organizacion_id == organizacion_id,
        )
        .first()
    )
    if membresia is None or membresia.rol != Rol.ADMINISTRADOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el administrador de esta organización puede realizar esta acción.",
        )
    return restituir_suspension_si_vencio(db, membresia)
