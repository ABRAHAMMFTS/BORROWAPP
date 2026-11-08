import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_estado_membresia.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/componentes.dart';
import '../widgets/selector_organizacion.dart';
import '../widgets/tarjetas.dart';
import 'detalle_necesidad_screen.dart';
import 'publicar_necesidad_screen.dart';

/// P15 · Necesidades de la organización activa, en tres pestañas:
/// "De la comunidad", "Mis necesidades" y "Mis ofertas".
class NecesidadesScreen extends StatefulWidget {
  const NecesidadesScreen({super.key, this.tabInicial = 0});

  /// 0 = De la comunidad, 1 = Mis necesidades, 2 = Mis ofertas.
  final int tabInicial;

  @override
  State<NecesidadesScreen> createState() => _NecesidadesScreenState();
}

class _Datos {
  const _Datos(this.necesidades, this.misOfertas);
  final List<Necesidad> necesidades;
  final List<({Necesidad necesidad, Oferta oferta})> misOfertas;
}

class _NecesidadesScreenState extends State<NecesidadesScreen> {
  late Future<_Datos> _futuro;

  // Filtro por pestaña. null = "Todas".
  EstadoNecesidad? _filtroComunidad;
  EstadoNecesidad? _filtroMias;
  EstadoOferta? _filtroOfertas;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
    // Al cambiar de organización activa se vuelve a cargar la lista.
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

  Future<_Datos> _cargar() async {
    final sesion = Servicios.i.sesion;
    final org = sesion.organizacionActiva;
    final usuario = sesion.usuario;
    if (org == null || usuario == null) return const _Datos([], []);
    final servicio = Servicios.i.necesidades;
    return _Datos(
      await servicio.listar(org.id),
      await servicio.misOfertas(usuario.id, org.id),
    );
  }

  Future<void> _abrir(Necesidad n) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleNecesidadScreen(necesidad: n)),
    );
    _recargar();
  }

  Future<void> _publicar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PublicarNecesidadScreen()),
    );
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    final yo = sesion.usuario?.id;
    final bloqueado = sesion.bloqueadoEnActiva;

    return DefaultTabController(
      length: 3,
      initialIndex: widget.tabInicial.clamp(0, 2),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Necesidades'),
          bottom: const TabBar(
            labelColor: BColors.laguna800,
            indicatorColor: BColors.laguna700,
            tabs: [
              Tab(text: 'De la comunidad'),
              Tab(text: 'Mis necesidades'),
              Tab(text: 'Mis ofertas'),
            ],
          ),
        ),
        backgroundColor: BColors.sal,
        bottomNavigationBar: const BarraInferior(indiceActual: 1),
        // RF-018: el botón se deshabilita si está suspendido o baneado.
        floatingActionButton: FloatingActionButton.extended(
          onPressed: bloqueado ? null : _publicar,
          backgroundColor: bloqueado ? BColors.bruma : BColors.laguna700,
          foregroundColor: bloqueado ? BColors.tinta3 : Colors.white,
          elevation: bloqueado ? 0 : null,
          icon: const Icon(Icons.add),
          label: const Text('Publicar'),
        ),
        body: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(alignment: Alignment.centerLeft, child: PildoraOrganizacion()),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: BannerEstadoMembresia(),
          ),
          Expanded(
            child: FutureBuilder<_Datos>(
              future: _futuro,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                      child: CircularProgressIndicator(color: BColors.laguna700));
                }
                if (snap.hasError || yo == null) {
                  return const EstadoVacio(
                    titulo: 'No pudimos cargar las necesidades',
                    texto: 'Inténtalo de nuevo en unos segundos.',
                  );
                }
                final datos = snap.data!;
                final comunidad =
                    datos.necesidades.where((n) => n.solicitanteId != yo).toList();
                final mias =
                    datos.necesidades.where((n) => n.solicitanteId == yo).toList();

                return TabBarView(children: [
                  _ListaNecesidades(
                    items: comunidad,
                    filtro: _filtroComunidad,
                    onFiltro: (f) => setState(() => _filtroComunidad = f),
                    onTap: _abrir,
                    vacioTitulo: 'Aún no hay necesidades de tu comunidad',
                    vacioTexto: 'Cuando alguien publique lo que necesita, lo verás aquí.',
                  ),
                  _ListaNecesidades(
                    items: mias,
                    filtro: _filtroMias,
                    onFiltro: (f) => setState(() => _filtroMias = f),
                    onTap: _abrir,
                    vacioTitulo: 'Aún no has publicado necesidades',
                    vacioTexto: 'Publica lo que necesitas y los demás podrán ofrecértelo.',
                    accion: bloqueado ? null : 'Publicar una necesidad',
                    onAccion: _publicar,
                  ),
                  _ListaMisOfertas(
                    items: datos.misOfertas,
                    filtro: _filtroOfertas,
                    onFiltro: (f) => setState(() => _filtroOfertas = f),
                    onTap: _abrir,
                  ),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

/// Fila de chips para filtrar por estado. `null` es "Todas".
class _FiltrosEstado<T extends Enum> extends StatelessWidget {
  const _FiltrosEstado({
    required this.valores,
    required this.etiqueta,
    required this.actual,
    required this.onCambio,
  });

  final List<T> valores;
  final String Function(T) etiqueta;
  final T? actual;
  final ValueChanged<T?> onCambio;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        ChoiceChip(
          label: const Text('Todas'),
          selected: actual == null,
          onSelected: (_) => onCambio(null),
        ),
        for (final v in valores) ...[
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(etiqueta(v)),
            selected: actual == v,
            onSelected: (_) => onCambio(v),
          ),
        ],
      ]),
    );
  }
}

