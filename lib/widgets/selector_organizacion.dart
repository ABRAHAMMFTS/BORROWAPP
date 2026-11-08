import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/usuario.dart';
import '../screens/crear_organizacion_screen.dart';
import '../screens/unirme_paso_1_screen.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/nav.dart';
import 'componentes.dart';

/// Color del avatar de una organización (se elige según su id para que cada
/// una tenga siempre el mismo color).
Color colorDeOrganizacion(int id) {
  const paleta = [BColors.laguna700, BColors.info, BColors.sol700, BColors.exito, BColors.laguna500];
  return paleta[id % paleta.length];
}

/// Avatar cuadrado de una organización: color propio e ícono según su tipo.
class AvatarOrganizacion extends StatelessWidget {
  const AvatarOrganizacion(this.org, {super.key, this.tam = 32});
  final Organizacion org;
  final double tam;

  @override
  Widget build(BuildContext context) {
    // Fundido de 200 ms al cambiar de organización (DESIGN.md sección 8).
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorDeOrganizacion(org.id),
        borderRadius: BorderRadius.circular(tam * 0.3),
      ),
      child: Icon(iconoDeTipoOrganizacion(org.tipo), color: Colors.white, size: tam * 0.55),
    );
  }
}

/// Píldora de la organización activa. Va arriba en las pantallas principales
/// y al tocarla abre el selector para cambiar de organización (RF-019).
/// Se redibuja sola cuando cambia la organización activa.
class PildoraOrganizacion extends StatelessWidget {
  const PildoraOrganizacion({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    return ListenableBuilder(
      listenable: sesion,
      builder: (context, _) {
        final org = sesion.organizacionActiva;
        if (org == null) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            borderRadius: BorderRadius.circular(BRadios.chip),
            onTap: () => mostrarSelectorOrganizacion(context),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(BRadios.chip),
                border: Border.all(color: BColors.linea),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AvatarOrganizacion(org),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(org.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: BColors.tinta)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 20, color: BColors.tinta2),
              ]),
            ),
          ),
        );
      },
    );
  }
}

/// Chip "Admin" o "Miembro" de una membresía.
class ChipRol extends StatelessWidget {
  const ChipRol(this.rol, {super.key});
  final RolMembresia rol;

  @override
  Widget build(BuildContext context) {
    final admin = rol == RolMembresia.administrador;
    return ChipEstado(
      admin ? 'Admin' : 'Miembro',
      admin ? Icons.shield_outlined : Icons.person_outline,
      admin ? BColors.sol100 : BColors.bruma,
      admin ? BColors.solTexto : BColors.tinta2,
    );
  }
}

/// Hoja inferior "Tus organizaciones" (selector de organización, RF-019).
Future<void> mostrarSelectorOrganizacion(BuildContext context) {
  final sesion = Servicios.i.sesion;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(BRadios.hero))),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: BColors.lineaFuerte, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          const Text('Tus organizaciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: BColors.tinta)),
          const SizedBox(height: 4),
          const Text('Lo que ves en la app corresponde a la organización activa.',
              style: TextStyle(color: BColors.tinta2, fontSize: 13)),
          const SizedBox(height: 12),
          for (final m in sesion.membresias)
            if (sesion.organizacion(m.organizacionId) != null)
              Builder(builder: (_) {
                final o = sesion.organizacion(m.organizacionId)!;
                final activa = o.id == sesion.organizacionActiva?.id;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AvatarOrganizacion(o, tam: 44),
                  title: Text(o.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(o.tipo.etiqueta, style: const TextStyle(color: BColors.tinta2, fontSize: 13)),
                      ChipRol(m.rol),
                    ]),
                  ),
                  trailing: activa
                      ? const Icon(Icons.check_circle, color: BColors.laguna700)
                      : null,
                  onTap: () {
                    sesion.cambiarOrganizacion(o.id);
                    Navigator.pop(ctx);
                  },
                );
              }),
          const Divider(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.vpn_key_outlined, color: BColors.laguna700),
            title: const Text('Unirme con un código'),
            onTap: () {
              Navigator.pop(ctx);
              Nav.ir(context, const UnirmePaso1Screen());
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.add_business_outlined, color: BColors.laguna700),
            title: const Text('Crear una organización'),
            onTap: () {
              Navigator.pop(ctx);
              Nav.ir(context, const CrearOrganizacionScreen());
            },
          ),
        ]),
      ),
    ),
  );
}
