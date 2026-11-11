import 'package:flutter/material.dart';
import 'data/api_repository.dart';
import 'screens/bienvenida_screen.dart';
import 'services/servicios.dart';
import 'theme/app_theme.dart';

void main() {
  // Por defecto se conecta a la API FastAPI (http://127.0.0.1:8000 o API_URL).
  // Para probar sin servidor se puede pasar Servicios.iniciar(MemoryRepository()).
  Servicios.iniciar(ApiRepository());
  runApp(const BorrowApp());
}

class BorrowApp extends StatelessWidget {
  const BorrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BorrowApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const BienvenidaScreen(), // P01: Bienvenida
    );
  }
}
