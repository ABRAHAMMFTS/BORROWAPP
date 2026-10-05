"""Configuración del backend. Todo se lee de variables de entorno."""
import os

class Settings:
    PROJECT_NAME: str = "BorrowApp API"
    API_V1_STR: str = "/api/v1"
    BACKEND_CORS_ORIGINS: list[str] = ["http://localhost:8080", "http://localhost:3000"]
    
    # Cadena de conexión a la base de datos.
    # Producción (SRS 2.5):  postgresql+psycopg2://usuario:clave@host:5432/borrowapp
    # Desarrollo sin instalar nada: si no hay variable, se usa un archivo SQLite.
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./borrowapp.db")
    
    # Clave con la que se firman los tokens JWT. CÁMBIALA en producción.
    SECRET_KEY: str = os.getenv("SECRET_KEY", "cambia-esta-clave-en-produccion")
    ALGORITMO_JWT: str = "HS256"
    MINUTOS_TOKEN: int = int(os.getenv("MINUTOS_TOKEN", "10080"))  # 7 días
    
    # Si es "1", al arrancar se cargan los datos de ejemplo del SRS (sección 1.6).
    CARGAR_DATOS_EJEMPLO: bool = os.getenv("CARGAR_DATOS_EJEMPLO", "1") == "1"

settings = Settings()

ALGORITMO_JWT = settings.ALGORITMO_JWT
MINUTOS_TOKEN = settings.MINUTOS_TOKEN
SECRET_KEY = settings.SECRET_KEY
DATABASE_URL = settings.DATABASE_URL

