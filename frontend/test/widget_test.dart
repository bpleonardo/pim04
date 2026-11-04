import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/main.dart';

void main() {
  testWidgets('Tela de login é exibida', (tester) async {
    await tester.pumpWidget(const BarbeariaApp());
    expect(find.text('Entrar'), findsOneWidget);
  });
}
