"""Endpoints de Reportes de Incumplimiento y Sanciones Disciplinarias (RF-014, RF-016, RF-017)."""
from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api import deps
from app.api.routes.auth import serializar_membresia
from app.models import (
    EstadoMembresia,
    EstadoPrestamo,
    EstadoReporte,
    Membresia,
    Prestamo,
    Reporte,
    Sancion,
    Usuario,
)
from app.schemas import (
    MembresiaOut,
    ReporteCrearIn,
    ReporteOut,
    ResolverReporteIn,
    UsuarioResumen,
)

router = APIRouter()


def serializar_reporte(r: Reporte) -> ReporteOut:
    """Convierte un Reporte ORM a ReporteOut incluyendo el objeto del préstamo."""
    objeto_str = r.prestamo.objeto if r.prestamo is not None else ""
    return ReporteOut(
        id=r.id,
        prestamo_id=r.prestamo_id,
        organizacion_id=r.organizacion_id,
        reportante_id=r.reportante_id,
        reportado_id=r.reportado_id,
        tipo=r.tipo,
        descripcion=r.descripcion,
        estado=r.estado,
        creado_en=r.creado_en,
        sancion=r.sancion,
        nota_resolucion=r.nota_resolucion,
        admin_id=r.admin_id,
        admin_resolutor_id=r.admin_id,
        resuelto_en=r.resuelto_en,
        reportante=UsuarioResumen.model_validate(r.reportante),
        reportado=UsuarioResumen.model_validate(r.reportado),
        objeto=objeto_str,
    )


