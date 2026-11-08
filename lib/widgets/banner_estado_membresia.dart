import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';

/// Banner fijo arriba cuando el usuario está ADVERTIDO, SUSPENDIDO o BANEADO
/// en la organización activa (RF-018, SRS 11 Bloque D). Si está ACTIVO no
/// ocupa espacio. Se redibuja solo cuando cambia la sesión.
class BannerEstadoMembresia extends StatelessWidget {
  const BannerEstadoMembresia({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = Servicios.i.sesion;
    return ListenableBuilder(
      listenable: sesion,
      builder: (context, _) {
        final m = sesion.membresiaActiva;
        final org = sesion.organizacionActiva;
        final usuario = sesion.usuario;
        if (m == null || org == null || usuario == null || m.estado == EstadoMembresia.activo) {
          return const SizedBox.shrink();
        }
        return FutureBuilder<String?>(
          future: Servicios.i.prestamos.motivoSancion(usuario.id, org.id),
          builder: (context, snap) {
            final motivo = snap.data;
            final sufijoMotivo = motivo == null ? '' : ' Motivo: $motivo.';
            final (icono, fondo, color) = switch (m.estado) {
              EstadoMembresia.advertido => (Icons.warning_amber_rounded, BColors.sol100, BColors.solTexto),
              EstadoMembresia.suspendido => (Icons.pause_circle_outline, BColors.errorFondo, BColors.error),
              _ => (Icons.block, BColors.errorFondo, BColors.error),
            };
            final String principal;
            final String? notas;
            switch (m.estado) {
              case EstadoMembresia.advertido:
                principal = 'Has recibido una advertencia del administrador.$sufijoMotivo';
                notas = null;
              case EstadoMembresia.suspendido:
                final hasta = m.sancionHasta;
                principal = 'Estás suspendido en ${org.nombre}'
                    '${hasta != null ? ' hasta ${Formato.fecha(hasta)}' : ''}.$sufijoMotivo';
                notas = 'Tus préstamos activos continúan con normalidad. '
                    'Esta suspensión no afecta tu cuenta en otras organizaciones.';
              default:
                principal = 'Fuiste retirado de esta organización de forma permanente.$sufijoMotivo';
                notas = null;
            }
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(16)),
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(icono, color: color, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(principal,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14, color: BColors.tinta)),
                            if (notas != null) ...[
                              const SizedBox(height: 4),
                              Text(notas,
                                  style: const TextStyle(fontSize: 13, color: BColors.tinta2)),
                            ],
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}

