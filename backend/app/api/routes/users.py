from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api import deps
from app.core.security import hashear_contrasena
from app.models import Usuario
from app.schemas import RegistroIn, UsuarioOut

router = APIRouter()

@router.post("/", response_model=UsuarioOut, status_code=status.HTTP_201_CREATED)
def create_user(
    *,
    db: Session = Depends(deps.get_db),
    user_in: RegistroIn,
) -> Any:
    """
    Create new user.
    """
    user = db.query(Usuario).filter(Usuario.correo == user_in.correo).first()
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this username already exists in the system.",
        )
    user = Usuario(
        nombre=user_in.nombre,
        correo=user_in.correo,
        contrasena_hash=hashear_contrasena(user_in.contrasena),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
