"""Endpoints de Organizaciones y Membresías (RF-003, RF-004, RF-005, RF-016)."""
import secrets
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.api import deps
from app.api.routes.auth import obtener_membresias_usuario, serializar_membresia
from app.models import (
    EstadoMembresia,
    Membresia,
    Organizacion,
    Rol,
    Usuario,
)
from app.schemas import (
    MembresiaOut,
    MiembroOut,
    OrganizacionCreadaOut,
    OrganizacionCrearIn,
    OrganizacionOut,
    OrganizacionPreview,
    PuntoCentralIn,
    UnirseIn,
    UnirseOrgIn,
    UsuarioResumen,
)

router = APIRouter()

# Alfabeto sin caracteres ambiguos (sin 0, O, 1, I, L) según RF-003.
ALFABETO_CODIGO = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"


def _generar_codigo_unico(db: Session) -> str:
    """Genera un código único de 5 caracteres usando ALFABETO_CODIGO."""
    for _ in range(100):
        codigo = "".join(secrets.choice(ALFABETO_CODIGO) for _ in range(5))
        existe = (
            db.query(Organizacion)
            .filter(func.upper(Organizacion.codigo) == codigo)
            .first()
        )
        if existe is None:
            return codigo
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="No fue posible generar un código único para la organización.",
    )


@router.post(
    "",
    response_model=OrganizacionCreadaOut,
    status_code=status.HTTP_201_CREATED,
    summary="Crear una organización (RF-003)",
)
@router.post(
    "/",
    response_model=OrganizacionCreadaOut,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False,
)
def crear_organizacion(
    datos: OrganizacionCrearIn,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Crea una nueva organización con código único de 5 caracteres y asigna al creador
    como ADMINISTRADOR con estado ACTIVO."""
    codigo = _generar_codigo_unico(db)
    org = Organizacion(
        nombre=datos.nombre.strip(),
        tipo=datos.tipo,
        codigo=codigo,
        punto_central=datos.punto_central.strip(),
        creada_por=current_user.id,
    )
    db.add(org)
    db.flush()

    membresia = Membresia(
        usuario_id=current_user.id,
        organizacion_id=org.id,
        rol=Rol.ADMINISTRADOR,
        estado=EstadoMembresia.ACTIVO,
        identificador_interno=datos.identificador_interno.strip() or "ADMIN-01",
    )
    db.add(membresia)
    db.commit()
    db.refresh(org)
    db.refresh(membresia)

    membresia_out = serializar_membresia(db, membresia)
    return OrganizacionCreadaOut(
        id=org.id,
        nombre=org.nombre,
        tipo=org.tipo,
        codigo=org.codigo,
        punto_central=org.punto_central,
        creada_por=org.creada_por,
        membresia=membresia_out,
    )


@router.get(
    "/my-memberships",
    response_model=list[MembresiaOut],
    status_code=status.HTTP_200_OK,
    summary="Listar mis membresías y organizaciones (RF-005)",
)
def listar_mis_membresias(
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Devuelve todas las membresías y organizaciones del usuario actual,
    restituyendo automáticamente suspensiones vencidas."""
    return obtener_membresias_usuario(db, current_user.id)


@router.get(
    "/by-code/{codigo}",
    response_model=OrganizacionPreview,
    status_code=status.HTTP_200_OK,
    summary="Buscar organización por código de 5 caracteres (RF-004 paso 1)",
)
def buscar_por_codigo(
    codigo: str,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Busca una organización por su código (insensible a mayúsculas)."""
    codigo_limpio = codigo.strip().upper()
    org = (
        db.query(Organizacion)
        .filter(func.upper(Organizacion.codigo) == codigo_limpio)
        .first()
    )
    if org is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Este código no corresponde a ninguna organización. Verifica con tu administrador.",
        )

    total = (
        db.query(Membresia)
        .filter(Membresia.organizacion_id == org.id)
        .count()
    )
    return OrganizacionPreview(
        id=org.id,
        nombre=org.nombre,
        tipo=org.tipo,
        codigo=org.codigo,
        punto_central=org.punto_central,
        creada_por=org.creada_por,
        total_miembros=total,
    )


@router.post(
    "/{org_id}/join",
    response_model=MembresiaOut,
    status_code=status.HTTP_201_CREATED,
    summary="Unirse a una organización con identificador interno (RF-004 paso 2)",
)
def unirse_a_organizacion(
    org_id: int,
    datos: UnirseOrgIn,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Crea la membresía MIEMBRO en estado ACTIVO para el usuario actual en {org_id}."""
    org = db.query(Organizacion).filter(Organizacion.id == org_id).first()
    if org is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Este código no corresponde a ninguna organización. Verifica con tu administrador.",
        )

    existente = (
        db.query(Membresia)
        .filter(
            Membresia.usuario_id == current_user.id,
            Membresia.organizacion_id == org.id,
        )
        .first()
    )
    if existente is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya perteneces a esta organización.",
        )

    nueva = Membresia(
        usuario_id=current_user.id,
        organizacion_id=org.id,
        rol=Rol.MIEMBRO,
        estado=EstadoMembresia.ACTIVO,
        identificador_interno=datos.identificador_interno.strip(),
    )
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return serializar_membresia(db, nueva)


