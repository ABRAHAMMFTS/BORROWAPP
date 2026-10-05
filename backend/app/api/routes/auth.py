from datetime import timedelta
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.api import deps
from app.core import security
from app.core.config import settings
from app.models import Usuario
from app.schemas import UsuarioOut
from pydantic import BaseModel

class Token(BaseModel):
    access_token: str
    token_type: str

router = APIRouter()

@router.post("/login", response_model=Token)
def login_access_token(
    db: Session = Depends(deps.get_db), form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    """
    OAuth2 compatible token login, get an access token for future requests.
    """
    user = db.query(Usuario).filter(Usuario.correo == form_data.username).first()
    if not user or not security.verificar_contrasena(form_data.password, user.contrasena_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect correo or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return {
        "access_token": security.crear_token(user.id),
        "token_type": "bearer",
    }

@router.get("/me", response_model=UsuarioOut)
def read_users_me(
    current_user: Usuario = Depends(deps.get_current_user),
) -> Any:
    """
    Get current user.
    """
    return current_user
