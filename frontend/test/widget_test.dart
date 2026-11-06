import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/app/app.dart';

void main() {
  testWidgets('Tela de login é exibida', (tester) async {
    await tester.pumpWidget(const BarbershopApp());
    expect(find.text('Entrar'), findsOneWidget);
    final context = tester.element(find.text('Entrar'));
    expect(Navigator.of(context).canPop(), isFalse);
  });
}