@router.post(
    "/loans/{loan_id}/reports",
    response_model=ReporteOut,
    status_code=status.HTTP_201_CREATED,
    summary="Reportar un problema en un préstamo en curso (RF-014)",
)
def crear_reporte_prestamo(
    loan_id: int,
    datos: ReporteCrearIn,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Solo solicitante o prestador de un préstamo no finalizado que no tenga ya
    un reporte pendiente. Marca prestamo.en_conflicto = True conservando su estado real."""
    prestamo = db.query(Prestamo).filter(Prestamo.id == loan_id).first()
    if prestamo is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El préstamo no existe.",
        )

    if current_user.id not in (prestamo.solicitante_id, prestamo.prestador_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el solicitante o el prestador pueden reportar un problema en este préstamo.",
        )

    if prestamo.estado == EstadoPrestamo.FINALIZADO:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se puede reportar un problema sobre un préstamo que ya finalizó.",
        )

    pendiente_existente = (
        db.query(Reporte)
        .filter(
            Reporte.prestamo_id == prestamo.id,
            Reporte.estado == EstadoReporte.PENDIENTE,
        )
        .first()
    )
    if pendiente_existente is not None or prestamo.en_conflicto:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Este préstamo ya tiene un reporte pendiente en revisión.",
        )

    reportado_id = (
        prestamo.prestador_id
        if current_user.id == prestamo.solicitante_id
        else prestamo.solicitante_id
    )

    reporte = Reporte(
        prestamo_id=prestamo.id,
        organizacion_id=prestamo.organizacion_id,
        reportante_id=current_user.id,
        reportado_id=reportado_id,
        tipo=datos.tipo,
        descripcion=datos.descripcion.strip(),
        estado=EstadoReporte.PENDIENTE,
    )
    prestamo.en_conflicto = True

    db.add(reporte)
    db.add(prestamo)
    db.commit()
    db.refresh(reporte)
    return serializar_reporte(reporte)


@router.get(
    "/organizations/{org_id}/reports",
    response_model=list[ReporteOut],
    status_code=status.HTTP_200_OK,
    summary="Listar reportes de una organización (RF-016)",
)
def listar_reportes_organizacion(
    org_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Devuelve los reportes de la organización ordenados del más reciente al más antiguo."""
    deps.exigir_miembro(db, current_user.id, org_id)
    filas = (
        db.query(Reporte)
        .filter(Reporte.organizacion_id == org_id)
        .order_by(Reporte.creado_en.desc(), Reporte.id.desc())
        .all()
    )
    return [serializar_reporte(r) for r in filas]


@router.get(
    "/reports",
    response_model=list[ReporteOut],
    status_code=status.HTTP_200_OK,
    summary="Listar reportes filtrando por organización",
)
def listar_reportes(
    organizacion_id: int = Query(..., description="ID de la organización"),
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    return listar_reportes_organizacion(organizacion_id, current_user, db)


@router.post(
    "/reports/{report_id}/resolve",
    response_model=ReporteOut,
    status_code=status.HTTP_200_OK,
    summary="Resolver un reporte y aplicar sanción disciplinaria (RF-017)",
)
def resolver_reporte(
    report_id: int,
    datos: ResolverReporteIn,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Exclusivo del administrador de la organización (403 si no lo es).
    Actualiza el estado de la Membresia del usuario reportado en esa organización,
    marca el reporte como RESUELTO y apaga prestamo.en_conflicto."""
    reporte = db.query(Reporte).filter(Reporte.id == report_id).first()
    if reporte is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El reporte no existe.",
        )

    deps.exigir_admin_organizacion(db, current_user.id, reporte.organizacion_id)

    if reporte.estado == EstadoReporte.RESUELTO:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Este reporte ya fue resuelto anteriormente.",
        )

    membresia_reportado = (
        db.query(Membresia)
        .filter(
            Membresia.usuario_id == reporte.reportado_id,
            Membresia.organizacion_id == reporte.organizacion_id,
        )
        .first()
    )
    if membresia_reportado is not None:
        nota = (datos.nota_resolucion or datos.nota or "").strip()
        membresia_reportado.sancion_motivo = nota
        if datos.sancion == Sancion.ADVERTENCIA:
            membresia_reportado.estado = EstadoMembresia.ADVERTIDO
            membresia_reportado.sancion_hasta = None
        elif datos.sancion == Sancion.SUSPENSION:
            membresia_reportado.estado = EstadoMembresia.SUSPENDIDO
            membresia_reportado.sancion_hasta = datos.sancion_hasta
        else:
            membresia_reportado.estado = EstadoMembresia.BANEADO
            membresia_reportado.sancion_hasta = None
        db.add(membresia_reportado)

    reporte.estado = EstadoReporte.RESUELTO
    reporte.sancion = datos.sancion
    reporte.nota_resolucion = (datos.nota_resolucion or datos.nota or "").strip()
    reporte.admin_id = current_user.id
    reporte.resuelto_en = datetime.now()
    db.add(reporte)

    prestamo = (
        db.query(Prestamo).filter(Prestamo.id == reporte.prestamo_id).first()
    )
    if prestamo is not None:
        prestamo.en_conflicto = False
        db.add(prestamo)

    db.commit()
    db.refresh(reporte)
    return serializar_reporte(reporte)


def _revertir_sancion_membresia(
    db: Session, membresia: Membresia, current_user: Usuario
) -> MembresiaOut:
    deps.exigir_admin_organizacion(
        db, current_user.id, membresia.organizacion_id
    )
    membresia.estado = EstadoMembresia.ACTIVO
    membresia.sancion_hasta = None
    membresia.sancion_motivo = None
    db.add(membresia)
    db.commit()
    db.refresh(membresia)
    return serializar_membresia(db, membresia)


@router.post(
    "/memberships/{membership_id}/revert-sanction",
    response_model=MembresiaOut,
    status_code=status.HTTP_200_OK,
    summary="Revertir sanción de un miembro por ID de membresía (RF-017)",
)
def revertir_sancion_por_membresia(
    membership_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Exclusivo del administrador de la organización. Restaura la membresía a ACTIVO
    y limpia la fecha de suspensión."""
    membresia = (
        db.query(Membresia).filter(Membresia.id == membership_id).first()
    )
    if membresia is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="La membresía no existe.",
        )
    return _revertir_sancion_membresia(db, membresia, current_user)


@router.post(
    "/organizations/{org_id}/members/{user_id}/revert-sanction",
    response_model=MembresiaOut,
    status_code=status.HTTP_200_OK,
    summary="Revertir sanción de un miembro por org_id y user_id (RF-017)",
)
def revertir_sancion_por_usuario(
    org_id: int,
    user_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Alternativa por org_id + user_id para revertir la sanción de un miembro."""
    deps.exigir_admin_organizacion(db, current_user.id, org_id)
    membresia = (
        db.query(Membresia)
        .filter(
            Membresia.organizacion_id == org_id,
            Membresia.usuario_id == user_id,
        )
        .first()
    )
    if membresia is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El usuario no pertenece a esta organización.",
        )
    return _revertir_sancion_membresia(db, membresia, current_user)