class _ListaNecesidades extends StatelessWidget {
  const _ListaNecesidades({
    required this.items,
    required this.filtro,
    required this.onFiltro,
    required this.onTap,
    required this.vacioTitulo,
    required this.vacioTexto,
    this.accion,
    this.onAccion,
  });

  final List<Necesidad> items;
  final EstadoNecesidad? filtro;
  final ValueChanged<EstadoNecesidad?> onFiltro;
  final void Function(Necesidad) onTap;
  final String vacioTitulo;
  final String vacioTexto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final visibles =
        filtro == null ? items : items.where((n) => n.estado == filtro).toList();
    return Column(children: [
      _FiltrosEstado<EstadoNecesidad>(
        valores: EstadoNecesidad.values,
        etiqueta: (e) => e.etiqueta,
        actual: filtro,
        onCambio: onFiltro,
      ),
      Expanded(
        child: visibles.isEmpty
            ? (items.isEmpty
                ? EstadoVacio(
                    titulo: vacioTitulo,
                    texto: vacioTexto,
                    accion: accion,
                    onAccion: onAccion)
                : const EstadoVacio(
                    titulo: 'Sin resultados',
                    texto: 'No hay necesidades con ese estado.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount: visibles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) =>
                    FilaNecesidad(visibles[i], onTap: () => onTap(visibles[i])),
              ),
      ),
    ]);
  }
}

class _ListaMisOfertas extends StatelessWidget {
  const _ListaMisOfertas({
    required this.items,
    required this.filtro,
    required this.onFiltro,
    required this.onTap,
  });

  final List<({Necesidad necesidad, Oferta oferta})> items;
  final EstadoOferta? filtro;
  final ValueChanged<EstadoOferta?> onFiltro;
  final void Function(Necesidad) onTap;

  @override
  Widget build(BuildContext context) {
    final visibles = filtro == null
        ? items
        : items.where((x) => x.oferta.estado == filtro).toList();
    return Column(children: [
      _FiltrosEstado<EstadoOferta>(
        valores: EstadoOferta.values,
        etiqueta: (e) => e.etiqueta,
        actual: filtro,
        onCambio: onFiltro,
      ),
      Expanded(
        child: visibles.isEmpty
            ? (items.isEmpty
                ? const EstadoVacio(
                    titulo: 'Aún no has ofrecido nada',
                    texto:
                        'Cuando alguien necesite algo que tengas, toca "Tengo este objeto".')
                : const EstadoVacio(
                    titulo: 'Sin resultados',
                    texto: 'No hay ofertas con ese estado.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount: visibles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final x = visibles[i];
                  return FilaNecesidad(
                    x.necesidad,
                    onTap: () => onTap(x.necesidad),
                    extra: 'Tu oferta: ${x.oferta.estado.etiqueta}',
                  );
                },
              ),
      ),
    ]);
  }
}
