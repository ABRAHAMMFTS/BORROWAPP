"""Endpoints de Préstamos y máquina de estados de 4 pasos (RF-011, RF-012, RF-013)."""
from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api import deps
from app.models import (
    EstadoNecesidad,
    EstadoPrestamo,
    Membresia,
    Necesidad,
    Prestamo,
    Usuario,
)
from app.schemas import PrestamoOut, UsuarioResumen

router = APIRouter()


def _accion_pendiente_prestamo(
    p: Prestamo, usuario_id: int
) -> tuple[str | None, str | None]:
    """Calcula el texto de acción pendiente y la clave de acción para el usuario."""
    if p.estado == EstadoPrestamo.CONFIRMADO and usuario_id == p.prestador_id:
        return ("Te toca marcar como entregado", "marcar_entregado")
    if (
        p.estado == EstadoPrestamo.ENTREGA_PENDIENTE
        and usuario_id == p.solicitante_id
    ):
        return ("Te toca confirmar que lo recibiste", "confirmar_recibido")
    if p.estado == EstadoPrestamo.ACTIVO and usuario_id == p.solicitante_id:
        return ("Te toca marcar como devuelto", "marcar_devuelto")
    if (
        p.estado == EstadoPrestamo.DEVOLUCION_PENDIENTE
        and usuario_id == p.prestador_id
    ):
        return ("Te toca confirmar la devolución", "confirmar_devolucion")
    return (None, None)


def serializar_prestamo(p: Prestamo, usuario_id: int) -> PrestamoOut:
    """Convierte un Prestamo ORM en PrestamoOut calculando vencido y acción pendiente."""
    accion_texto, accion_clave = _accion_pendiente_prestamo(p, usuario_id)
    vencido = (
        p.estado != EstadoPrestamo.FINALIZADO
        and datetime.now() > p.fecha_fin
    )
    return PrestamoOut(
        id=p.id,
        oferta_id=p.oferta_id,
        necesidad_id=p.necesidad_id,
        organizacion_id=p.organizacion_id,
        solicitante_id=p.solicitante_id,
        prestador_id=p.prestador_id,
        objeto=p.objeto,
        fecha_inicio=p.fecha_inicio,
        fecha_fin=p.fecha_fin,
        modalidad=p.modalidad,
        precio_total=p.precio_total,
        punto_central=p.punto_central,
        estado=p.estado,
        en_conflicto=p.en_conflicto,
        vencido=vencido,
        entrega_prestador_en=p.entrega_prestador_en,
        entrega_solicitante_en=p.entrega_solicitante_en,
        devolucion_solicitante_en=p.devolucion_solicitante_en,
        devolucion_prestador_en=p.devolucion_prestador_en,
        solicitante=UsuarioResumen.model_validate(p.solicitante),
        prestador=UsuarioResumen.model_validate(p.prestador),
        accion_pendiente=accion_texto,
        accion_clave=accion_clave,
    )


def _obtener_prestamo_o_404(db: Session, loan_id: int) -> Prestamo:
    prestamo = db.query(Prestamo).filter(Prestamo.id == loan_id).first()
    if prestamo is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El préstamo no existe.",
        )
    return prestamo


@router.get(
    "/organizations/{org_id}/loans",
    response_model=list[PrestamoOut],
    status_code=status.HTTP_200_OK,
    summary="Listar préstamos de una organización",
)
def listar_prestamos_organizacion(
    org_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Devuelve los préstamos de la organización ordenados del más reciente al más antiguo."""
    deps.exigir_miembro(db, current_user.id, org_id)
    filas = (
        db.query(Prestamo)
        .filter(Prestamo.organizacion_id == org_id)
        .order_by(Prestamo.id.desc())
        .all()
    )
    return [serializar_prestamo(p, current_user.id) for p in filas]


@router.get(
    "/loans",
    response_model=list[PrestamoOut],
    status_code=status.HTTP_200_OK,
    summary="Listar préstamos filtrando por organización",
)
@router.get(
    "/loans/",
    response_model=list[PrestamoOut],
    status_code=status.HTTP_200_OK,
    include_in_schema=False,
)
def listar_prestamos(
    organizacion_id: int | None = Query(default=None),
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Lista los préstamos de organizacion_id o de las organizaciones del usuario."""
    if organizacion_id is not None:
        deps.exigir_miembro(db, current_user.id, organizacion_id)
        filas = (
            db.query(Prestamo)
            .filter(Prestamo.organizacion_id == organizacion_id)
            .order_by(Prestamo.id.desc())
            .all()
        )
        return [serializar_prestamo(p, current_user.id) for p in filas]

    org_ids = [
        m.organizacion_id
        for m in db.query(Membresia)
        .filter(Membresia.usuario_id == current_user.id)
        .all()
    ]
    if not org_ids:
        return []
    filas = (
        db.query(Prestamo)
        .filter(Prestamo.organizacion_id.in_(org_ids))
        .order_by(Prestamo.id.desc())
        .all()
    )
    return [serializar_prestamo(p, current_user.id) for p in filas]


@router.get(
    "/loans/{loan_id}",
    response_model=PrestamoOut,
    status_code=status.HTTP_200_OK,
    summary="Obtener detalle de un préstamo",
)
def obtener_prestamo(
    loan_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Devuelve el detalle de un préstamo verificando que el usuario pertenezca a la organización."""
    prestamo = _obtener_prestamo_o_404(db, loan_id)
    deps.exigir_miembro(db, current_user.id, prestamo.organizacion_id)
    return serializar_prestamo(prestamo, current_user.id)


@router.post(
    "/loans/{loan_id}/mark-delivered",
    response_model=PrestamoOut,
    status_code=status.HTTP_200_OK,
    summary="Paso 1: El prestador marca el objeto como entregado (RF-012)",
)
def marcar_entregado(
    loan_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Solo el prestador cuando el préstamo está en CONFIRMADO. Pasa a ENTREGA_PENDIENTE."""
    prestamo = _obtener_prestamo_o_404(db, loan_id)
    if prestamo.prestador_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el prestador puede marcar el objeto como entregado.",
        )
    if prestamo.estado != EstadoPrestamo.CONFIRMADO:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El préstamo debe estar en estado CONFIRMADO para marcar la entrega.",
        )

    prestamo.entrega_prestador_en = datetime.now()
    prestamo.estado = EstadoPrestamo.ENTREGA_PENDIENTE
    db.add(prestamo)
    db.commit()
    db.refresh(prestamo)
    return serializar_prestamo(prestamo, current_user.id)


