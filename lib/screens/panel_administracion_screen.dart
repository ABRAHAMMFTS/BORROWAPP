import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../models/usuario.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/acciones.dart';
import '../widgets/codigo_organizacion.dart';
import '../widgets/componentes.dart';
import '../widgets/selector_organizacion.dart';
import '../widgets/tarjetas.dart';
import 'detalle_necesidad_screen.dart';
import 'prestamo_activo_screen.dart';

/// P16 · Panel de administración de la organización activa (RF-016, RF-017, Bloque E).
class PanelAdministracionScreen extends StatefulWidget {
  const PanelAdministracionScreen({super.key});

  @override
  State<PanelAdministracionScreen> createState() =>
      _PanelAdministracionScreenState();
}

class _DatosPanel {
  const _DatosPanel({
    required this.miembros,
    required this.publicaciones,
    required this.prestamos,
    required this.reportes,
  });

  final List<({Usuario usuario, Membresia membresia})> miembros;
  final List<Necesidad> publicaciones;
  final List<Prestamo> prestamos;
  final List<Reporte> reportes;

  int get reportesPendientes =>
      reportes.where((r) => r.estado == EstadoReporte.pendiente).length;
}

class _PanelAdministracionScreenState extends State<PanelAdministracionScreen> {
  late Future<_DatosPanel> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
    Servicios.i.sesion.addListener(_recargar);
  }

  @override
  void dispose() {
    Servicios.i.sesion.removeListener(_recargar);
    super.dispose();
  }

  void _recargar() {
    if (mounted) setState(() => _futuro = _cargar());
  }

  Future<_DatosPanel> _cargar() async {
    final sesion = Servicios.i.sesion;
    final admin = sesion.usuario;
    final org = sesion.organizacionActiva;
    if (admin == null || org == null) {
      return const _DatosPanel(
        miembros: [],
        publicaciones: [],
        prestamos: [],
        reportes: [],
      );
    }
    return _DatosPanel(
      miembros: await Servicios.i.organizaciones.miembros(org.id),
      publicaciones: await Servicios.i.necesidades.listar(org.id),
      prestamos: await Servicios.i.prestamos.deOrganizacion(org.id),
      reportes: await Servicios.i.prestamos.reportesDe(admin.id, org.id),
    );
  }

  Future<void> _modificarPuntoCentral(Organizacion org) async {
    final admin = Servicios.i.sesion.usuario;
    if (admin == null) return;
    final ctrl = TextEditingController(text: org.puntoCentral);
    final nuevoPunto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Modificar punto central',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BColors.sol100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: BColors.solTexto, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este cambio aplicará a los nuevos préstamos de tu organización',
                      style: TextStyle(
                        color: BColors.solTexto,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Punto central de entrega y devolución',
                hintText: 'Ej. Biblioteca Central, mostrador de atención',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (nuevoPunto == null || !mounted) return;
    final ok = await ejecutar(context, () async {
      await Servicios.i.organizaciones.cambiarPuntoCentral(
        adminId: admin.id,
        organizacionId: org.id,
        nuevoPunto: nuevoPunto,
      );
      await Servicios.i.sesion.recargar(activarOrganizacionId: org.id);
    });
    if (!ok || !mounted) return;
    mostrarMensaje(context, 'Punto central actualizado.');
    _recargar();
  }

  Future<void> _abrirVista(Widget pantalla) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    final org = sesion.organizacionActiva;

    if (org == null || !sesion.esAdminActivo) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel de administración')),
        backgroundColor: BColors.sal,
        body: const EstadoVacio(
          titulo: 'Sin permisos de administrador',
          texto: 'Solo el administrador de esta organización puede ver el panel.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de administración')),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: FutureBuilder<_DatosPanel>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: BColors.laguna700),
              );
            }
            if (snap.hasError) {
              return const EstadoVacio(
                titulo: 'No pudimos cargar el panel',
                texto: 'Vuelve atrás e inténtalo de nuevo.',
              );
            }
            final d = snap.data!;
            final pendientes = d.reportesPendientes;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Encabezado con nombre y código de 5 casillas
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: marea,
                    borderRadius: BorderRadius.circular(BRadios.hero),
                  ),
                  child: Column(
                    children: [
                      Text(
                        org.nombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        org.tipo.etiqueta,
                        style: const TextStyle(color: BColors.laguna100),
                      ),
                      const SizedBox(height: 16),
                      CodigoOrganizacion(codigo: org.codigo, claro: true),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: org.codigo),
                          );
                          if (!context.mounted) return;
                          mostrarMensaje(
                            context,
                            'Código ${org.codigo} copiado.',
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copiar código'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cuadrícula de 4 tarjetas con contadores reales
                Row(
                  children: [
                    Expanded(
                      child: _TarjetaContadorAdmin(
                        valor: '${d.miembros.length}',
                        etiqueta: 'Miembros',
                        icono: Icons.people_outline,
                        onTap: () => _abrirVista(
                          AdminMiembrosScreen(organizacion: org),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TarjetaContadorAdmin(
                        valor: '${d.publicaciones.length}',
                        etiqueta: 'Publicaciones',
                        icono: Icons.search,
                        onTap: () => _abrirVista(
                          AdminPublicacionesScreen(organizacion: org),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TarjetaContadorAdmin(
                        valor: '${d.prestamos.length}',
                        etiqueta: 'Préstamos',
                        icono: Icons.handshake_outlined,
                        onTap: () => _abrirVista(
                          AdminPrestamosScreen(organizacion: org),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TarjetaContadorAdmin(
                        valor: '${d.reportes.length}',
                        etiqueta: 'Reportes',
                        icono: Icons.report_problem_outlined,
                        insignia: pendientes > 0 ? '$pendientes' : null,
                        alerta: pendientes > 0,
                        onTap: () => _abrirVista(
                          AdminReportesScreen(organizacion: org),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Tarjeta Punto central de entrega y devolución
                TarjetaBlanca(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: BColors.laguna100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.place_outlined,
                              color: BColors.laguna800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Punto central de entrega y devolución',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        org.puntoCentral,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: BColors.tinta,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () => _modificarPuntoCentral(org),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Modificar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TarjetaContadorAdmin extends StatelessWidget {
  const _TarjetaContadorAdmin({
    required this.valor,
    required this.etiqueta,
    required this.icono,
    required this.onTap,
    this.insignia,
    this.alerta = false,
  });

  final String valor;
  final String etiqueta;
  final IconData icono;
  final VoidCallback onTap;
  final String? insignia;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    return TarjetaBlanca(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      color: alerta ? BColors.errorFondo.withValues(alpha: 0.45) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icono,
                color: alerta ? BColors.error : BColors.laguna700,
                size: 28,
              ),
              if (insignia != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: BColors.error,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$insignia pend.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  color: BColors.tinta3,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontFamily: 'Bricolage',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: alerta ? BColors.error : BColors.tinta,
            ),
          ),
          const SizedBox(height: 2),
          Text(etiqueta, style: const TextStyle(color: BColors.tinta2)),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. VISTA DE MIEMBROS (buscador, chip de estado, etiqueta Admin y revertir)
// ============================================================================

class AdminMiembrosScreen extends StatefulWidget {
  const AdminMiembrosScreen({super.key, required this.organizacion});

  final Organizacion organizacion;

  @override
  State<AdminMiembrosScreen> createState() => _AdminMiembrosScreenState();
}

class _AdminMiembrosScreenState extends State<AdminMiembrosScreen> {
  final _busquedaCtrl = TextEditingController();
  late Future<List<({Usuario usuario, Membresia membresia})>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<List<({Usuario usuario, Membresia membresia})>> _cargar() =>
      Servicios.i.organizaciones.miembros(widget.organizacion.id);

  void _recargar() {
    if (mounted) setState(() => _futuro = _cargar());
  }

  Future<void> _mostrarDetalleMiembro(
    Usuario u,
    Membresia m,
  ) async {
    final motivo = await Servicios.i.prestamos.motivoSancion(
      u.id,
      widget.organizacion.id,
    );
    if (!mounted) return;
    final revertir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          u.nombre,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChipRol(m.rol),
                ChipEstado.membresia(m.estado),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.organizacion.tipo.etiquetaIdentificador}: ${m.identificadorInterno}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(u.correo, style: const TextStyle(color: BColors.tinta2)),
            if (m.sancionHasta != null) ...[
              const SizedBox(height: 8),
              Text(
                'Suspendido hasta: ${Formato.fecha(m.sancionHasta!)}',
                style: const TextStyle(
                  color: BColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (motivo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Última nota de resolución: $motivo',
                style: const TextStyle(color: BColors.tinta2, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cerrar'),
          ),
          if (m.estado != EstadoMembresia.activo)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Revertir sanción'),
            ),
        ],
      ),
    );
    if (revertir != true || !mounted) return;
    await _confirmarYRevertir(u);
  }

  Future<void> _confirmarYRevertir(Usuario u) async {
    final confirmar = await confirmarDialogo(
      context,
      titulo: '¿Revertir sanción?',
      texto:
          '${u.nombre} volverá al estado Activo en ${widget.organizacion.nombre}.',
      confirmar: 'Sí, revertir',
    );
    if (!confirmar || !mounted) return;
    final admin = Servicios.i.sesion.usuario!;
    final ok = await ejecutar(
      context,
      () => Servicios.i.prestamos.revertirSancion(
        adminId: admin.id,
        usuarioId: u.id,
        organizacionId: widget.organizacion.id,
      ),
    );
    if (!ok || !mounted) return;
    mostrarMensaje(context, 'Sanción revertida. El miembro volvió a Activo.');
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final filtro = _busquedaCtrl.text.trim().toLowerCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Miembros')),
      backgroundColor: BColors.sal,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _busquedaCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o identificador...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filtro.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<({Usuario usuario, Membresia membresia})>>(
              future: _futuro,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: BColors.laguna700),
                  );
                }
                final todos = snap.data ?? [];
                final visibles = filtro.isEmpty
                    ? todos
                    : todos.where((item) {
                        return item.usuario.nombre
                                .toLowerCase()
                                .contains(filtro) ||
                            item.usuario.correo
                                .toLowerCase()
                                .contains(filtro) ||
                            item.membresia.identificadorInterno
                                .toLowerCase()
                                .contains(filtro);
                      }).toList();

                if (visibles.isEmpty) {
                  return const EstadoVacio(
                    titulo: 'Sin miembros que coincidan',
                    texto: 'Prueba buscando con otro nombre o identificador.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visibles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final u = visibles[i].usuario;
                    final m = visibles[i].membresia;
                    final sancionado = m.estado != EstadoMembresia.activo;
                    return TarjetaBlanca(
                      onTap: () => _mostrarDetalleMiembro(u, m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AvatarIniciales(u.iniciales, tam: 42),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            u.nombre,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (m.esAdministrador) ...[
                                          const SizedBox(width: 8),
                                          ChipRol(m.rol),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${widget.organizacion.tipo.etiquetaIdentificador}: ${m.identificadorInterno}',
                                      style: const TextStyle(
                                        color: BColors.tinta2,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ChipEstado.membresia(m.estado),
                            ],
                          ),
                          if (sancionado) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _confirmarYRevertir(u),
                                  icon: const Icon(Icons.restore, size: 18),
                                  label: const Text('Revertir sanción'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. VISTA DE PUBLICACIONES (todas las necesidades de la organización)
// ============================================================================

class AdminPublicacionesScreen extends StatefulWidget {
  const AdminPublicacionesScreen({super.key, required this.organizacion});

  final Organizacion organizacion;

  @override
  State<AdminPublicacionesScreen> createState() =>
      _AdminPublicacionesScreenState();
}

class _AdminPublicacionesScreenState extends State<AdminPublicacionesScreen> {
  late Future<List<Necesidad>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = Servicios.i.necesidades.listar(widget.organizacion.id);
  }

  void _recargar() {
    if (mounted) {
      setState(
        () => _futuro = Servicios.i.necesidades.listar(widget.organizacion.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicaciones de la organización')),
      backgroundColor: BColors.sal,
      body: FutureBuilder<List<Necesidad>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: BColors.laguna700),
            );
          }
          final lista = snap.data ?? [];
          if (lista.isEmpty) {
            return const EstadoVacio(
              titulo: 'No hay publicaciones',
              texto: 'Aún no se han publicado necesidades en esta organización.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => FilaNecesidad(
              lista[i],
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleNecesidadScreen(necesidad: lista[i]),
                  ),
                );
                _recargar();
              },
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 4. VISTA DE PRÉSTAMOS (todos los préstamos, destacando los "En conflicto")
// ============================================================================

class AdminPrestamosScreen extends StatefulWidget {
  const AdminPrestamosScreen({super.key, required this.organizacion});

  final Organizacion organizacion;

  @override
  State<AdminPrestamosScreen> createState() => _AdminPrestamosScreenState();
}

class _AdminPrestamosScreenState extends State<AdminPrestamosScreen> {
  late Future<List<Prestamo>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<Prestamo>> _cargar() async {
    final lista = await Servicios.i.prestamos.deOrganizacion(
      widget.organizacion.id,
    );
    // Los que están "En conflicto" van primero para atención inmediata.
    lista.sort((a, b) {
      if (a.enConflicto != b.enConflicto) {
        return a.enConflicto ? -1 : 1;
      }
      return b.id.compareTo(a.id);
    });
    return lista;
  }

  void _recargar() {
    if (mounted) setState(() => _futuro = _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Préstamos de la organización')),
      backgroundColor: BColors.sal,
      body: FutureBuilder<List<Prestamo>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: BColors.laguna700),
            );
          }
          final lista = snap.data ?? [];
          if (lista.isEmpty) {
            return const EstadoVacio(
              titulo: 'No hay préstamos registrados',
              texto: 'Cuando se confirmen préstamos en la organización aparecerán aquí.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final p = lista[i];
              return TarjetaBlanca(
                color: p.enConflicto
                    ? BColors.errorFondo.withValues(alpha: 0.35)
                    : null,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrestamoActivoScreen(prestamo: p),
                    ),
                  );
                  _recargar();
                },
                child: Row(
                  children: [
                    IconoCategoria(p.objeto),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.objeto,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          NombreUsuario(
                            p.solicitanteId,
                            prefijo: 'Solicita: ',
                            estilo: const TextStyle(
                              color: BColors.tinta2,
                              fontSize: 13,
                            ),
                          ),
                          NombreUsuario(
                            p.prestadorId,
                            prefijo: 'Presta: ',
                            estilo: const TextStyle(
                              color: BColors.tinta2,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${Formato.rango(p.fechaInicio, p.fechaFin)} · ${Formato.dinero(p.precioTotal, gratisSiCero: true)}',
                            style: const TextStyle(
                              color: BColors.tinta2,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ChipEstado.prestamo(p.estado),
                              if (p.enConflicto)
                                ChipEstado.prestamo(
                                  p.estado,
                                  enConflicto: true,
                                ),
                              ChipEstado.modalidad(p.modalidad),
                              if (p.vencido)
                                const ChipEstado(
                                  'Vencido',
                                  Icons.event_busy,
                                  BColors.errorFondo,
                                  BColors.error,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: BColors.tinta3),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// 5. VISTA DE REPORTES (Pestañas Pendientes | Resueltos)
// ============================================================================

class AdminReportesScreen extends StatefulWidget {
  const AdminReportesScreen({super.key, required this.organizacion});

  final Organizacion organizacion;

  @override
  State<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends State<AdminReportesScreen> {
  late Future<List<Reporte>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<Reporte>> _cargar() {
    final admin = Servicios.i.sesion.usuario!;
    return Servicios.i.prestamos.reportesDe(admin.id, widget.organizacion.id);
  }

  void _recargar() {
    if (mounted) setState(() => _futuro = _cargar());
  }

  Future<void> _abrirReporte(Reporte r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDetalleReporteScreen(reporteId: r.id),
      ),
    );
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes'),
          bottom: const TabBar(
            labelColor: BColors.laguna800,
            indicatorColor: BColors.laguna700,
            tabs: [
              Tab(text: 'Pendientes'),
              Tab(text: 'Resueltos'),
            ],
          ),
        ),
        backgroundColor: BColors.sal,
        body: FutureBuilder<List<Reporte>>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: BColors.laguna700),
              );
            }
            final todos = snap.data ?? [];
            final pendientes = todos
                .where((r) => r.estado == EstadoReporte.pendiente)
                .toList();
            final resueltos = todos
                .where((r) => r.estado == EstadoReporte.resuelto)
                .toList();

            return TabBarView(
              children: [
                _ListaReportesAdmin(
                  reportes: pendientes,
                  onTap: _abrirReporte,
                  vacioTitulo: 'No hay reportes pendientes',
                  vacioTexto: 'Todo marcha en orden en tu organización.',
                ),
                _ListaReportesAdmin(
                  reportes: resueltos,
                  onTap: _abrirReporte,
                  vacioTitulo: 'Aún no hay reportes resueltos',
                  vacioTexto:
                      'Los reportes que atiendas quedarán archivados aquí.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ListaReportesAdmin extends StatelessWidget {
  const _ListaReportesAdmin({
    required this.reportes,
    required this.onTap,
    required this.vacioTitulo,
    required this.vacioTexto,
  });

  final List<Reporte> reportes;
  final void Function(Reporte) onTap;
  final String vacioTitulo;
  final String vacioTexto;

  @override
  Widget build(BuildContext context) {
    if (reportes.isEmpty) {
      return EstadoVacio(titulo: vacioTitulo, texto: vacioTexto);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reportes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = reportes[i];
        final pendiente = r.estado == EstadoReporte.pendiente;
        return TarjetaBlanca(
          onTap: () => onTap(r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: pendiente ? BColors.errorFondo : BColors.exitoFondo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  pendiente
                      ? Icons.report_problem_outlined
                      : Icons.verified_outlined,
                  color: pendiente ? BColors.error : BColors.exito,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.tipo.etiqueta,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    NombreUsuario(
                      r.reportadoId,
                      prefijo: 'Reportado: ',
                      estilo: const TextStyle(
                        color: BColors.tinta,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    NombreUsuario(
                      r.reportanteId,
                      prefijo: 'Reportó: ',
                      estilo: const TextStyle(
                        color: BColors.tinta2,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BColors.tinta2,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ChipEstado(
                          r.estado.etiqueta,
                          pendiente ? Icons.schedule : Icons.check_circle_outline,
                          pendiente ? BColors.sol100 : BColors.exitoFondo,
                          pendiente ? BColors.solTexto : BColors.exito,
                        ),
                        if (r.sancion != null)
                          ChipEstado(
                            r.sancion!.etiqueta,
                            Icons.gavel_outlined,
                            BColors.errorFondo,
                            BColors.error,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: BColors.tinta3),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// 6 y 7. DETALLE DE REPORTE Y APLICACIÓN / REVERSIÓN DE SANCIÓN (RF-017)
// ============================================================================

class AdminDetalleReporteScreen extends StatefulWidget {
  const AdminDetalleReporteScreen({super.key, required this.reporteId});

  final int reporteId;

  @override
  State<AdminDetalleReporteScreen> createState() =>
      _AdminDetalleReporteScreenState();
}

class _VistaReporte {
  const _VistaReporte({
    required this.reporte,
    required this.prestamo,
    required this.membresiaReportado,
  });

  final Reporte reporte;
  final Prestamo? prestamo;
  final Membresia? membresiaReportado;
}

class _AdminDetalleReporteScreenState extends State<AdminDetalleReporteScreen> {
  late Future<_VistaReporte?> _futuro;
  Sancion _sancion = Sancion.advertencia;
  DateTime _suspensionHasta = DateTime.now().add(const Duration(days: 7));
  final _notaCtrl = TextEditingController();
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<_VistaReporte?> _cargar() async {
    final r = await Servicios.i.prestamos.reporte(widget.reporteId);
    if (r == null) return null;
    final p = await Servicios.i.prestamos.detalle(r.prestamoId);
    final m = await Servicios.i.organizaciones.membresia(
      r.reportadoId,
      r.organizacionId,
    );
    return _VistaReporte(reporte: r, prestamo: p, membresiaReportado: m);
  }

  void _recargar() {
    if (mounted) setState(() => _futuro = _cargar());
  }

  Future<void> _elegirFechaSuspension() async {
    final manana = DateTime.now().add(const Duration(days: 1));
    final elegida = await showDatePicker(
      context: context,
      firstDate: manana,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _suspensionHasta.isBefore(manana) ? manana : _suspensionHasta,
      helpText: 'Fecha de fin de la suspensión',
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _suspensionHasta = DateTime(
        elegida.year,
        elegida.month,
        elegida.day,
        23,
        59,
      );
    });
  }

  Future<void> _aplicarSancion(Reporte r) async {
    final confirmar = await confirmarDialogo(
      context,
      titulo: '¿Aplicar ${sancionTexto(_sancion)}?',
      texto:
          'Se actualizará el estado del miembro en esta organización y el reporte quedará resuelto.',
      confirmar: 'Sí, aplicar sanción',
      peligro: _sancion != Sancion.advertencia,
    );
    if (!confirmar || !mounted) return;
    final admin = Servicios.i.sesion.usuario!;
    setState(() => _procesando = true);
    final ok = await ejecutar(context, () async {
      await Servicios.i.prestamos.resolverReporte(
        adminId: admin.id,
        reporteId: r.id,
        sancion: _sancion,
        nota: _notaCtrl.text,
        suspensionHasta:
            _sancion == Sancion.suspension ? _suspensionHasta : null,
      );
      await Servicios.i.sesion.recargar(
        activarOrganizacionId: r.organizacionId,
      );
    });
    if (!mounted) return;
    setState(() => _procesando = false);
    if (!ok) return;
    mostrarMensaje(context, 'Sanción aplicada y reporte resuelto.');
    _recargar();
  }

  Future<void> _revertirSancion(Reporte r) async {
    final confirmar = await confirmarDialogo(
      context,
      titulo: '¿Revertir sanción?',
      texto:
          'La membresía de la persona reportada volverá al estado Activo en esta organización.',
      confirmar: 'Sí, revertir',
    );
    if (!confirmar || !mounted) return;
    final admin = Servicios.i.sesion.usuario!;
    setState(() => _procesando = true);
    final ok = await ejecutar(context, () async {
      await Servicios.i.prestamos.revertirSancion(
        adminId: admin.id,
        usuarioId: r.reportadoId,
        organizacionId: r.organizacionId,
      );
      await Servicios.i.sesion.recargar(
        activarOrganizacionId: r.organizacionId,
      );
    });
    if (!mounted) return;
    setState(() => _procesando = false);
    if (!ok) return;
    mostrarMensaje(context, 'Sanción revertida. El miembro volvió a Activo.');
    _recargar();
  }

  String sancionTexto(Sancion s) => s.etiqueta.toLowerCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del reporte')),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: FutureBuilder<_VistaReporte?>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: BColors.laguna700),
              );
            }
            final v = snap.data;
            if (v == null) {
              return const EstadoVacio(
                titulo: 'No encontramos este reporte',
                texto: 'Puede que ya no exista.',
              );
            }
            final r = v.reporte;
            final p = v.prestamo;
            final m = v.membresiaReportado;
            final pendiente = r.estado == EstadoReporte.pendiente;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Datos del reporte
                TarjetaBlanca(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.tipo.etiqueta,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          ChipEstado(
                            r.estado.etiqueta,
                            pendiente
                                ? Icons.schedule
                                : Icons.check_circle_outline,
                            pendiente ? BColors.sol100 : BColors.exitoFondo,
                            pendiente ? BColors.solTexto : BColors.exito,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _FilaUsuarioAdmin('Reportó', r.reportanteId),
                      _FilaUsuarioAdmin('Reportado', r.reportadoId),
                      FilaDato('Fecha', Formato.fechaHora(r.creadoEn)),
                      const Divider(height: 24),
                      const Text(
                        'Descripción del reporte',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(r.descripcion),
                    ],
                  ),
                ),

                // Préstamo asociado
                if (p != null) ...[
                  const SizedBox(height: 14),
                  TarjetaBlanca(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrestamoActivoScreen(prestamo: p),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        IconoCategoria(p.objeto),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Préstamo asociado',
                                style: TextStyle(
                                  color: BColors.tinta2,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                p.objeto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                Formato.rango(p.fechaInicio, p.fechaFin),
                                style: const TextStyle(
                                  color: BColors.tinta2,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: BColors.tinta3,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Si está PENDIENTE: formulario para aplicar sanción
                if (pendiente) ...[
                  const TituloSeccion('Decisión'),
                  for (final s in Sancion.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OpcionSancion(
                        sancion: s,
                        seleccionada: _sancion == s,
                        onTap: () => setState(() => _sancion = s),
                      ),
                    ),
                  if (_sancion == Sancion.suspension) ...[
                    const SizedBox(height: 6),
                    TextField(
                      readOnly: true,
                      onTap: _elegirFechaSuspension,
                      decoration: InputDecoration(
                        labelText: 'Suspensión hasta',
                        hintText: Formato.fecha(_suspensionHasta),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(
                        text: Formato.fecha(_suspensionHasta),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const TituloSeccion('Nota de resolución'),
                  TextField(
                    controller: _notaCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Explica el motivo de la decisión (mínimo 5 caracteres)...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  BotonPrimario(
                    'Aplicar sanción',
                    icono: Icons.gavel_outlined,
                    cargando: _procesando,
                    onPressed: () => _aplicarSancion(r),
                  ),
                ] else ...[
                  // Si está RESUELTO: resumen de la resolución y botón Revertir sanción
                  const TituloSeccion('Resolución aplicada'),
                  TarjetaBlanca(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.sancion != null)
                          FilaDato('Sanción aplicada', r.sancion!.etiqueta),
                        if (r.adminId != null)
                          _FilaUsuarioAdmin('Administrador', r.adminId!),
                        if (r.resueltoEn != null)
                          FilaDato(
                            'Fecha de resolución',
                            Formato.fechaHora(r.resueltoEn!),
                          ),
                        if (r.notaResolucion != null)
                          FilaDato('Nota', r.notaResolucion!),
                        if (m != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 120,
                                  child: Text(
                                    'Estado actual',
                                    style: TextStyle(
                                      color: BColors.tinta2,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                ChipEstado.membresia(m.estado),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (m != null && m.estado != EstadoMembresia.activo) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _procesando ? null : () => _revertirSancion(r),
                      icon: const Icon(Icons.restore),
                      label: const Text('Revertir sanción'),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilaUsuarioAdmin extends StatelessWidget {
  const _FilaUsuarioAdmin(this.etiqueta, this.usuarioId);
  final String etiqueta;
  final int usuarioId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              etiqueta,
              style: const TextStyle(color: BColors.tinta2, fontSize: 13),
            ),
          ),
          Expanded(
            child: NombreUsuario(
              usuarioId,
              estilo: const TextStyle(
                fontWeight: FontWeight.w600,
                color: BColors.tinta,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionSancion extends StatelessWidget {
  const _OpcionSancion({
    required this.sancion,
    required this.seleccionada,
    required this.onTap,
  });

  final Sancion sancion;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final descripcion = switch (sancion) {
      Sancion.advertencia =>
        'El miembro recibe un aviso pero puede seguir operando.',
      Sancion.suspension =>
        'No podrá publicar, ofrecer ni aceptar hasta la fecha de fin.',
      Sancion.baneo =>
        'Retiro permanente de las operaciones en esta organización.',
    };
    return Material(
      color: seleccionada ? BColors.laguna50 : Colors.white,
      borderRadius: BorderRadius.circular(BRadios.campo),
      child: InkWell(
        borderRadius: BorderRadius.circular(BRadios.campo),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BRadios.campo),
            border: Border.all(
              color: seleccionada ? BColors.laguna700 : BColors.linea,
              width: seleccionada ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                seleccionada
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: seleccionada ? BColors.laguna700 : BColors.tinta3,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sancion.etiqueta,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: BColors.tinta,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        color: BColors.tinta2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
