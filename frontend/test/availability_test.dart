import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/features/availability/presentation/availability_screen.dart';

class AvailabilityApi extends BarbershopApi {
  final saving = Completer<void>();
  int writes = 0;
  @override
  Future<Map<String, dynamic>> myAvailability() async => {'dias': []};
  @override
  Future<void> saveAvailability(Map<String, dynamic> availability) async {
    writes++;
    await saving.future;
  }
}

void main() {
  testWidgets('Intervalo inválido permanece aberto com uma mensagem',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AvailabilityScreen(api: AvailabilityApi()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Domingo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar intervalo').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '08:00');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um fim posterior ao início'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '18:00');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('09:00–18:00'), findsWidgets);
  });

  testWidgets(
      'Salvar disponibilidade bloqueia alterações até concluir e libera após resposta',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = AvailabilityApi();
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AvailabilityScreen(api: api))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Domingo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar disponibilidade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar disponibilidade'));
    await tester.pump();
    expect(api.writes, 1);
    for (final button
        in tester.widgetList<TextButton>(find.byType(TextButton))) {
      expect(button.onPressed, isNull);
    }
    api.saving.complete();
    await tester.pumpAndSettle();
    expect(find.text('Disponibilidade salva.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