@router.post(
    "/join",
    response_model=MembresiaOut,
    status_code=status.HTTP_201_CREATED,
    summary="Unirse a una organización enviando código e identificador interno",
)
def unirse_por_codigo(
    datos: UnirseIn,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Alternativa directa para unirse enviando código e identificador_interno en un solo paso."""
    codigo_limpio = datos.codigo.strip().upper()
    org = (
        db.query(Organizacion)
        .filter(func.upper(Organizacion.codigo) == codigo_limpio)
        .first()
    )
    if org is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Este código no corresponde a ninguna organización. Verifica con tu administrador.",
        )

    existente = (
        db.query(Membresia)
        .filter(
            Membresia.usuario_id == current_user.id,
            Membresia.organizacion_id == org.id,
        )
        .first()
    )
    if existente is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya perteneces a esta organización.",
        )

    nueva = Membresia(
        usuario_id=current_user.id,
        organizacion_id=org.id,
        rol=Rol.MIEMBRO,
        estado=EstadoMembresia.ACTIVO,
        identificador_interno=datos.identificador_interno.strip(),
    )
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return serializar_membresia(db, nueva)


@router.get(
    "/{org_id}/members",
    response_model=list[MiembroOut],
    status_code=status.HTTP_200_OK,
    summary="Listar miembros de una organización (RF-017)",
)
def listar_miembros_organizacion(
    org_id: int,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Lista las membresías y datos básicos de los usuarios de la organización."""
    deps.exigir_miembro(db, current_user.id, org_id)

    membresias = (
        db.query(Membresia)
        .filter(Membresia.organizacion_id == org_id)
        .order_by(Membresia.id.asc())
        .all()
    )

    resultado: list[MiembroOut] = []
    for m in membresias:
        m_actualizada = serializar_membresia(db, m)
        u = m.usuario
        resumen = UsuarioResumen.model_validate(u)
        resultado.append(
            MiembroOut(
                id=m.id,
                membresia_id=m.id,
                usuario_id=u.id,
                organizacion_id=m.organizacion_id,
                usuario=resumen,
                nombre=u.nombre,
                correo=u.correo,
                iniciales=u.iniciales,
                rol=m.rol,
                estado=m_actualizada.estado,
                identificador_interno=m.identificador_interno,
                sancion_motivo=m_actualizada.sancion_motivo,
                sancion_hasta=m_actualizada.sancion_hasta,
                fecha_fin_suspension=m_actualizada.fecha_fin_suspension,
            )
        )
    return resultado


@router.patch(
    "/{org_id}/central-point",
    response_model=OrganizacionOut,
    status_code=status.HTTP_200_OK,
    summary="Modificar el punto central de la organización (RF-016)",
)
def actualizar_punto_central(
    org_id: int,
    datos: PuntoCentralIn,
    current_user: Usuario = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """Exclusivo para el ADMINISTRADOR de la organización. Actualiza punto_central
    para los préstamos futuros sin alterar los préstamos existentes."""
    deps.exigir_admin_organizacion(db, current_user.id, org_id)

    org = db.query(Organizacion).filter(Organizacion.id == org_id).first()
    if org is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="La organización no existe.",
        )

    org.punto_central = datos.punto_central.strip()
    db.add(org)
    db.commit()
    db.refresh(org)
    return OrganizacionOut.model_validate(org)

