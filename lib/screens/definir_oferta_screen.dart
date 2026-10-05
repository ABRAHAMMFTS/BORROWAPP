import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ofertas_recibidas_screen.dart';

// P11: Definir oferta
class DefinirOfertaScreen extends StatelessWidget {
  const DefinirOfertaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Definir Oferta'),
      ),
      backgroundColor: BColors.sal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Condiciones de la oferta', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Campos (gratis o alquiler, etc.)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Precio',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: 'Por día',
                      decoration: InputDecoration(
                        labelText: 'Unidad',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: ['Por hora', 'Por día'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Fecha y hora estimada de entrega',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              // Tarjeta total calculado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: BColors.laguna50, borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL CALCULADO', style: TextStyle(color: BColors.tinta2)),
                    Text('\$30.000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: BColors.laguna700)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Por ahora simulamos que al publicar pasamos a ver las ofertas (P12)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OfertasRecibidasScreen()),
                    );
                  },
                  child: const Text('Publicar mis condiciones'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
