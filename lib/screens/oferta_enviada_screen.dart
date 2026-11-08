import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/operaciones.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../utils/nav.dart';
import '../widgets/componentes.dart';
import 'necesidades_screen.dart';

/// P11.1 · Oferta enviada: resumen de las condiciones y estado "Pendiente".
class OfertaEnviadaScreen extends StatelessWidget {
  const OfertaEnviadaScreen(
      {super.key, required this.necesidad, required this.oferta});

  final Necesidad necesidad;
  final Oferta oferta;

  @override
  Widget build(BuildContext context) {
    final total = Servicios.i.necesidades.calcularTotal(
      necesidad: necesidad,
      modalidad: oferta.modalidad,
      precio: oferta.precio,
      unidad: oferta.unidadCobro,
    );
    final punto =
        Servicios.i.sesion.organizacion(necesidad.organizacionId)?.puntoCentral;
    final alquiler = oferta.modalidad == Modalidad.alquiler;
    return Scaffold(
      backgroundColor: BColors.sal,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Oferta enviada'),
      ),
      bottomNavigationBar: BarraAccion(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          BotonPrimario(
            'Ver mis ofertas',
            onPressed: () {
              // Vuelve al inicio y abre "Mis ofertas".
              Nav.alInicio(context);
              Nav.ir(context, const NecesidadesScreen(tabInicial: 2));
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Nav.alInicio(context),
            child: const Text('Ir al inicio'),
          ),
        ]),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Center(
              child: Icon(Icons.check_circle, size: 72, color: BColors.exito),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('¡Publicaste tus condiciones!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('El solicitante decidirá si las acepta.',
                  style: TextStyle(color: BColors.tinta2)),
            ),
            const SizedBox(height: 24),
            TarjetaBlanca(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconoCategoria(necesidad.objeto),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(necesidad.objeto,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  ),
                  ChipEstado.oferta(oferta.estado),
                ]),
                const SizedBox(height: 8),
                FilaDato('Modalidad', oferta.modalidad.etiqueta),
                if (alquiler)
                  FilaDato(
                      'Precio',
                      '${Formato.dinero(oferta.precio ?? 0)} / '
                          '${oferta.unidadCobro == UnidadCobro.hora ? 'hora' : 'día'}'),
                FilaDato('Total', Formato.dinero(total, gratisSiCero: true)),
                FilaDato('Entrega', Formato.fechaHora(oferta.fechaEntrega)),
                if (punto != null) FilaDato('Punto central', punto),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

