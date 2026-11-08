"""Configuración del backend leída desde variables de entorno y archivo .env."""
import os
from dotenv import load_dotenv

# Carga variables desde el archivo .env si existe (solo para entorno local).
load_dotenv()


def _normalizar_database_url(url: str) -> str:
    """Convierte 'postgres://' a 'postgresql://' para compatibilidad con SQLAlchemy 2.0 y Supabase."""
    url_limpia = url.strip()
    if url_limpia.startswith("postgres://"):
        return url_limpia.replace("postgres://", "postgresql://", 1)
    return url_limpia


class Settings:
    PROJECT_NAME: str = "BorrowApp API"
    API_V1_STR: str = "/api/v1"
    BACKEND_CORS_ORIGINS: list[str] = ["*"]

    # Base de datos:
    # - Producción / Supabase PostgreSQL: postgresql://... (con SSL)
    # - Desarrollo local sin servidor: sqlite:///./borrowapp.db
    DATABASE_URL: str = _normalizar_database_url(
        os.getenv("DATABASE_URL", "sqlite:///./borrowapp.db")
    )

    # Clave secreta para firmar tokens JWT (valor por defecto exclusivo para desarrollo local).
    CLAVE_SECRETA: str = os.getenv(
        "CLAVE_SECRETA",
        os.getenv("SECRET_KEY", "clave-local-desarrollo-borrowapp-cambiar-en-produccion"),
    )
    SECRET_KEY: str = CLAVE_SECRETA

    # Algoritmo y vigencia del token JWT (7 días = 10080 minutos).
    ALGORITMO_JWT: str = "HS256"
    ALGORITHM: str = ALGORITMO_JWT
    MINUTOS_VALIDEZ_TOKEN: int = int(
        os.getenv("MINUTOS_VALIDEZ_TOKEN", os.getenv("MINUTOS_TOKEN", "10080"))
    )
    MINUTOS_TOKEN: int = MINUTOS_VALIDEZ_TOKEN

    # Semillas de ejemplo del SRS v1.1.
    CARGAR_DATOS_EJEMPLO: bool = os.getenv(
        "CARGAR_DATOS_EJEMPLO", "true"
    ).strip().lower() in ("1", "true", "yes", "si")


settings = Settings()

DATABASE_URL: str = settings.DATABASE_URL
CLAVE_SECRETA: str = settings.CLAVE_SECRETA
SECRET_KEY: str = settings.SECRET_KEY
ALGORITMO_JWT: str = settings.ALGORITMO_JWT
ALGORITHM: str = settings.ALGORITHM
MINUTOS_VALIDEZ_TOKEN: int = settings.MINUTOS_VALIDEZ_TOKEN
MINUTOS_TOKEN: int = settings.MINUTOS_TOKEN
CARGAR_DATOS_EJEMPLO: bool = settings.CARGAR_DATOS_EJEMPLO
