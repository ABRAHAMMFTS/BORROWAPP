import 'package:borrowapp/main.dart';
import 'package:borrowapp/services/servicios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el usuario puede registrar una cuenta y crear su comunidad', (
    tester,
  ) async {
    Servicios.iniciar();
    await tester.pumpWidget(const BorrowApp());

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    final camposRegistro = find.byType(TextField);
    await tester.enterText(camposRegistro.at(0), 'Administrador de prueba');
    await tester.enterText(camposRegistro.at(1), 'nuevo@borrowapp.com');
    await tester.enterText(camposRegistro.at(2), '12345678');
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear mi organización'));
    await tester.pumpAndSettle();

    final camposOrganizacion = find.byType(TextField);
    await tester.enterText(camposOrganizacion.at(0), 'Comunidad de prueba');
    await tester.enterText(camposOrganizacion.at(1), '1604');
    await tester.enterText(camposOrganizacion.at(2), 'Lobby central');
    await tester.tap(find.text('Crear organización'));
    await tester.pumpAndSettle();

    expect(find.text('¡Organización creada!'), findsOneWidget);
    expect(
      find.text('Ahora eres administrador de esta organización.'),
      findsOneWidget,
    );
    expect(find.textContaining('Código generado:'), findsOneWidget);
  });
}
