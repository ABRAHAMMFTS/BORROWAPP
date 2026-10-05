"""Seguridad: contraseñas con bcrypt (RNF-002) y tokens JWT (RF-002)."""
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt

from app.core.config import ALGORITMO_JWT, MINUTOS_TOKEN, SECRET_KEY


def hashear_contrasena(contrasena: str) -> str:
    """Devuelve el hash bcrypt. La contraseña nunca se guarda en texto plano."""
    return bcrypt.hashpw(contrasena.encode(), bcrypt.gensalt()).decode()


def verificar_contrasena(contrasena: str, hash_guardado: str) -> bool:
    try:
        return bcrypt.checkpw(contrasena.encode(), hash_guardado.encode())
    except ValueError:
        return False


def crear_token(usuario_id: int) -> str:
    """Token firmado que identifica al usuario y expira solo."""
    expira = datetime.now(timezone.utc) + timedelta(minutes=MINUTOS_TOKEN)
    return jwt.encode({"sub": str(usuario_id), "exp": expira}, SECRET_KEY, algorithm=ALGORITMO_JWT)


def leer_token(token: str) -> int | None:
    """Devuelve el id del usuario o None si el token es inválido o venció."""
    try:
        datos = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITMO_JWT])
        return int(datos["sub"])
    except (jwt.PyJWTError, KeyError, ValueError):
        return None
