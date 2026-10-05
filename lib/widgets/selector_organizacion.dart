import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../screens/crear_organizacion_screen.dart';
import '../screens/unirme_paso_1_screen.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/nav.dart';

/// Color del avatar de una organización (se elige según su id para que cada
/// una tenga siempre el mismo color).
Color colorDeOrganizacion(int id) {
  const paleta = [BColors.laguna700, BColors.info, BColors.sol700, BColors.exito, BColors.laguna500];
  return paleta[id % paleta.length];
}

/// Avatar cuadrado con la inicial de la organización.
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
      child: Text(org.nombre[0].toUpperCase(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: tam * 0.45)),
    );
  }
}

/// Píldora de la organización activa. Va arriba en las pantallas principales
/// y al tocarla abre el selector para cambiar de organización (RF-019).
class PildoraOrganizacion extends StatelessWidget {
  const PildoraOrganizacion({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    final org = sesion.organizacionActiva;
    if (org == null) return const SizedBox.shrink();
    return InkWell(
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
    );
  }
}

/// Hoja inferior con las organizaciones del usuario (selector de organización).
Future<void> mostrarSelectorOrganizacion(BuildContext context) {
  final sesion = Servicios.i.sesion;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(BRadios.hero))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: BColors.lineaFuerte, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          const Text('Cambiar de organización',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
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
                  leading: AvatarOrganizacion(o, tam: 40),
                  title: Text(o.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${m.rol.etiqueta} · ${m.identificadorInterno}'),
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
