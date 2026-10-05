import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'confirmar_aceptacion_screen.dart';

// P12: Ofertas recibidas
class OfertasRecibidasScreen extends StatelessWidget {
  const OfertasRecibidasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas recibidas'),
      ),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Ofertas para tu Taladro percutor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: BColors.laguna100, child: Icon(Icons.person)),
                      title: const Text('Jesús Vergara'),
                      subtitle: const Text('\$10.000 / día'),
                      trailing: const Text('\$30.000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ConfirmarAceptacionScreen()),
                          );
                        },
                        child: const Text('Aceptar esta oferta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
