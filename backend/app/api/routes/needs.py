"""Endpoints de Necesidades (RF-006, RF-007, RF-020)."""
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api import deps
from app.models import (
    EstadoNecesidad,
    EstadoOferta,
    Membresia,
    Necesidad,
    Oferta,
    Usuario,
)
from app.schemas import NecesidadCrearIn, NecesidadOut, UsuarioResumen

router = APIRouter()


def serializar_necesidad(
    db: Session, n: Necesidad, usuario_actual_id: int
) -> NecesidadOut:
    """Construye NecesidadOut enriquecido con ofertas_pendientes y mi_oferta_id."""
    ofertas_pend = (
        db.query(Oferta)
        .filter(
            Oferta.necesidad_id == n.id,
            Oferta.estado == EstadoOferta.PENDIENTE,
        )
        .all()
    )
    mi_oferta = next(
        (o.id for o in ofertas_pend if o.prestador_id == usuario_actual_id),
        None,
    )
    return NecesidadOut(
        id=n.id,
        organizacion_id=n.organizacion_id,
        solicitante_id=n.solicitante_id,
        objeto=n.objeto,
        descripcion=n.descripcion,
        fecha_inicio=n.fecha_inicio,
        fecha_fin=n.fecha_fin,
        estado=n.estado,
        creada_en=n.creada_en,
        solicitante=UsuarioResumen.model_validate(n.solicitante),
        ofertas_pendientes=len(ofertas_pend),
        mi_oferta_id=mi_oferta,
    )


def _listar_necesidades_org(
    db: Session, org_id: int, current_user: Usuario
) -> list[NecesidadOut]:
    deps.exigir_miembro(db, current_user.id, org_id)
    filas = (
        db.query(Necesidad)
        .filter(Necesidad.organizacion_id == org_id)
        .order_by(Necesidad.creada_en.desc(), Necesidad.id.desc())
        .all()
    )
    return [serializar_necesidad(db, n, current_user.id) for n in filas]


def _crear_necesidad_en_org(
    db: Session, org_id: int, need_in: NecesidadCrearIn, current_user: Usuario
) -> NecesidadOut:
    # RF-006 y RF-018: debe ser miembro de org_id y no estar SUSPENDIDO ni BANEADO (403).
    deps.exigir_miembro_activo_no_bloqueado(db, current_user.id, org_id)

    nueva = Necesidad(
        organizacion_id=org_id,
        solicitante_id=current_user.id,
        objeto=need_in.objeto.strip(),
        descripcion=need_in.descripcion.strip(),
        fecha_inicio=need_in.fecha_inicio,
        fecha_fin=need_in.fecha_fin,
        estado=EstadoNecesidad.BUSCANDO_PRESTADOR,
    )
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return serializar_necesidad(db, nueva, current_user.id)


@router.get(
    "/organizations/{org_id}/needs",
    response_model=list[NecesidadOut],
    status_code=status.HTTP_200_OK,
    summary="Listar necesidades de una organización (RF-007)",
)
def listar_necesidades_por_organizacion(
    org_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Devuelve las necesidades de la organización ordenadas de la más reciente a la más antigua."""
    return _listar_necesidades_org(db, org_id, current_user)


@router.post(
    "/organizations/{org_id}/needs",
    response_model=NecesidadOut,
    status_code=status.HTTP_201_CREATED,
    summary="Publicar una necesidad en una organización (RF-006)",
)
def crear_necesidad_en_organizacion(
    org_id: int,
    need_in: NecesidadCrearIn,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Crea una necesidad en estado BUSCANDO_PRESTADOR verificando que el miembro no esté bloqueado."""
    return _crear_necesidad_en_org(db, org_id, need_in, current_user)


@router.get(
    "/needs",
    response_model=list[NecesidadOut],
    status_code=status.HTTP_200_OK,
    summary="Listar necesidades filtrando por organizacion_id",
)
@router.get(
    "/needs/",
    response_model=list[NecesidadOut],
    status_code=status.HTTP_200_OK,
    include_in_schema=False,
)
def read_needs(
    organizacion_id: int | None = Query(
        default=None, description="ID de la organización"
    ),
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Lista las necesidades de organizacion_id (o de todas las organizaciones del usuario si se omite)."""
    if organizacion_id is not None:
        return _listar_necesidades_org(db, organizacion_id, current_user)

    org_ids = [
        m.organizacion_id
        for m in db.query(Membresia)
        .filter(Membresia.usuario_id == current_user.id)
        .all()
    ]
    if not org_ids:
        return []
    filas = (
        db.query(Necesidad)
        .filter(Necesidad.organizacion_id.in_(org_ids))
        .order_by(Necesidad.creada_en.desc(), Necesidad.id.desc())
        .all()
    )
    return [serializar_necesidad(db, n, current_user.id) for n in filas]


@router.post(
    "/needs",
    response_model=NecesidadOut,
    status_code=status.HTTP_201_CREATED,
    summary="Publicar una necesidad indicando organizacion_id (RF-006)",
)
@router.post(
    "/needs/",
    response_model=NecesidadOut,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False,
)
def create_need(
    need_in: NecesidadCrearIn,
    organizacion_id: int | None = Query(default=None),
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Crea una necesidad usando organizacion_id del cuerpo o query param."""
    org_id = need_in.organizacion_id or organizacion_id
    if org_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Debes indicar el ID de la organización (organizacion_id).",
        )
    return _crear_necesidad_en_org(db, org_id, need_in, current_user)


@router.get(
    "/needs/me",
    response_model=list[NecesidadOut],
    status_code=status.HTTP_200_OK,
    summary="Listar mis necesidades publicadas",
)
def read_needs_me(
    organizacion_id: int | None = Query(default=None),
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Devuelve las necesidades del usuario actual (opcionalmente filtradas por organización)."""
    q = db.query(Necesidad).filter(Necesidad.solicitante_id == current_user.id)
    if organizacion_id is not None:
        deps.exigir_miembro(db, current_user.id, organizacion_id)
        q = q.filter(Necesidad.organizacion_id == organizacion_id)
    filas = q.order_by(Necesidad.creada_en.desc(), Necesidad.id.desc()).all()
    return [serializar_necesidad(db, n, current_user.id) for n in filas]


@router.post(
    "/needs/{need_id}/cancel",
    response_model=NecesidadOut,
    status_code=status.HTTP_200_OK,
    summary="Cancelar una necesidad propia (RF-020)",
)
def cancelar_necesidad(
    need_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Cancela una necesidad propia que esté en BUSCANDO_PRESTADOR: pasa la necesidad
    a CERRADA y todas sus ofertas PENDIENTE a CERRADA."""
    necesidad = db.query(Necesidad).filter(Necesidad.id == need_id).first()
    if necesidad is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="La necesidad no existe.",
        )

    if necesidad.solicitante_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el solicitante que publicó la necesidad puede cancelarla.",
        )

    if necesidad.estado != EstadoNecesidad.BUSCANDO_PRESTADOR:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Solo puedes cancelar una necesidad mientras sigue buscando prestador.",
        )

    necesidad.estado = EstadoNecesidad.CERRADA
    ofertas_pendientes = (
        db.query(Oferta)
        .filter(
            Oferta.necesidad_id == necesidad.id,
            Oferta.estado == EstadoOferta.PENDIENTE,
        )
        .all()
    )
    for oferta in ofertas_pendientes:
        oferta.estado = EstadoOferta.CERRADA
        db.add(oferta)

    db.add(necesidad)
    db.commit()
    db.refresh(necesidad)
    return serializar_necesidad(db, necesidad, current_user.id)
