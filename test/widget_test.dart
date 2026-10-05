import 'package:flutter_test/flutter_test.dart';

import 'package:borrowapp/main.dart';

void main() {
  testWidgets('muestra la pantalla de bienvenida', (tester) async {
    await tester.pumpWidget(const BorrowApp());

    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
