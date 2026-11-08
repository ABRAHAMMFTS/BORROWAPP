"""Punto de entrada de la API FastAPI de BorrowApp."""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import inspect, text

from app import models
from app.api.routes import auth, loans, needs, offers, organizations, reports, users
from app.core.config import settings
from app.core.database import engine
from app.errors import ReglaNegocio


def _asegurar_esquema_bd() -> None:
    """Crea las tablas si no existen y asegura columnas nuevas en bases locales."""
    models.Base.metadata.create_all(bind=engine)
    try:
        inspector = inspect(engine)
        if "membresias" in inspector.get_table_names():
            columnas = {col["name"] for col in inspector.get_columns("membresias")}
            if "sancion_motivo" not in columnas:
                with engine.begin() as conn:
                    conn.execute(
                        text("ALTER TABLE membresias ADD COLUMN sancion_motivo TEXT")
                    )
    except Exception:
        pass


_asegurar_esquema_bd()

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.1.0",
    description="API REST para gestión de préstamos y alquileres de objetos en organizaciones cerradas (SRS v1.1).",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(ReglaNegocio)
async def manejador_regla_negocio(_request: Request, exc: ReglaNegocio) -> JSONResponse:
    """Convierte excepciones de negocio en respuestas HTTP con detail claro en español."""
    return JSONResponse(
        status_code=exc.codigo,
        content={"detail": exc.mensaje},
    )


app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])
app.include_router(users.router, prefix=f"{settings.API_V1_STR}/users", tags=["users"])
app.include_router(
    organizations.router,
    prefix=f"{settings.API_V1_STR}/organizations",
    tags=["organizations"],
)
app.include_router(needs.router, prefix=settings.API_V1_STR, tags=["needs"])
app.include_router(offers.router, prefix=settings.API_V1_STR, tags=["offers"])
app.include_router(loans.router, prefix=settings.API_V1_STR, tags=["loans"])
app.include_router(reports.router, prefix=settings.API_V1_STR, tags=["reports"])


@app.get("/")
def read_root() -> dict[str, str]:
    return {
        "mensaje": "API BorrowApp funcionando correctamente",
        "estado": "ok",
    }
