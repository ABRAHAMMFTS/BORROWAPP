"""Endpoints de usuarios: creación de cuenta y consulta pública de usuario por ID."""
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api import deps
from app.api.routes.auth import obtener_membresias_usuario, registrar_nuevo_usuario
from app.models import Usuario
from app.schemas import (
    AuthOut,
    PerfilMeOut,
    RegistroIn,
    UsuarioOut,
    UsuarioPublicoOut,
)

router = APIRouter()


@router.post(
    "/",
    response_model=AuthOut,
    status_code=status.HTTP_201_CREATED,
    summary="Crear cuenta de usuario (alias de /auth/register)",
)
@router.post(
    "",
    response_model=AuthOut,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False,
)
def create_user(
    user_in: RegistroIn,
    db: Session = Depends(deps.get_db),
) -> Any:
    """Registra un nuevo usuario validando nombre completo, correo único y contraseña >= 8 caracteres."""
    return registrar_nuevo_usuario(db, user_in)


@router.get(
    "/me",
    response_model=PerfilMeOut,
    status_code=status.HTTP_200_OK,
    summary="Obtener datos del usuario autenticado",
)
def read_user_me(
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Devuelve los datos del usuario actual junto con sus membresías y organizaciones."""
    membresias = obtener_membresias_usuario(db, current_user.id)
    organizaciones = [
        m.organizacion for m in membresias if m.organizacion is not None
    ]
    usuario_out = UsuarioOut.model_validate(current_user)
    return PerfilMeOut(
        id=current_user.id,
        nombre=current_user.nombre,
        correo=current_user.correo,
        iniciales=current_user.iniciales,
        usuario=usuario_out,
        membresias=membresias,
        organizaciones=organizaciones,
    )


@router.get(
    "/{user_id}",
    response_model=UsuarioPublicoOut,
    status_code=status.HTTP_200_OK,
    summary="Obtener datos básicos de un usuario por ID",
)
def read_user_by_id(
    user_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Devuelve id, nombre, correo e iniciales de un usuario (jamás expone contrasena_hash)."""
    usuario = db.query(Usuario).filter(Usuario.id == user_id).first()
    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El usuario solicitado no existe.",
        )
    return UsuarioPublicoOut.model_validate(usuario)
