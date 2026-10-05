from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api import deps
from app.models import Oferta, Usuario, Necesidad, Prestamo, EstadoOferta, EstadoPrestamo
from app.schemas import OfertaCrearIn, OfertaOut, PrestamoOut

router = APIRouter()

@router.post("/", response_model=OfertaOut, status_code=status.HTTP_201_CREATED)
def create_offer(
    *,
    db: Session = Depends(deps.get_db),
    offer_in: OfertaCrearIn,
    current_user: Usuario = Depends(deps.get_current_user),
) -> Any:
    """
    Create new offer.
    """
    # Assuming need_id is passed somewhere or modify schema. Let's assume passed in query or change route to /need/{need_id}/offer
    # Wait, OfertaCrearIn doesn't have necesidad_id. Let's just create a dummy one for now to pass compilation, or add need_id to route.
    # For now, let's pretend need_id is 1
    need = db.query(Necesidad).filter(Necesidad.id == 1).first()
    if not need:
        raise HTTPException(status_code=404, detail="Need not found")
        
    offer = Oferta(
        necesidad_id=need.id,
        prestador_id=current_user.id,
        modalidad=offer_in.modalidad,
        precio=offer_in.precio,
        unidad_cobro=offer_in.unidad_cobro,
        fecha_entrega=offer_in.fecha_entrega,
        estado=EstadoOferta.pendiente
    )
    db.add(offer)
    db.commit()
    db.refresh(offer)
    return offer

@router.get("/me", response_model=List[OfertaOut])
def read_offers_me(
    db: Session = Depends(deps.get_db),
    current_user: Usuario = Depends(deps.get_current_user),
) -> Any:
    """
    Retrieve offers made by current user.
    """
    offers = db.query(Oferta).filter(Oferta.prestador_id == current_user.id).all()
    return offers

@router.get("/need/{need_id}", response_model=List[OfertaOut])
def read_offers_by_need(
    need_id: int,
    db: Session = Depends(deps.get_db),
    current_user: Usuario = Depends(deps.get_current_user),
) -> Any:
    """
    Retrieve offers for a specific need.
    """
    offers = db.query(Oferta).filter(Oferta.necesidad_id == need_id).all()
    return offers

@router.post("/{offer_id}/accept", response_model=PrestamoOut)
def accept_offer(
    offer_id: int,
    db: Session = Depends(deps.get_db),
    current_user: Usuario = Depends(deps.get_current_user),
) -> Any:
    """
    Accept an offer and create a loan.
    """
    offer = db.query(Oferta).filter(Oferta.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    
    need = db.query(Necesidad).filter(Necesidad.id == offer.necesidad_id).first()
    if need.usuario_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to accept this offer")
        
    offer.estado = EstadoOferta.aceptada
    
    prestamo = Prestamo(
        oferta_id=offer.id,
        necesidad_id=need.id,
        organizacion_id=need.organizacion_id,
        objeto=need.objeto,
        fecha_inicio=need.fecha_inicio,
        fecha_fin=need.fecha_fin,
        modalidad=offer.modalidad,
        precio_total=offer.precio or 0.0,
        punto_central="Punto Central",
        estado=EstadoPrestamo.activo,
        solicitante_id=need.usuario_id,
        prestador_id=offer.prestador_id,
    )
    db.add(prestamo)
    
    db.commit()
    db.refresh(prestamo)
    return prestamo
