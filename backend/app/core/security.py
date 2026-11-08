"""Seguridad: contraseñas con bcrypt (RNF-002) y tokens JWT (RF-002)."""
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt

from app.core.config import ALGORITMO_JWT, CLAVE_SECRETA, MINUTOS_VALIDEZ_TOKEN


def hashear_contrasena(contrasena: str) -> str:
    """Devuelve el hash bcrypt en UTF-8. La contraseña nunca se guarda en texto plano."""
    return bcrypt.hashpw(contrasena.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verificar_contrasena(contrasena: str, hash_guardado: str) -> bool:
    """Compara una contraseña en texto plano contra su hash bcrypt almacenado."""
    try:
        return bcrypt.checkpw(
            contrasena.encode("utf-8"),
            hash_guardado.encode("utf-8"),
        )
    except ValueError:
        return False


def crear_token(usuario_id: int) -> str:
    """Genera un JWT firmado con el id del usuario en 'sub' y su fecha de expiración 'exp'."""
    expira = datetime.now(timezone.utc) + timedelta(minutes=MINUTOS_VALIDEZ_TOKEN)
    payload = {
        "sub": str(usuario_id),
        "exp": expira,
    }
    return jwt.encode(payload, CLAVE_SECRETA, algorithm=ALGORITMO_JWT)


def decodificar_token(token: str) -> dict:
    """Decodifica el JWT con PyJWT. Lanza ExpiredSignatureError o InvalidTokenError si falla."""
    return jwt.decode(token, CLAVE_SECRETA, algorithms=[ALGORITMO_JWT])
