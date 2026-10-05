import 'package:flutter/material.dart';
import 'screens/bienvenida_screen.dart';
import 'theme/app_theme.dart';

import 'services/servicios.dart';

void main() {
  Servicios.iniciar();
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
