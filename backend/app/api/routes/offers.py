"""Endpoints de Ofertas y aceptación atómica con creación de Préstamo (RF-008 a RF-011, RNF-007)."""
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.api import deps
from app.api.routes.loans import serializar_prestamo
from app.models import (
    EstadoNecesidad,
    EstadoOferta,
    EstadoPrestamo,
    Modalidad,
    Necesidad,
    Oferta,
    Organizacion,
    Prestamo,
    UnidadCobro,
    Usuario,
)
from app.schemas import OfferCreate, OfertaCrearIn, OfertaOut, PrestamoOut, UsuarioResumen

router = APIRouter()


def calcular_total_oferta(
    necesidad: Necesidad,
    modalidad: Modalidad,
    precio: float | None,
    unidad_cobro: UnidadCobro | None,
) -> float:
    """RF-008: Calcula el monto total en el servidor según modalidad, unidad y rango de fechas.
    dias = max(1, (fecha_fin - fecha_inicio).days)."""
    if modalidad == Modalidad.GRATIS or precio is None:
        return 0.0
    dias = max(1, (necesidad.fecha_fin - necesidad.fecha_inicio).days)
    if unidad_cobro == UnidadCobro.DIA:
        return round(float(precio) * dias, 2)
    return round(float(precio) * dias * 24, 2)


def serializar_oferta(oferta: Oferta, necesidad: Necesidad) -> OfertaOut:
    """Convierte una Oferta ORM a OfertaOut incluyendo total_calculado."""
    total = calcular_total_oferta(
        necesidad, oferta.modalidad, oferta.precio, oferta.unidad_cobro
    )
    return OfertaOut(
        id=oferta.id,
        necesidad_id=oferta.necesidad_id,
        prestador_id=oferta.prestador_id,
        modalidad=oferta.modalidad,
        precio=oferta.precio,
        unidad_cobro=oferta.unidad_cobro,
        fecha_entrega=oferta.fecha_entrega,
        estado=oferta.estado,
        prestador=UsuarioResumen.model_validate(oferta.prestador),
        total_calculado=total,
    )


def _crear_oferta_en_necesidad(
    db: Session,
    need_id: int,
    offer_in: OfertaCrearIn,
    current_user: Usuario,
) -> OfertaOut:
    necesidad = db.query(Necesidad).filter(Necesidad.id == need_id).first()
    if necesidad is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="La necesidad no existe.",
        )

    # RF-008 y RF-018: Verifica membresía y que no esté SUSPENDIDO ni BANEADO (403).
    deps.exigir_miembro_activo_no_bloqueado(
        db, current_user.id, necesidad.organizacion_id
    )

    if necesidad.solicitante_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No puedes hacer una oferta sobre tu propia necesidad.",
        )

    if necesidad.estado != EstadoNecesidad.BUSCANDO_PRESTADOR:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Esta necesidad ya no está buscando prestador.",
        )

    oferta_existente = (
        db.query(Oferta)
        .filter(
            Oferta.necesidad_id == necesidad.id,
            Oferta.prestador_id == current_user.id,
            Oferta.estado == EstadoOferta.PENDIENTE,
        )
        .first()
    )
    if oferta_existente is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya tienes una oferta pendiente para esta necesidad.",
        )

    fecha_entrega = offer_in.fecha_entrega or necesidad.fecha_inicio
    nueva = Oferta(
        necesidad_id=necesidad.id,
        prestador_id=current_user.id,
        modalidad=offer_in.modalidad,
        precio=(
            offer_in.precio
            if offer_in.modalidad == Modalidad.ALQUILER
            else None
        ),
        unidad_cobro=(
            offer_in.unidad_cobro
            if offer_in.modalidad == Modalidad.ALQUILER
            else None
        ),
        fecha_entrega=fecha_entrega,
        estado=EstadoOferta.PENDIENTE,
    )
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return serializar_oferta(nueva, necesidad)


