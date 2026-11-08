import 'package:flutter/material.dart';

import '../screens/historial_screen.dart';
import '../screens/inicio_screen.dart';
import '../screens/mis_prestamos_screen.dart';
import '../screens/necesidades_screen.dart';
import '../screens/perfil_screen.dart';
import '../services/servicios.dart';
import '../theme/app_theme.dart';
import '../utils/nav.dart';

/// Barra de navegación inferior fija con las 5 pestañas oficiales del SRS v1.1
/// (Sección 11): Inicio, Necesidades, Mis préstamos, Historial y Perfil.
class BarraInferior extends StatelessWidget {
  const BarraInferior({super.key, required this.indiceActual});

  /// 0 = Inicio, 1 = Necesidades, 2 = Mis préstamos, 3 = Historial, 4 = Perfil.
  final int indiceActual;

  void _navegar(BuildContext context, int destino) {
    if (destino == indiceActual) return;
    if (destino == 0) {
      if (Navigator.of(context).canPop()) {
        Nav.alInicio(context);
      } else {
        Nav.reiniciarEn(context, const InicioScreen());
      }
      return;
    }
    final Widget pantalla = switch (destino) {
      1 => const NecesidadesScreen(),
      2 => const MisPrestamosScreen(),
      3 => const HistorialScreen(),
      _ => const PerfilScreen(),
    };
    if (indiceActual == 0) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => pantalla))
          .then((_) => Servicios.i.sesion.notificar());
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => pantalla),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: BColors.laguna700,
      unselectedItemColor: BColors.tinta3,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      currentIndex: indiceActual,
      onTap: (i) => _navegar(context, i),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          activeIcon: Icon(Icons.saved_search),
          label: 'Necesidades',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.handshake_outlined),
          activeIcon: Icon(Icons.handshake),
          label: 'Mis préstamos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: 'Historial',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
