import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'definir_oferta_screen.dart';

// P10: Detalle de necesidad (Necesidad de otro miembro)
class DetalleNecesidadScreen extends StatelessWidget {
  const DetalleNecesidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Necesidad'),
      ),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar y nombre
              const CircleAvatar(radius: 30, backgroundColor: BColors.bruma, child: Icon(Icons.person, color: BColors.tinta3)),
              const SizedBox(height: 8),
              const Text('Camilo Junco', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('Hace 2 horas', style: TextStyle(color: BColors.tinta2)),
              const SizedBox(height: 24),
              // Detalles del objeto
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: BColors.laguna100, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.handyman, size: 40, color: BColors.laguna700),
              ),
              const SizedBox(height: 16),
              const Text('Taladro percutor', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Para colgar unos cuadros en mi apartamento. Lo devuelvo el mismo día.'),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DefinirOfertaScreen()),
                    );
                  },
                  child: const Text('Tengo este objeto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