@router.post(
    "/needs/{need_id}/offers",
    response_model=OfertaOut,
    status_code=status.HTTP_201_CREATED,
    summary="Crear una oferta sobre una necesidad (RF-008, RF-009)",
)
def crear_oferta_en_necesidad(
    need_id: int,
    offer_in: OfferCreate,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Crea una oferta en estado PENDIENTE calculando el total en el servidor."""
    return _crear_oferta_en_necesidad(db, need_id, offer_in, current_user)


@router.post(
    "/offers",
    response_model=OfertaOut,
    status_code=status.HTTP_201_CREATED,
    summary="Crear una oferta indicando necesidad_id en el cuerpo (RF-008, RF-009)",
)
@router.post(
    "/offers/",
    response_model=OfertaOut,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False,
)
def create_offer(
    offer_in: OfferCreate,
    necesidad_id: int | None = Query(default=None),
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Crea una oferta recibiendo necesidad_id en el cuerpo o como query param."""
    target_need_id = offer_in.necesidad_id or necesidad_id
    if target_need_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Debes indicar el ID de la necesidad (necesidad_id).",
        )
    return _crear_oferta_en_necesidad(
        db, target_need_id, offer_in, current_user
    )


def _listar_ofertas_de_necesidad(
    db: Session, need_id: int, current_user: Usuario
) -> list[OfertaOut]:
    necesidad = db.query(Necesidad).filter(Necesidad.id == need_id).first()
    if necesidad is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="La necesidad no existe.",
        )

    deps.exigir_miembro(db, current_user.id, necesidad.organizacion_id)

    ofertas = (
        db.query(Oferta)
        .filter(Oferta.necesidad_id == need_id)
        .order_by(Oferta.id.desc())
        .all()
    )
    return [serializar_oferta(o, necesidad) for o in ofertas]


