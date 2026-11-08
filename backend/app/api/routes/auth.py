"""Endpoints de autenticación: registro, inicio de sesión y perfil actual (RF-001, RF-002)."""
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.api import deps
from app.core import security
from app.models import Membresia, Reporte, EstadoReporte, Usuario
from app.schemas import (
    AuthOut,
    MembresiaOut,
    OrganizacionOut,
    PerfilMeOut,
    RegistroIn,
    UsuarioOut,
)

router = APIRouter()


def serializar_membresia(db: Session, m: Membresia) -> MembresiaOut:
    """Restituye suspensión vencida y convierte una Membresia ORM a MembresiaOut."""
    m = deps.restituir_suspension_si_vencio(db, m)
    motivo = m.sancion_motivo
    if not motivo and m.estado.value != "ACTIVO":
        ultimo_rep = (
            db.query(Reporte)
            .filter(
                Reporte.reportado_id == m.usuario_id,
                Reporte.organizacion_id == m.organizacion_id,
                Reporte.estado == EstadoReporte.RESUELTO,
                Reporte.nota_resolucion.isnot(None),
            )
            .order_by(Reporte.resuelto_en.desc(), Reporte.id.desc())
            .first()
        )
        if ultimo_rep and ultimo_rep.nota_resolucion:
            motivo = ultimo_rep.nota_resolucion

    org_out = (
        OrganizacionOut.model_validate(m.organizacion)
        if m.organizacion is not None
        else None
    )
    return MembresiaOut(
        id=m.id,
        usuario_id=m.usuario_id,
        organizacion_id=m.organizacion_id,
        rol=m.rol,
        estado=m.estado,
        identificador_interno=m.identificador_interno,
        sancion_motivo=motivo,
        motivo_sancion=motivo,
        sancion_hasta=m.sancion_hasta,
        fecha_fin_suspension=m.fecha_fin_suspension,
        organizacion=org_out,
    )


def obtener_membresias_usuario(db: Session, usuario_id: int) -> list[MembresiaOut]:
    """Obtiene todas las membresías del usuario y restituye suspensiones vencidas."""
    filas = (
        db.query(Membresia)
        .filter(Membresia.usuario_id == usuario_id)
        .order_by(Membresia.id.asc())
        .all()
    )
    return [serializar_membresia(db, m) for m in filas]


def registrar_nuevo_usuario(db: Session, datos: RegistroIn) -> AuthOut:
    """Crea un usuario nuevo verificando unicidad de correo y devuelve su sesión JWT."""
    correo_limpio = datos.correo.strip().lower()
    existente = db.query(Usuario).filter(Usuario.correo == correo_limpio).first()
    if existente is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ese correo ya tiene una cuenta. Inicia sesión o usa otro correo.",
        )

    nuevo = Usuario(
        nombre=datos.nombre.strip(),
        correo=correo_limpio,
        contrasena_hash=security.hashear_contrasena(datos.contrasena),
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    token = security.crear_token(nuevo.id)
    usuario_out = UsuarioOut.model_validate(nuevo)
    return AuthOut(
        access_token=token,
        token_type="bearer",
        token=token,
        usuario=usuario_out,
        membresias=[],
    )


@router.post(
    "/register",
    response_model=AuthOut,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar cuenta de usuario (RF-001)",
)
def register(
    datos: RegistroIn,
    db: Session = Depends(deps.get_db),
) -> Any:
    """Registra un nuevo usuario con nombre completo, correo único y contraseña >= 8 caracteres."""
    return registrar_nuevo_usuario(db, datos)


@router.post(
    "/login",
    response_model=AuthOut,
    status_code=status.HTTP_200_OK,
    summary="Iniciar sesión con correo y contraseña (RF-002)",
)
async def login(
    request: Request,
    db: Session = Depends(deps.get_db),
) -> Any:
    """Inicia sesión aceptando JSON ({correo, contrasena} o {usuario, contrasena})
    o formulario OAuth2 (username, password)."""
    content_type = (request.headers.get("content-type") or "").lower()
    correo = ""
    contrasena = ""

    if (
        "application/x-www-form-urlencoded" in content_type
        or "multipart/form-data" in content_type
    ):
        form = await request.form()
        correo = str(
            form.get("username")
            or form.get("correo")
            or form.get("usuario")
            or ""
        ).strip().lower()
        contrasena = str(
            form.get("password") or form.get("contrasena") or ""
        )
    else:
        try:
            body = await request.json()
        except Exception:
            body = {}
        if isinstance(body, dict):
            correo = str(
                body.get("correo")
                or body.get("usuario")
                or body.get("username")
                or ""
            ).strip().lower()
            contrasena = str(
                body.get("contrasena") or body.get("password") or ""
            )

    if not correo or not contrasena:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos. Verifica tus datos.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    usuario = db.query(Usuario).filter(Usuario.correo == correo).first()
    if usuario is None or not security.verificar_contrasena(
        contrasena, usuario.contrasena_hash
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos. Verifica tus datos.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = security.crear_token(usuario.id)
    membresias = obtener_membresias_usuario(db, usuario.id)
    usuario_out = UsuarioOut.model_validate(usuario)
    return AuthOut(
        access_token=token,
        token_type="bearer",
        token=token,
        usuario=usuario_out,
        membresias=membresias,
    )


@router.get(
    "/me",
    response_model=PerfilMeOut,
    status_code=status.HTTP_200_OK,
    summary="Obtener usuario autenticado y sus membresías",
)
def read_auth_me(
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Devuelve el usuario autenticado junto con sus membresías y organizaciones."""
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
