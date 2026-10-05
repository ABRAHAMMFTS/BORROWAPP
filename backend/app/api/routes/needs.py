from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api import deps
from app.models import Necesidad, Usuario, EstadoNecesidad
from app.schemas import NecesidadCrearIn, NecesidadOut

router = APIRouter()

@router.post("/", response_model=NecesidadOut, status_code=status.HTTP_201_CREATED)
def create_need(
    *,
    db: Session = Depends(deps.get_db),
    need_in: NecesidadCrearIn,
    current_user: Usuario = Depends(deps.get_current_user),
) -> Any:
    """
    Create new need.
    """
    need = Necesidad(
        usuario_id=current_user.id,
        objeto=need_in.objeto,
        descripcion=need_in.descripcion,
        estado=EstadoNecesidad.buscandoPrestador,
        fecha_inicio=need_in.fecha_inicio,
        fecha_fin=need_in.fecha_fin,
        organizacion_id=1 # Hardcode for now or fetch from current_user
    )
    db.add(need)
    db.commit()
    db.refresh(need)
    return need

@router.get("/", response_model=List[NecesidadOut])
def read_needs(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Retrieve needs.
    """
    needs = db.query(Necesidad).offset(skip).limit(limit).all()
    return needs

@router.get("/me", response_model=List[NecesidadOut])
def read_needs_me(
    db: Session = Depends(deps.get_db),
    current_user: Usuario = Depends(deps.get_current_user),
) -> Any:
    """
    Retrieve needs of current user.
    """
    needs = db.query(Necesidad).filter(Necesidad.usuario_id == current_user.id).all()
    return needs