@router.get(
    "/needs/{need_id}/offers",
    response_model=list[OfertaOut],
    status_code=status.HTTP_200_OK,
    summary="Listar las ofertas de una necesidad (RF-010)",
)
def listar_ofertas_por_necesidad(
    need_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Devuelve todas las ofertas recibidas para una necesidad."""
    return _listar_ofertas_de_necesidad(db, need_id, current_user)


@router.get(
    "/offers/need/{need_id}",
    response_model=list[OfertaOut],
    status_code=status.HTTP_200_OK,
    summary="Alias para listar ofertas de una necesidad",
)
def read_offers_by_need(
    need_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    return _listar_ofertas_de_necesidad(db, need_id, current_user)


@router.get(
    "/offers/me",
    response_model=list[OfertaOut],
    status_code=status.HTTP_200_OK,
    summary="Listar las ofertas enviadas por el usuario actual",
)
def read_offers_me(
    organizacion_id: int | None = Query(default=None),
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Devuelve las ofertas enviadas por el usuario actual."""
    q = (
        db.query(Oferta, Necesidad)
        .join(Necesidad, Necesidad.id == Oferta.necesidad_id)
        .filter(Oferta.prestador_id == current_user.id)
    )
    if organizacion_id is not None:
        deps.exigir_miembro(db, current_user.id, organizacion_id)
        q = q.filter(Necesidad.organizacion_id == organizacion_id)
    filas = q.order_by(Oferta.id.desc()).all()
    return [serializar_oferta(oferta, nec) for oferta, nec in filas]


@router.post(
    "/offers/{offer_id}/reject",
    response_model=OfertaOut,
    status_code=status.HTTP_200_OK,
    summary="Rechazar una oferta recibida (RF-010)",
)
def rechazar_oferta(
    offer_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Exclusivo del solicitante de la necesidad. Pasa la oferta a RECHAZADA sin cerrar
    la necesidad ni las demás ofertas."""
    oferta = db.query(Oferta).filter(Oferta.id == offer_id).first()
    if oferta is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="La oferta no existe.",
        )

    necesidad = (
        db.query(Necesidad)
        .filter(Necesidad.id == oferta.necesidad_id)
        .first()
    )
    if necesidad is None or necesidad.solicitante_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el solicitante de la necesidad puede rechazar sus ofertas.",
        )

    if oferta.estado != EstadoOferta.PENDIENTE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Solo se pueden rechazar ofertas que estén pendientes.",
        )

    oferta.estado = EstadoOferta.RECHAZADA
    db.add(oferta)
    db.commit()
    db.refresh(oferta)
    return serializar_oferta(oferta, necesidad)


@router.post(
    "/offers/{offer_id}/accept",
    response_model=PrestamoOut,
    status_code=status.HTTP_200_OK,
    summary="Aceptar una oferta y crear el préstamo en CONFIRMADO (RF-010, RF-011, RNF-007)",
)
def accept_offer(
    offer_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Transacción atómica:
    1. Verifica que quien acepta sea el solicitante_id y no esté bloqueado en la organización.
    2. Verifica que la oferta esté PENDIENTE y la necesidad en BUSCANDO_PRESTADOR.
    3. Pasa la oferta a ACEPTADA y el resto de ofertas PENDIENTE a CERRADA.
    4. Pasa la necesidad a CON_PRESTAMO_CONFIRMADO.
    5. Crea el Prestamo en estado CONFIRMADO copiando el punto_central de la organización."""
    oferta = db.query(Oferta).filter(Oferta.id == offer_id).first()
    if oferta is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="La oferta no existe.",
        )

    necesidad = (
        db.query(Necesidad)
        .filter(Necesidad.id == oferta.necesidad_id)
        .first()
    )
    if necesidad is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="La necesidad asociada no existe.",
        )

    if necesidad.solicitante_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el solicitante de la necesidad puede aceptar una oferta.",
        )

    # RF-018: Verifica que el solicitante no esté SUSPENDIDO ni BANEADO en la organización.
    deps.exigir_miembro_activo_no_bloqueado(
        db, current_user.id, necesidad.organizacion_id
    )

    if necesidad.estado != EstadoNecesidad.BUSCANDO_PRESTADOR:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Esta necesidad ya tiene un préstamo confirmado o está cerrada.",
        )

    if oferta.estado != EstadoOferta.PENDIENTE:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Esta oferta ya no está pendiente.",
        )

    org = (
        db.query(Organizacion)
        .filter(Organizacion.id == necesidad.organizacion_id)
        .first()
    )
    punto_central = org.punto_central if org is not None else "Punto central"
    precio_total = calcular_total_oferta(
        necesidad, oferta.modalidad, oferta.precio, oferta.unidad_cobro
    )

    try:
        oferta.estado = EstadoOferta.ACEPTADA
        db.add(oferta)

        otras_pendientes = (
            db.query(Oferta)
            .filter(
                Oferta.necesidad_id == necesidad.id,
                Oferta.id != oferta.id,
                Oferta.estado == EstadoOferta.PENDIENTE,
            )
            .all()
        )
        for otra in otras_pendientes:
            otra.estado = EstadoOferta.CERRADA
            db.add(otra)

        necesidad.estado = EstadoNecesidad.CON_PRESTAMO_CONFIRMADO
        db.add(necesidad)

        prestamo = Prestamo(
            oferta_id=oferta.id,
            necesidad_id=necesidad.id,
            organizacion_id=necesidad.organizacion_id,
            solicitante_id=necesidad.solicitante_id,
            prestador_id=oferta.prestador_id,
            objeto=necesidad.objeto,
            fecha_inicio=necesidad.fecha_inicio,
            fecha_fin=necesidad.fecha_fin,
            modalidad=oferta.modalidad,
            precio_total=precio_total,
            punto_central=punto_central,
            estado=EstadoPrestamo.CONFIRMADO,
            en_conflicto=False,
        )
        db.add(prestamo)
        db.commit()
        db.refresh(prestamo)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Esta necesidad ya tiene una oferta aceptada.",
        )

    return serializar_prestamo(prestamo, current_user.id)