@router.post(
    "/loans/{loan_id}/confirm-received",
    response_model=PrestamoOut,
    status_code=status.HTTP_200_OK,
    summary="Paso 2: El solicitante confirma la recepción del objeto (RF-012)",
)
def confirmar_recibido(
    loan_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Solo el solicitante cuando el préstamo está en ENTREGA_PENDIENTE. Pasa a ACTIVO."""
    prestamo = _obtener_prestamo_o_404(db, loan_id)
    if prestamo.solicitante_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el solicitante puede confirmar que recibió el objeto.",
        )
    if prestamo.estado != EstadoPrestamo.ENTREGA_PENDIENTE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Primero el prestador debe marcar que entregó el objeto.",
        )

    prestamo.entrega_solicitante_en = datetime.now()
    prestamo.estado = EstadoPrestamo.ACTIVO
    db.add(prestamo)
    db.commit()
    db.refresh(prestamo)
    return serializar_prestamo(prestamo, current_user.id)


@router.post(
    "/loans/{loan_id}/mark-returned",
    response_model=PrestamoOut,
    status_code=status.HTTP_200_OK,
    summary="Paso 3: El solicitante marca el objeto como devuelto (RF-013)",
)
def marcar_devuelto(
    loan_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Solo el solicitante cuando el préstamo está en ACTIVO. Pasa a DEVOLUCION_PENDIENTE."""
    prestamo = _obtener_prestamo_o_404(db, loan_id)
    if prestamo.solicitante_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el solicitante puede marcar el objeto como devuelto.",
        )
    if prestamo.estado != EstadoPrestamo.ACTIVO:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El préstamo debe estar ACTIVO para marcar la devolución.",
        )

    prestamo.devolucion_solicitante_en = datetime.now()
    prestamo.estado = EstadoPrestamo.DEVOLUCION_PENDIENTE
    db.add(prestamo)
    db.commit()
    db.refresh(prestamo)
    return serializar_prestamo(prestamo, current_user.id)


@router.post(
    "/loans/{loan_id}/confirm-returned",
    response_model=PrestamoOut,
    status_code=status.HTTP_200_OK,
    summary="Paso 4: El prestador confirma la devolución del objeto (RF-013)",
)
def confirmar_devolucion(
    loan_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Solo el prestador cuando está en DEVOLUCION_PENDIENTE. Pasa el préstamo a
    FINALIZADO y la necesidad asociada a CERRADA."""
    prestamo = _obtener_prestamo_o_404(db, loan_id)
    if prestamo.prestador_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el prestador puede confirmar que recibió el objeto de vuelta.",
        )
    if prestamo.estado != EstadoPrestamo.DEVOLUCION_PENDIENTE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Primero el solicitante debe marcar que devolvió el objeto.",
        )

    prestamo.devolucion_prestador_en = datetime.now()
    prestamo.estado = EstadoPrestamo.FINALIZADO
    db.add(prestamo)

    necesidad = (
        db.query(Necesidad)
        .filter(Necesidad.id == prestamo.necesidad_id)
        .first()
    )
    if necesidad is not None:
        necesidad.estado = EstadoNecesidad.CERRADA
        db.add(necesidad)

    db.commit()
    db.refresh(prestamo)
    return serializar_prestamo(prestamo, current_user.id)

