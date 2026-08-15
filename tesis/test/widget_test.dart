// Test básico de humo.
//
// La app real (SismoApp) requiere inicializar Firebase, que no está disponible
// en el entorno de pruebas sin mocks. Este test valida que el framework de
// widgets monta correctamente, sirviendo de plantilla para pruebas futuras.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Monta un widget básico', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('SISMO'))),
    );

    expect(find.text('SISMO'), findsOneWidget);
  });
}
