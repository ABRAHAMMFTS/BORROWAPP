import 'package:flutter/material.dart';

/// Colores del sistema de diseño "Marea" (ver DESIGN.md, sección 2 y 11).
/// Nada de negro puro ni grises puros: todos los neutros tienen tinte verdoso.
class BColors {
  // Laguna (color de marca, primario)
  static const laguna50 = Color(0xFFEAF8F6);
  static const laguna100 = Color(0xFFC9EFEA);
  static const laguna200 = Color(0xFF97E0D6);
  static const laguna300 = Color(0xFF5CCBBE);
  static const laguna400 = Color(0xFF2DB1A3);
  static const laguna500 = Color(0xFF109588);
  static const laguna600 = Color(0xFF0B786F);
  static const laguna700 = Color(0xFF0A5F5A); // primario: botones, íconos, enlaces
  static const laguna800 = Color(0xFF0A4A47);
  static const laguna900 = Color(0xFF0A3634);

  // Sol (acento: "esto requiere tu atención")
  static const sol50 = Color(0xFFFFF8E1);
  static const sol100 = Color(0xFFFFEDB3);
  static const sol400 = Color(0xFFFFC233);
  static const sol500 = Color(0xFFF5A800);
  static const sol700 = Color(0xFF8F5B00);
  static const solTexto = Color(0xFF6F4700);

  // Neutros con tinte
  static const sal = Color(0xFFF3F7F6); // fondo de pantallas
  static const bruma = Color(0xFFE9F0EE);
  static const linea = Color(0xFFDCE5E3);
  static const lineaFuerte = Color(0xFFC3D0CD);
  static const tinta = Color(0xFF0E1F1E); // texto principal
  static const tinta2 = Color(0xFF4B5F5D); // texto secundario
  static const tinta3 = Color(0xFF7A8D8B); // placeholders / deshabilitado

  // Sistema
  static const error = Color(0xFFD92D20);
  static const errorFondo = Color(0xFFFEE4E2);
  static const exito = Color(0xFF157A3E);
  static const exitoFondo = Color(0xFFDCF5E5);
  static const info = Color(0xFF1E4FD8);
  static const infoFondo = Color(0xFFE0E9FF);
}

/// Degradado "Marea": uno de los 4 usos permitidos (bienvenida, hero del
/// inicio, pantallas de éxito y tarjeta del panel de administración).
const marea = LinearGradient(
  begin: Alignment(-0.34, -0.94),
  end: Alignment(0.34, 0.94),
  colors: [Color(0xFF0A3634), Color(0xFF0A5F5A), Color(0xFF109588)],
  stops: [0.0, 0.55, 1.0],
);

/// Radios del sistema (DESIGN.md sección 4).
class BRadios {
  static const double chip = 999;
  static const double campo = 14;
  static const double tarjeta = 20;
  static const double hero = 28;
}

/// Tema general de la aplicación.
class AppTheme {
  static ThemeData get lightTheme {
    final base = ColorScheme.fromSeed(
      seedColor: BColors.laguna700,
      primary: BColors.laguna700,
      secondary: BColors.sol400,
      error: BColors.error,
      surface: Colors.white,
    );

    OutlineInputBorder borde(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(BRadios.campo),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: BColors.sal,
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: BColors.tinta, fontWeight: FontWeight.w800, fontSize: 34, height: 1.18),
        headlineLarge: TextStyle(color: BColors.tinta, fontWeight: FontWeight.w700, fontSize: 26, height: 1.2),
        headlineMedium: TextStyle(color: BColors.tinta, fontWeight: FontWeight.w700, fontSize: 20, height: 1.25),
        bodyLarge: TextStyle(color: BColors.tinta, fontSize: 15, height: 1.45),
        bodyMedium: TextStyle(color: BColors.tinta2, fontSize: 13, height: 1.45),
        labelLarge: TextStyle(color: BColors.tinta, fontSize: 15, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: BColors.tinta2, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BColors.sal,
        surfaceTintColor: Colors.transparent,
        foregroundColor: BColors.tinta,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            color: BColors.tinta, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: BColors.tinta2),
        hintStyle: const TextStyle(color: BColors.tinta3),
        border: borde(BColors.linea),
        enabledBorder: borde(BColors.linea),
        focusedBorder: borde(BColors.laguna500, 2),
        errorBorder: borde(BColors.error),
        focusedErrorBorder: borde(BColors.error, 2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BColors.laguna700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: BColors.bruma,
          disabledForegroundColor: BColors.tinta3,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BRadios.tarjeta)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BColors.laguna700,
          side: const BorderSide(color: BColors.laguna700, width: 1.5),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BRadios.tarjeta)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BColors.laguna700,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: BColors.laguna100,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: s.contains(WidgetState.selected)
                  ? BColors.laguna800
                  : BColors.tinta2,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? BColors.laguna800
                  : BColors.tinta2,
            )),
      ),
      dividerTheme: const DividerThemeData(color: BColors.linea, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BColors.tinta,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BRadios.hero)),
      ),
    );
  }
}
