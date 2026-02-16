import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora_frontend/main.dart';
// 1. Importar el servicio original
import 'package:finora_frontend/core/connectivity/connectivity_service.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // 2. Instanciar el servicio falso (Mock)
    final mockConnectivityService = MockConnectivityService();

    // 3. Pasarlo al constructor de MyApp (quitando el 'const')
    await tester.pumpWidget(
      MyApp(connectivityService: mockConnectivityService),
    );

    // NOTA: Tu test original verifica un contador, pero tu App ahora muestra
    // un Splash o Login. Este test compilará, pero fallará la lógica después
    // porque no encontrará el '0'. Para arreglar solo el error de compilación
    // esto es suficiente.

    // El resto del código original del test...
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

// 4. Definición de la clase Mock al final del archivo
// Implementa la interfaz del servicio pero no hace nada real
class MockConnectivityService implements ConnectivityService {
  @override
  Future<bool> checkConnectivity() async => true;

  @override
  void dispose() {}

  @override
  Future<void> init() async {}

  @override
  bool get isOnline => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();

  @override
  // TODO: implement onSyncComplete
  Stream<bool> get onSyncComplete => throw UnimplementedError();
}
